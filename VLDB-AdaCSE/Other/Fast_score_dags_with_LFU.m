function [score, cache, node_scores] = Fast_score_dags_with_LFU(data, ns, dags, varargin)
% FAST_SCORE_DAGS_WITH_LFU Compute the BIC score of one or more DAGs using LFU cache and dynamic size.
%
% Inputs:
%   data:           n x N matrix, observed data (n variables, N samples)
%   ns:             1 x n vector, number of states per variable
%   dags:           1 x NG cell, each is a DAG adjacency matrix
%   varargin:       optional arguments including 'cache' and 'node_scores'
%
% Outputs:
%   score:          1 x NG vector, BIC scores for each DAG
%   cache:          struct with fields entry, score, freq, cache_size
%   node_scores:    1 x n cell, each cell contains parent-set-score records

    [n, ~] = size(data);
    NG = length(dags); % Population size
    score = zeros(1, NG);

    % 计算平均每个节点的父节点数
    total_parents = 0;
    for g = 1:NG
        for j = 1:n
            total_parents = total_parents + length(parents(dags{g}, j));
        end
    end
    avg_parents_per_node = total_parents / (n * NG);

    % 设置 cache 大小（动态）
    pop_size = NG;
    cache_size = calc_cache_size(pop_size, avg_parents_per_node);

    % 初始化或复用 cache
    if nargin < 4 || isempty(varargin) || ~isfield(varargin{1}, 'cache')
        cache = init_cache();
        cache.cache_size = cache_size;
    else
        cache = varargin{1}.cache;
        if ~isfield(cache, 'cache_size')
            cache.cache_size = cache_size;
        end
    end

    % 初始化 node_scores（每个节点一个列表）
    if nargin < 4 || isempty(varargin) || ~isfield(varargin{1}, 'node_scores')
        node_scores = cell(1, n);
        for j = 1:n
            node_scores{j} = struct('parents', {}, 'score', {});
        end
    else
        node_scores = varargin{1}.node_scores;
    end

    % Loop over all DAGs
    for g = 1:NG
        if isempty(dags{g})
            score(g) = -Inf;
            continue;
        end

        % Loop over all nodes
        for j = 1:n
            ps = parents(dags{g}, j);
            ps = sort(ps); % 标准化排序

            key = generate_key(j, ps); % 使用统一 key 表示法

            % Step 1: 查找缓存
            [found, scor] = cache_lookup(cache, key);
            if ~found
                % Step 2: 如果未命中，则计算并插入缓存
                scor = Fast_score_family2(j, ps, 'tabular', ns, 1:n, data, {});
                [cache, ~] = cache_insert_or_update(cache, key, scor);

                % Step 3: 更新 node_scores（可选优化）
                idx = find_parent_in_node_scores(node_scores{j}, ps);
                if idx == 0
                    node_scores{j}(end+1) = struct('parents', ps, 'score', scor);
                else
                    node_scores{j}(idx).score = scor;
                end
            else
                % 如果命中，也同步更新 node_scores 中的记录（如有）
                idx = find_parent_in_node_scores(node_scores{j}, ps);
                if idx ~= 0
                    node_scores{j}(idx).score = scor;
                end
            end

            % 累加得分
            score(g) = score(g) + scor;
        end
    end

end

% ---------------------- 辅助函数 ----------------------

% 动态 cache_size 函数
function cache_size = calc_cache_size(pop_size, avg_parents_per_node)
    scaling_factor = 3; % 可调参数
    cache_size = round(pop_size * avg_parents_per_node * scaling_factor);
end

% 初始化 LFU cache
function cache = init_cache()
    cache.key = {};
    cache.score = [];
    cache.freq = [];
    cache.cache_size = 0;
end

% 查询缓存是否存在 key
function [found, score] = cache_lookup(cache, key)
    found = false;
    score = 0;

    for i = 1:length(cache.key)
        if strcmp(cache.key{i}, key)
            found = true;
            score = cache.score(i);
            return;
        end
    end
end

% 插入或更新缓存（LFU 替换策略）
function [cache, replaced] = cache_insert_or_update(cache, key, new_score)
    replaced = false;

    % 先检查是否已存在该条目
    for i = 1:length(cache.key)
        if strcmp(cache.key{i}, key)
            cache.score(i) = new_score;
            cache.freq(i) = cache.freq(i) + 1;
            return;
        end
    end

    % 如果缓存未满，直接插入
    if length(cache.key) < cache.cache_size
        cache.key{end+1} = key;
        cache.score(end+1) = new_score;
        cache.freq(end+1) = 1;
    else
        % 否则使用 LFU 替换
        [~, idx] = min(cache.freq);
        cache.key{idx} = key;
        cache.score(idx) = new_score;
        cache.freq(idx) = 1;
        replaced = true;
    end
end

% 在 node_scores 中查找是否已有某 parent_set
function idx = find_parent_in_node_scores(node_cell, ps)
    idx = 0;
    ps = sort(ps);
    for i = 1:length(node_cell)
        if isequal(node_cell(i).parents, ps)
            idx = i;
            return;
        end
    end
end

% 生成唯一 key 字符串
function key = generate_key(j, ps)
    if isempty(ps)
        key = sprintf('j%d_ps[]', j);
    else
        key = sprintf('j%d_ps[%s]', j, num2str(sort(ps)'));
    end
end

% ---------------------- Fast_score_family 示例简化版 ----------------------
function score = Fast_score_family2(j, ps, node_type, ns, discrete, data, args)
    ccc = iscell(data);
    misv = -9999;
    if ccc
        data = bnt_to_mat(data, misv);
    end

    [n, ncases] = size(data);
    fam = [ps, j];
    dag = zeros(n);
    if ~isempty(ps)
        dag(sort(ps), j) = 1;
    end

    % Build BN structure
    bnet = mk_bnet(dag, ns, 'discrete', discrete);
    fname = sprintf('%s_CPD', node_type);
    if isempty(args)
        bnet.CPD{j} = feval(fname, bnet, j);
    else
        bnet.CPD{j} = feval(fname, bnet, j, args{:});
    end

    % Determine available cases
    if ccc
        [~, unavailable] = find(data(fam, :) == misv);
        available_case = setdiff(1:ncases, unavailable);
    else
        available_case = 1:ncases;
    end

    % Learn parameters and compute log probability
    bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
    logprob = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
    params = struct(bnet.CPD{j});  % Get parameter count

    % BIC score
    score = logprob - 0.5 * params.nparams * log(length(available_case));
end