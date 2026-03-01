function [score, cache] = score_family_norecover(j, ps, node_type, ns, discrete, data, args, cache)
% SCORE_FAMILY_NORECOVER 计算节点 j 的 BIC 分数，安全获取 nparams

%% 默认参数处理
if nargin < 8 || isempty(cache)
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
end
if nargin < 7 || isempty(args)
    args = {};
end

%% 数据预处理
misv = -9999;
ccc = iscell(data);
if ccc
    data = bnt_to_mat(data, misv);
end

[n, ncases] = size(data);

%% 规范化 ps
ps = unique(ps);
ps = sort(ps);

%% 生成缓存键
if isempty(ps)
    key = sprintf('j_%d_ps_empty', j);
else
    ps_str_cell = arrayfun(@int2str, ps, 'UniformOutput', false);
    ps_str = strjoin(ps_str_cell, '_');
    key = sprintf('j_%d_ps_%s', j, ps_str);
end

%% 检查缓存
if isKey(cache, key)
    score = cache(key);
    return;
end

%% 构建局部 DAG
dag = zeros(n);
if ~isempty(ps)
    dag(ps, j) = 1;
end

%% 创建网络和 CPD
bnet = mk_bnet(dag, ns, 'discrete', discrete);
fname = sprintf('%s_CPD', node_type);
if isempty(args)
    bnet.CPD{j} = feval(fname, bnet, j);
else
    bnet.CPD{j} = feval(fname, bnet, j, args{:});
end

%% 提取有效样本
fam = [ps, j];
[~, available_case] = find(data(fam, :) == misv);
available_case = setdiff(1:ncases, available_case);

%% 计算评分
if isempty(available_case)
    score = -inf;
else
    try
        % 学习参数
        bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
        
        % 计算对数似然
        L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
        
        % ✅ 安全获取 nparams：直接访问，用 try-catch
        nparams = bnet.CPD{j}.nparams;  % 如果支持，直接获取
        
        Ndata = length(available_case);
        score = L - 0.5 * nparams * log(Ndata);
        
    catch ME
        error('score_family_norecover: Failed to compute score for node %d: %s', j, ME.message);
    end
end

%% 写入缓存
cache(key) = score;

end