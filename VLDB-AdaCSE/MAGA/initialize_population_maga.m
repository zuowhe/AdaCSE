function pop = initialize_population_maga(SuperStructure,N_total, BN_NodesNum, edge_prob)
% INITIALIZE_POPULATION_MAGA - 根据论文描述为MAGA生成初始种群
%
%   pop = initialize_population_maga(N_total, BN_NodesNum, edge_prob)
%
%   根据二项式图生成算法创建初始解。
%   - N_total: 智能体总数 (L_size * L_size)
%   - BN_NodesNum: 贝叶斯网络中的节点数
%   - edge_prob: 任意一条边存在的概率 (例如 0.1)

    pop = cell(1, N_total);
    num_vars = BN_NodesNum * BN_NodesNum;

    for i = 1:N_total
        % 1. 创建一个随机邻接矩阵
        adj_matrix = zeros(BN_NodesNum, BN_NodesNum);
        for row = 1:BN_NodesNum
            for col = 1:BN_NodesNum
              if SuperStructure(row,col) ==1



                    if row ~= col % 排除自环
                        if rand < 0.1
                            adj_matrix(row, col) = 1;
                        end
                    end
    
              end
            
            end
        end
        
        % 2. 将邻接矩阵“扁平化”为二进制向量
        %    使用 reshape(M', 1, []) 来按行展开，确保与后续操作一致
        pop{i} = reshape(adj_matrix', 1, num_vars);
    end
end