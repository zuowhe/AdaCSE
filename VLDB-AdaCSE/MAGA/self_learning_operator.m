function [best_agent_from_sl, best_score_from_sl, cache] = self_learning_operator(S_best, sL_size, sGen, sPm, sPr, Pc, ...
                                                              data, ns, scoring_fn, cache, max_cache_size, ...
                                                               MP, BN_NodesNum)
%SELF_LEARNING_OPERATOR Implements the local search refinement from the MAGA paper (Algorithm 2).
%
%   [best_agent_from_sl, cache] = self_learning_operator(S_best, ...)
%
%   This function performs a short, intensive local search around the best
%   solution of the current generation ('S_best'). It runs a "mini-MAGA"
%   on a small grid initialized with variants of S_best.

    sN_total = sL_size * sL_size;

    % 1. --- 初始化小种群 (创建“精锐小分队”) ---
    s_pop = cell(1, sN_total);
    s_pop{1} = S_best;

    for i = 2:sN_total
        s_pop{i} = maga_mutation(S_best, BN_NodesNum);
    end

    %s_pop = MIGA_del_loop_MI(s_pop, MI, MP);
    for i = 1:numel(s_pop)
        s_pop{i} = repair_operator_dfs(s_pop{i}, BN_NodesNum);
    end

    % 对初始小种群进行评分 (修复了续行符后的参数缺失问题)
    [s_score, cache, ~] = MAGA_score_dags_recover(data, ns, s_pop, ...
        'scoring_fn', scoring_fn, 'cache', cache, 'max_cache_size', max_cache_size);
%     [s_score, cache,] = score_dags(data,ns, s_pop,'scoring_fn',scoring_fn,'cache',cache);
    % 2. --- 运行 sGen 代的“迷你MAGA” ---
    for g = 1:sGen
        
        % a. --- 迷你交叉 ---
        s_pop_after_crossover = s_pop;
        for k = 1:sN_total
            if rand < Pc
                s_neighbor_indices = get_neighbor_indices(k, sL_size);
                s_neighbor_scores = s_score(s_neighbor_indices);
                [~, best_local_idx] = max(s_neighbor_scores);
                best_neighbor_idx = s_neighbor_indices(best_local_idx);

                [child,best_score, cache] = maga_crossover(s_pop{k}, s_pop{best_neighbor_idx}, ...
                                                data, ns, scoring_fn, cache, max_cache_size,BN_NodesNum);
                s_score(k) = best_score;
                s_pop_after_crossover{k} = child;
            end
        end
        s_pop = s_pop_after_crossover;
        

        % b. --- 迷你变异 (带接受准则) ---
        for k = 1:sN_total
            if rand < sPm
                original_s_agent = s_pop{k};
                original_s_score = s_score(k);
                
                mutated_s_agent = maga_mutation(original_s_agent, BN_NodesNum);
                repaired_s_agent_cell = repair_operator_dfs(mutated_s_agent, BN_NodesNum);

                repaired_s_agent = repaired_s_agent_cell;

                [new_s_scores, updated_cache, ~] = MAGA_score_dags_recover(data, ns, {repaired_s_agent}, ...
                    'scoring_fn', scoring_fn, 'cache', cache, 'max_cache_size', max_cache_size);
%                 [new_s_scores, updated_cache] = score_dags(data,ns,{repaired_s_agent},'scoring_fn',scoring_fn,'cache',cache);
                cache = updated_cache;
                new_s_score = new_s_scores(1);

                if new_s_score > original_s_score
                    s_pop{k} = repaired_s_agent;
                    s_score(k) = new_s_score;
                elseif rand <= sPr
                    s_pop{k} = repaired_s_agent;
                    s_score(k) = new_s_score;
                end
            end
        end
    end

    % 3. --- 返回小种群中的最终最优解及其分数 ---
    [best_score_from_sl, best_idx] = max(s_score); 
    best_agent_from_sl = s_pop{best_idx};
end