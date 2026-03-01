function [g_best,g_best_score] = get_best(score,pop)
% Get elite individual from current generation population.
% 获取当前种群的最优个体及评分
j_star = find(score==max(score),1);
g_best_score = score(j_star);
g_best = pop{j_star};
end