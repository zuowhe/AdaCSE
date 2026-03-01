function [p,l_map_MI,l_cnt] = MYGA_initialization(ss,N,norm_MI)
% 根据 SS 随机初始化个体
% - outputs:
%   l_cnt:SS 中边的个数
%   l_map_MI:SS 个体中的边,按照相对MI进行排序

bns = size(ss,1);       % bnet size
p = cell(1,N);          % population
p(:) = {false(bns)};    % logic init
l_cnt = 0;              % 边的个数
l_map_MI = zeros(0,3);  % 初始化记录个体中的边

temp_a = rand(5*N,1);          % 取0-1内的正态分布，从5倍的里面挑合适的
temp_idx = find(temp_a>-0.5 & temp_a<0.5);
p_a = temp_a(temp_idx(1:N))+0.5;    % a*MMI 控制搜索空间


for j = 1 : bns-1
    for k = j+1 :bns
        if ss(j,k)
            % 统计 SS 中的边的个数及连接
            l_cnt = l_cnt + 1;
            l_map_MI(l_cnt,:) = [j,k,norm_MI(j,k)];
        end
    end
end
% 假设 MI 是一个 N x N 的矩阵，且只在上三角部分有有效数据
Nodenum = size(norm_MI, 1);

% 创建上三角掩码（不包含对角线）
upper_tri_mask = triu(true(Nodenum), 1);
upper_vals = norm_MI(upper_tri_mask);
% threshold = mean(upper_vals) + std(upper_vals);

% 参数设置
n_samples = N;           % 样本数量
target_median = mean(upper_vals);       % 想要的中位数
std_dev = std(upper_vals);            % 控制分布的宽度（标准差）

% 创建一个截断正态分布：均值 = target_median，标准差 = std_dev，区间 [0,1]
pd = makedist('Normal', 'mu', target_median, 'sigma', std_dev);
t_pd = truncate(pd, 0, 1);

% 从该分布中随机采样
samples = random(t_pd, n_samples, 1);

% % 按照第三列排序 l_map_MI. MI 大的在前面
% [~,index] = sort(l_map_MI(:,3),'descend');
% l_temp = l_map_MI;
% for l = 1:l_cnt
%     l_temp(l,:) = l_map_MI(index(l),:);
% end
% l_map_MI = l_temp;

for l = 1:l_cnt
    j = l_map_MI(l,1);  k = l_map_MI(l,2);  l_MI = l_map_MI(l,3);
    for i = 1:N
        if l_MI > samples(i)
%         if l_MI > rand
            switch(randi(2)) % randi(n) 生成一个在 1 到 n 之间的随机整数（包括 1 和 n）。
                case 1
                    p{i}(j,k) = true;  p{i}(k,j) = false;
                case 2
                    p{i}(j,k) = false;  p{i}(k,j) = true;
                otherwise
                    p{i}(j,k) = false;  p{i}(k,j) = false;
            end
        end
    end
end


end