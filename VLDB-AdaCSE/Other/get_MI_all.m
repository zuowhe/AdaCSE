function [MI, norm_MI] = get_MI_all(data, node_sizes)
%% 计算互信息 Mutual Information（MI）
bns = size(node_sizes, 2);    % 节点数
m = size(data, 2);            % 训练集大小
MI = zeros(bns);              % 互信息矩阵初始化

% 计算MI
for n1 = 1:bns
    for n2 = n1+1 :bns        % n2 从 n1+1 开始，避免重复计算对称部分。
        cnt1 = zeros(1, node_sizes(n1));
        cnt2 = zeros(1, node_sizes(n2));
        cnt12 = zeros(node_sizes(n1), node_sizes(n2));
        for k = 1:m           % 统计n1和n2节点不同值出现的次数，以及两个节点不同联合状态的出现次数
            a = data(n1, k);
            b = data(n2, k);
            
            cnt1(a) = cnt1(a) + 1;
            cnt2(b) = cnt2(b) + 1;
            cnt12(a, b) = cnt12(a, b) + 1;
        end
        cnt1 = cnt1 / m;
        cnt2 = cnt2 / m;
        cnt12 = cnt12 / m;
        for i = 1:node_sizes(n1)
            for j = 1:node_sizes(n2)
                if cnt12(i,j) > 0
                    delta_MI = cnt12(i,j) * log2(cnt12(i,j) / (cnt1(i) * cnt2(j)) );   % 根据公式计算MI
                    MI(n1, n2) = MI(n1, n2) + delta_MI;
                    MI(n2, n1) = MI(n1, n2);    % 将下三角部分填充
                end
            end
        end
    end
end

%% 归一化互信息值
norm_MI = zeros(bns);              % 归一化的互信息矩阵初始化

% 获取全局最大MI值
max_MI = max(MI(:));  % 取整个MI矩阵的最大值

% 使用全局最大MI值进行归一化
for i = 1:bns
    for j = i:bns
        norm_MI(i,j) = MI(i,j) / max_MI;  % 用全局最大值进行归一化
        norm_MI(j,i) = norm_MI(i,j);      % 保证矩阵对称
    end
end

end
