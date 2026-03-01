function [score, cacheStruct, flag_cache] = he_score_dags_bic_with_lru(data, ns, dags, varargin)
% 输入参数
% data: 数据矩阵 (n_vars x n_samples)
% ns: 每个变量的取值数量（离散）
% dags: 当前种群中所有个体（DAG结构）
% varargin: 可选参数，目前仅支持 'cache' 参数传入缓存结构

% 初始化输出
flag_cache = 0;
score = -Inf; % 默认得分最小

% 获取数据维度
[n_vars, n_samples] = size(data);

% 初始化或读取缓存结构
if nargin < 4 || isempty(varargin) || ~isfield(varargin{2}, 'cache')
    % 如果没有传入缓存，则初始化缓存结构
    cacheStruct = struct('maxSize', 500, 'nodeCache', cell(1, n_vars), 'lruList', cell(1, n_vars));
    for i = 1:n_vars
        cacheStruct.nodeCache{i} = containers.Map();
        cacheStruct.lruList{i} = {};
    end
else
    cacheStruct = varargin{2}.cache;
end

% 遍历每个节点，计算局部BIC得分
for j = 1:n_vars
    ps = parents(dags, j); % 获取当前节点j的父节点集合
    parentKey = getParentKey(j, ps); % 将父节点转换为字符串key

    % 查找缓存
    if isKey(cacheStruct.nodeCache{j}, parentKey)
        localScore = cacheStruct.nodeCache{j}(parentKey);
        updateLRU(cacheStruct, j, parentKey); % 更新LRU顺序
        flag_cache = 1;
    else
        % 如果缓存未命中，计算BIC得分
        localScore = computeBIC(data, ns, j, ps);
        addOrUpdateCache(cacheStruct, j, parentKey, localKey, localScore); % 插入缓存
    end

    score = score + localScore;
end

end

function key = getParentKey(node, parentSet)
    if isempty(parentSet)
        key = sprintf('n%d_p[]', node);
    else
        sortedParents = sort(parentSet);
        key = sprintf('n%d_p%s', node, mat2str(sortedParents));
    end
end
function bic = computeBIC(data, ns, node, parentSet)
    n_vars = size(data, 1);
    n_samples = size(data, 2);

    % 节点取值数
    r_i = ns(node);
    
    % 父节点取值数乘积
    if ~isempty(parentSet)
        q_i = prod(ns(parentSet));
    else
        q_i = 1;
    end

    % 计算频数表
    counts = zeros(r_i, q_i);
    for s = 1:n_samples
        value_i = data(node, s);
        if isempty(parentSet)
            counts(value_i, 1) = counts(value_i, 1) + 1;
        else
            parentValues = data(parentSet, s)';
            idx = sub2ind(size(counts, 2), parentValues + 1); % 假设从0开始编码
            counts(value_i, idx) = counts(value_i, idx) + 1;
        end
    end

    % MLE估计下的对数似然
    logLikelihood = 0;
    total = sum(counts(:));
    for k = 1:size(counts, 2)
        N_ik = sum(counts(:, k));
        if N_ik > 0
            for m = 1:size(counts, 1)
                if counts(m, k) > 0
                    logLikelihood = logLikelihood + counts(m, k) * log(counts(m, k) / N_ik);
                end
            end
        end
    end

    % BIC评分公式
    penalty = 0.5 * log(n_samples) * r_i * q_i;
    bic = logLikelihood - penalty;
end
function addOrUpdateCache(cacheStruct, node, key, score)
    cache = cacheStruct.nodeCache{node};
    lruList = cacheStruct.lruList{node};

    if length(lruList) >= cacheStruct.maxSize
        % 移除最久未使用的项
        oldestKey = lruList{1};
        cacheStruct.nodeCache{node}.remove(oldestKey);
        lruList(1) = [];
    end

    % 添加新项
    cacheStruct.nodeCache{node}(key) = score;
    lruList{end+1} = key;

    % 更新缓存结构
    cacheStruct.lruList{node} = lruList;
end
function updateLRU(cacheStruct, node, key)
    lruList = cacheStruct.lruList{node};
    idx = find(strcmp(lruList, key), 1);
    if ~isempty(idx)
        % 将该项移到队列末尾
        lruList([idx:end]) = lruList([idx+1:end idx]);
        lruList(end) = key;
        cacheStruct.lruList{node} = lruList;
    end
end
