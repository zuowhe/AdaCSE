% ********** 关键修改：随机父集交叉（融入SSIM）**********
function [offspring] = MIGA_crossover_RPSX(N, parents, g_best)
% 功能：对每个节点随机选择父代的父集构建子代，利用SSIM调整选择权重
% 参数：parents为父代种群，g_best为当前最优个体
bns = size(parents{1},1);
offspring = cell(1, 2*N);  % 子代种群（规模翻倍）

for i = 1:N
    % 选择两个父代
    p1 = parents{i};
    p2 = parents{i+N};  % 假设parents前N和后N为配对父代
    
    % 计算两父代的SSIM
    ssim_p = dag_ssim(p1, p2);
    
    % 生成两个子代
    for c = 1:2
        child = false(bns);  % 子代DAG初始化
        
        for node = 1:bns
            % 父代1的父集
            p1_parents = find(p1(:, node));
            % 父代2的父集
            p2_parents = find(p2(:, node));
            
            % 根据SSIM调整选择概率：SSIM越高，越均衡选择两父代；否则偏向优质父集
            if ssim_p > 0.7  % 高相似度：均衡选择
                prob_p1 = 0.5;
            else  % 低相似度：偏向与最优个体更相似的父代
                ssim1 = dag_ssim(p1, g_best);
                ssim2 = dag_ssim(p2, g_best);
                prob_p1 = ssim1 / (ssim1 + ssim2 + 1e-4);  % 归一化概率
            end
            
            % 随机选择父集来源
            if rand < prob_p1
                % 从父代1选择部分父集（随机比例）
                select_ratio = 0.3 + 0.7*rand;  % 30%-100%的父集保留
                selected = randsample(length(p1_parents), round(select_ratio*length(p1_parents)));
                child(p1_parents(selected), node) = true;
            else
                % 从父代2选择部分父集
                select_ratio = 0.3 + 0.7*rand;
                selected = randsample(length(p2_parents), round(select_ratio*length(p2_parents)));
                child(p2_parents(selected), node) = true;
            end
        end
        
        offspring{i + (c-1)*N} = child;
    end
end
end