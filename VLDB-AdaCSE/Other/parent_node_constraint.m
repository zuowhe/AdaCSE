function pop = parent_node_constraint(pop, MI_matrix, max_parents, current_iter, total_iter)
% 父节点约束操作符：结合随机删除和MI指导删除，控制每个节点的父节点数量。
%
% 输入参数：
%   pop: 种群，是一个cell数组，每个元素是一个邻接矩阵（N x N）
%   MI_matrix: 互信息矩阵（N x N），MI(i,j) 表示变量i和j之间的互信息
%   max_parents: 每个节点的最大父节点数限制
%   current_iter: 当前迭代次数
%   total_iter: 总迭代次数
%
% 输出：
%   pop: 经过父节点约束操作后的新种群

    nPop = length(pop);  % 获取种群个体数量
    sigma = current_iter / total_iter;  % 计算选择率sigma

    for i = 1:nPop
        individual = pop{i};  % 获取当前个体（邻接矩阵）
        nNodes = size(individual, 1);  % 获取节点数量

        for j = 1:nNodes
            % 找出当前节点j的所有父节点（即列中值为1的行索引）
            parents = find(individual(:, j) == 1);
            num_parents = length(parents);  % 当前父节点数量

            % 如果父节点数量超过最大限制，则进行边删除
            while num_parents > max_parents
                rand4 = rand();  % 生成一个0~1之间的随机数

                if rand4 > sigma
                    % 随机删除一条边
                    idx_to_remove = parents(randi(num_parents));  % 随机选择一个父节点
                else
                    % MI指导删除：移除MI值最低的边
                    mi_values = MI_matrix(j, parents);  % 获取当前父节点对应的MI值
                    [~, min_idx] = min(mi_values);  % 找到最小MI值的位置
                    idx_to_remove = parents(min_idx);  % 对应的父节点索引
                end

                % 删除选中的边（将对应位置设置为0）
                individual(idx_to_remove, j) = 0;
                parents = setdiff(parents, idx_to_remove);  % 更新父节点列表
                num_parents = num_parents - 1;  % 更新父节点数量
            end
        end

        pop{i} = individual;  % 将处理后的个体重新存入种群
    end
end