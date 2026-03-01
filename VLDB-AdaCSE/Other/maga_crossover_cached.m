function [best_child, best_score, cache] = maga_crossover_cached(parent1, parent2, data, ns, scoring_fn, cache, BN_NodesNum)
% 带缓存评分的交叉操作

len = length(parent1);
child1 = zeros(1,len); 
child2 = zeros(1,len);

for i = 1:len
    if parent1(i) == parent2(i)
        child1(i) = parent1(i);
        child2(i) = parent1(i);
    else
        child1(i) = randsample([parent1(i), parent2(i)], 1);
        child2(i) = randsample([parent1(i), parent2(i)], 1);
    end
end

% 修复两个子代
repaired_children = {
    repair_operator_dfs(double(child1), BN_NodesNum);
    repair_operator_dfs(double(child2), BN_NodesNum)
};

% 批量评分
[scores, cache] = score_dags(data, ns, repaired_children, ...
    'scoring_fn', scoring_fn, ...
    'discrete', 1:BN_NodesNum, ...
    'cache', cache);

% 选择最优
[best_score, idx] = max(scores);
best_child = repaired_children{idx};