function [score, cache, flag_cache] = he_score_dags_bic_with_lru_wrapper(data, ns, dags, varargin)
% 输入:
%   data: 数据矩阵 (n_vars x n_samples)
%   ns: 每个变量的状态数（离散）
%   dags: 当前DAG结构（个体）
%   varargin: 可选参数列表，目前支持 'cache' 参数传入缓存结构
%
% 输出:
%   score: DAG的BIC得分
%   cache: 更新后的缓存结构
%   flag_cache: 是否命中缓存（0=未命中，1=命中）

[n_vars, ~] = size(data);
flag_cache = 0;
score = 0;

% 默认缓存设置
if nargin < 4 || isempty(varargin) || ~isfield(varargin{2}, 'cache')
    % 初始化缓存结构（每个节点一个LRU缓存）
    cache = struct('maxSize', 500, 'nodeCache', cell(1, n_vars), 'lruList', cell(1, n_vars));
    for i = 1:n_vars
        cache.nodeCache{i} = containers.Map();
        cache.lruList{i} = {};
    end
else
    cache = varargin{2}.cache;
end

% 遍历每个节点，计算局部BIC得分
for j = 1:n_vars
    ps = parents(dags, j); % 获取当前节点j的父节点集合

    % 调用带缓存机制的BIC评分函数
    [scor, cache, hit] = he_score_family_bic_with_lru(j, ps, ns, data, cache);

    if hit
        flag_cache = 1;
    end
    score = score + scor;
end

end