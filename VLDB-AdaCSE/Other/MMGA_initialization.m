function [p,l_map_MI,l_cnt] = MMGA_initialization(ss,N,norm_MI)
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

for l = 1:l_cnt
    j = l_map_MI(l,1);  k = l_map_MI(l,2);  l_MI = l_map_MI(l,3);
    for i = 1:N
        if l_MI > p_a(i)
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