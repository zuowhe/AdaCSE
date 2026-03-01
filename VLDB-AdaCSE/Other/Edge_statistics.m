function Edge_statistics(DsS,Bnets,trial)

for j = 1:size(DsS,2)
    BN_Name = DsS{j}{1,1};         % 获取BN名称
    Ds_set = DsS{j}{1,2};          % 获取该BN生成训练集的不同规模
    bnet = Bnets{j}{1,2};          % 获取当前BN的全部信息
    ns = bnet.node_sizes;           % node sizes
    BN_NodesNum = size(bnet.dag,1);         % #网络规模，即网络节点的数量
    fprintf('%s节点数量为: %d\n   ',BN_Name,BN_NodesNum);
    for i = 1:size(Ds_set,2)
            Ds = Ds_set(i);       % DS为当前训练集的大小
            NetSizeStr = sprintf('%s%s',BN_Name,num2str(Ds));     % 将网络名和数据规模整合成一个字符串
            % ====== 读取本地mat数据集文件
            data = load(NetSizeStr);
            TrainData = data.(NetSizeStr);
            for T = 1:1
                fprintf('训练集为: %s  ', NetSizeStr);
                % CB phase: CI test 生成 Super-structure 超结构 
                p_value = he_get_CI_test(TrainData{T},bnet,0);
                p_avg = mean(p_value(:));  % 所有p_value的平均值
                fprintf('p-value的均值为: %2.3f   ', p_avg);
                [alpha_candidate,~] = updateCI(p_avg, 100, 200, BN_NodesNum, 0, 0, 0);

                % 设置最小阈值为 0.001
                CI_init = 0.1;
                % CI_init = 0.01;
                fprintf('CI的初始阈值:%9.8f    ', CI_init);
                % 构造超结构，然后初始化种群
                SuperStructure = xor(true(BN_NodesNum), diag(true(1, BN_NodesNum))); 
                for i1 = 1:BN_NodesNum-1
                    for j1 = i1+1:BN_NodesNum
                        if p_value(i1, j1) > CI_init
                            SuperStructure(i1, j1) = false; SuperStructure(j1, i1) = false;   % remove edge
                        end
                    end
                end
                
%                 SuperStructure = get_CI_test(TrainData{T},bnet,tol);
                
                [n, m] = size(SuperStructure);
                % 上三角部分（不包括对角线）的索引
                upper_triangle_idx = triu(true(n, m), 1); 

                % 统计矩阵 SS 上三角部分中 1 的个数
                SS_upper_ones = sum(SuperStructure(upper_triangle_idx) == 1);

                % 统计矩阵 DGA 上三角部分中 1 的个数
                DAG_upper_ones = sum(bnet.dag(upper_triangle_idx) == 1);            
                
                [MI,norm_MI] = get_MI_all(TrainData{T},ns);
%                 [~,norm_MI] = get_MI(TrainData{T},ns);
                % 计算整个矩阵的平均值
                mean_value = mean(norm_MI(:));

                % 将矩阵转换为 01 矩阵
                [N, ~] = size(norm_MI);
                upper_tri_mask = triu(true(N), 1);  % 上三角（不含对角线）

%                 % 初始化 binary_matrix
%                 binary_matrix = false(N);
% 
%                 % 遍历每一行
%                 for row = 1:N
%                     % 提取当前行且属于上三角区域的元素
%                     upper_vals = norm_MI(row, :) .* upper_tri_mask(row, :);
% 
%                     % 找出当前行上三角中的最大值及其位置
%                     [maxVal, maxIdx] = max(upper_vals);
% 
%                     % 如果最大值对应的位置值为 0，说明该行上三角全是 0 或 NaN
%                     if ~isempty(maxIdx) && maxVal ~= 0
%                         % 只保留该行最大值的第一个位置为 1
%                         binary_matrix(row, maxIdx) = true;
%                     end
%                 end
%                 binary_matrix = norm_MI > mean_value*n*0.1;
%                 binary_matrix = norm_MI ==1;
                % 提取上三角区域的有效值
                upper_vals = norm_MI(upper_tri_mask);

                % 设置阈值（示例：平均值 + 标准差）
%                 threshold = mean(upper_vals) + std(upper_vals);  % 你可以替换为你自己的阈值策略
                threshold = median(upper_vals) + mad(upper_vals);
                fprintf('MI阈值为: %1.9f;   \n', threshold);
                binary_matrix = norm_MI > threshold;
%                 binary_matrix = norm_MI > 0.5;
                 % 统计矩阵 MI 上三角部分中 1 的个数
                MI_matrix_one = sum(binary_matrix(upper_triangle_idx) == 1);
                
                % 初始化计数器
                count1 = 0;
                count2 = 0;
                count3 = 0;
                count4 = 0;
                for i1 = 1:n
                    for j2 = i1+1:m  % 从 i+1 开始，确保是上三角部分
                        if upper_triangle_idx(i1, j2) && SuperStructure(i1, j2) == 1 && bnet.dag(i1, j2) == 1
                            count1 = count1 + 1;
                        end
                        if upper_triangle_idx(i1, j2) && binary_matrix(i1, j2) == 1 && bnet.dag(i1, j2) == 1
                            count2 = count2 + 1;
                        end
                        if upper_triangle_idx(i1, j2) && SuperStructure(i1, j2) == 1 && binary_matrix(i1, j2) == 1
                            count3 = count3 + 1;
                        end
                        if upper_triangle_idx(i1, j2) && SuperStructure(i1, j2) == 1 && bnet.dag(i1, j2) == 1 && binary_matrix(i1, j2) == 1
                            count4 = count4 + 1;
                        end
                    end
                end
                % 输出结果
                fprintf('矩阵SS: %d;  ', SS_upper_ones);
                fprintf('标准DAG: %d;  ', DAG_upper_ones);
                fprintf('SS和DAG相同位置的个数: %d\n', count1);
                
                fprintf('矩阵MI: %d;  ', MI_matrix_one);
                fprintf('标准DAG: %d;  ', DAG_upper_ones);
                fprintf('矩阵MI和DAG相同的个数: %d\n', count2);
                
                fprintf('矩阵MI和SS相同的个数: %d     ', count3);
                fprintf('三者相同的个数: %d\n', count4);
                
                
                
            end
    end
end


end

