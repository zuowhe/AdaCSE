function [score, cache, hit] = Fast_score_dags_with_LFU2(data, ns, dag, varargin)
% FAST_SCORE_DAGS_WITH_LFU (Modified for single DAG input)
% 支持输入单个 DAG，并返回该 DAG 的 BIC 评分、更新后的缓存和是否命中标志。

    % 初始化输出
    score = 0;
    hit = false;

    % 获取节点数量
    n = size(data, 1);

    % 检查输入 DAG 是否为空
    if isempty(dag)
        score = -Inf;
        return;
    end

    % 初始化或复用缓存
    if nargin < 4 || isempty(varargin) || ~isfield(varargin{1}, 'cache')
        cache = init_cache();
        cache.cache_size = calc_cache_size(1, 1); % 默认缓存大小
    else
        cache = varargin{1}.cache;
    end

    % 如果提供了 node_scores，则复用；否则初始化
    if nargin >= 4 && isfield(varargin{1}, 'node_scores')
        node_scores = varargin{1}.node_scores;
    else
        node_scores = cell(1, n);
        for j = 1:n
            node_scores{j} = struct('parents', {}, 'score', {});
        end
    end

    % 主体评分过程
    for j = 1:n
        ps = parents(dag, j);
        ps = sort(ps); % 标准化父集表示

        key = generate_key(j, ps); % 生成唯一 key

        % 查找缓存
        [found, scor] = cache_lookup(cache, key);
        if ~found
            % 未命中，计算评分并插入缓存
            scor = Fast_score_family2(j, ps, 'tabular', ns, 1:n, data, {});
            [cache, ~] = cache_insert_or_update(cache, key, scor);

            % 更新 node_scores
            idx = find_parent_in_node_scores(node_scores{j}, ps);
            if idx == 0
                node_scores{j}(end+1) = struct('parents', ps, 'score', scor);
            else
                node_scores{j}(idx).score = scor;
            end
        else
            hit = true; % 命中缓存
        end

        % 累加评分
        score = score + scor;
    end

end


%% 本地子函数 Local Helper Functions %%

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

% 示例 Fast_score_family2（简化版）
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