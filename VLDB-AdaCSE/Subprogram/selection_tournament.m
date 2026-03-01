function [pop1,score1] = selection_tournament(N,N2,pop,score,tour)
% 选择算子：锦标赛选择 tournament selection（ N1 减少到 N ）
% tour： 锦标赛规模，随机选择tour个个体，选top1
% N2：   种群数量                     N：保留的个体数量
% pop：  种群          选择        pop1：保留的种群
% score：种群得分                score1：保留的种群得分

i = 0;
% 初始化选择之后的种群
% 数量为选择之后的 N0
% 原因：后面进行的交叉操作会生成新的个体，这里仅做初始化
pop1 = cell(1,N2);                  % 保留的个体
score1 = -Inf * ones(1,N2);         % 保留的个体的评分

% 选择 N0 个个体
while i < N
    index = ceil(rand(1,tour) *N2);                         % 在 N 个个体中随机选择 tour 个，编号在 index 中
    score_list = score(index);                              % 他们的评分
    best_list = index(find(score_list == max(score_list))); % 取top1，可能会有重复
    best_pop = best_list(1);                                % 防止重复
    i = i+1;                                                % 保留的个体+1
    pop1{i} = pop{best_pop};
    score1(i) = score(best_pop);
end
end