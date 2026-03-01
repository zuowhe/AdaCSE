function [pop2,score2,norm_score2] = tournament_selection_limit(N,N2,pop,score,norm_score,t,tour_limit)
% Halve population size by retaining fitter individuals with an higher likelihood.
% 通过保留较高的适应性个体将人口规模减半
% t 锦标赛规模 (t选1)
% tour_limit 相同个体出现的最多次数

i = 0;
pop2 = cell(1,N2);                  % 保留的个体
score2 = -Inf * ones(1,N2);         % 保留的个体的评分
norm_score2 = -Inf * ones(1,N2);    % 保留的个体的归一化评分

while i < N
    index = ceil(rand(1,t) * N2);      % 随机选择锦标赛个体
    scores = score(index);
    best_index = index(find(scores == max(scores)));
    best_p = best_index(1);         % 胜者编号
    
    % 寻找相同个体数
    same_p = 0;
    for j = 1 : i
        if pop2{j} == pop{best_p}
            same_p = same_p + 1;
        end
        % 根据相同个体数 same_p判断是否保留
        if same_p > tour_limit
            continue;   % 抛弃
        end
    end
    % 根据相同个体数 same_p判断是否保留
    if same_p > tour_limit
        continue;   % 抛弃
    else
        % 保留
        i = i+1;
        pop2{i} = pop{best_p};          % 胜者个体
        score2(i) = score(best_p);      % 胜者评分
        norm_score2(i) = norm_score(best_p);
    end
end

end