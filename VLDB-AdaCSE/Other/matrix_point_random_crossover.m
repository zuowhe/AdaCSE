function [pop] = matrix_point_random_crossover(N, pop)
% 矩阵点随机交叉：对邻接矩阵的每个元素（点）独立随机选择父代取值，处理双向边冲突
% 输入：
%   N - 种群规模
%   pop - 种群（单元格数组，每个元素为n×n邻接矩阵，n为节点数）
% 输出：
%   pop - 扩展后的种群（新增N个后代个体）

    n = size(pop{1}, 1);  % 获取节点数（邻接矩阵维度）

    for p1 = 1:N
        % 随机选择另一个父代p2（确保p1≠p2）
        p2 = p1;
        while p1 == p2
            p2 = randi(N);
        end

        % 初始化后代为父代p1的副本，后续逐点交叉
        pop{N + p1} = pop{p1};

        % 遍历邻接矩阵的每个点（i≠j，跳过对角线）
        for i = 1:n
            for j = 1:n
                if i == j
                    continue;  % 对角线元素为0（自环不允许）
                end

                % 随机选择：以50%概率取p1的(i,j)值，50%概率取p2的(i,j)值
                if rand < 0.5
                    pop{N + p1}(i, j) = pop{p1}(i, j);
                else
                    pop{N + p1}(i, j) = pop{p2}(i, j);
                end
            end
        end

        % 处理双向边冲突（若i→j和j→i同时存在，随机保留一条）
        for i = 1:n
            for j = i+1:n  % 仅检查上三角，避免重复处理
                if pop{N + p1}(i, j) == 1 && pop{N + p1}(j, i) == 1
                    % 随机保留一条边，删除另一条
                    if rand < 0.5
                        pop{N + p1}(i, j) = 0;
                    else
                        pop{N + p1}(j, i) = 0;
                    end
                end
            end
        end
    end
end