function [best_agent_from_sl, best_score_from_sl, cache] = self_learning_operator_cached(S_best, sL_size, sGen, sPm, sPr, Pc, ...
                                                              data, ns, scoring_fn, cache, max_cache_size, ...
                                                               MP, BN_NodesNum)
% 自我学习算子（带缓存评分）

sN_total = sL_size * sL_size;
s_pop = cell(1, sN_total);
s_pop{1} = S_best;

% 初始化子种群
for i = 2:sN_total
    s_pop{i} = maga_mutation(S_best, BN_NodesNum);
    s_pop{i} = repair_operator_dfs(s_pop{i}, BN_NodesNum);
end

% 初始评分
[s_score, cache] = score_dags(data, ns, s_pop, ...
    'scoring_fn', scoring_fn, ...
    'discrete', 1:BN_NodesNum, ...
    'cache', cache);

% 进化循环
for sg = 1:sGen
    for k = 1:sN_total
        % 锦标赛选择邻居
        idxs = randperm(sN_total, min(3, sN_total));
        [~, best_neighbor] = max(s_score(idxs));
        best_neighbor_idx = idxs(best_neighbor);

        % 变异
        if rand < sPm
            original_score = s_score(k);
            mutated = maga_mutation(s_pop{k}, BN_NodesNum);
            repaired = repair_operator_dfs(mutated, BN_NodesNum);
            [new_score, cache] = score_dags(data, ns, {repaired}, ...
                'scoring_fn', scoring_fn, ...
                'discrete', 1:BN_NodesNum, ...
                'cache', cache);
            new_score = new_score(1);

            if new_score > original_score
                s_pop{k} = repaired;
                s_score(k) = new_score;
            elseif rand <= sPr
                s_pop{k} = repaired;
                s_score(k) = new_score;
            end
        end

        % 交叉
        if rand < Pc
            [child, child_score, cache] = maga_crossover_cached(s_pop{k}, s_pop{best_neighbor_idx}, ...
                data, ns, scoring_fn, cache, BN_NodesNum);
            if child_score > s_score(k)
                s_pop{k} = child;
                s_score(k) = child_score;
            end
        end
    end
end

% 重新评分确保一致性
[s_score, cache] = score_dags(data, ns, s_pop, ...
    'scoring_fn', scoring_fn, ...
    'discrete', 1:BN_NodesNum, ...
    'cache', cache);

[best_score_from_sl, best_idx] = max(s_score);
best_agent_from_sl = s_pop{best_idx};