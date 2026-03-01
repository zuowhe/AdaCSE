function [bic, cache, hit] = he_score_family_bic_with_lru(node, parentSet, ns, data, cache)
% 输入：
%   node: 当前节点编号
%   parentSet: 父节点集合（向量）
%   ns: 各变量状态数
%   data: 数据矩阵 (n_vars x n_samples)
%   cache: 缓存结构
%
% 输出：
%   bic: 局部BIC得分
%   cache: 更新后的缓存结构
%   hit: 是否命中缓存（0/1）

hit = 0;

% 生成唯一key
key = getParentKey(node, parentSet);

% 尝试从缓存中获取
if isKey(cache.nodeCache{node}, key)
    bic = cache.nodeCache{node}(key);
    updateLRU(cache, node, key);
    hit = 1;
    return;
end

% 如果缓存未命中，则计算BIC
bic = computeBIC(data, ns, node, parentSet);

% 插入缓存
addOrUpdateCache(cache, node, key, bic);

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
