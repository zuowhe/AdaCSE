function [p,l_map,l_cnt] = init_pop_ss(ss,N)
% 根据 SS 随机初始化个体
% - outputs:
%   l_cnt:SS 中边的个数
%   l_map:SS 个体中的边

bns = size(ss,1);       % bnet size
p = cell(1,N);          % population
p(:) = {false(bns)};    % logic init
l_cnt = 0;              % 边的个数
l_map = zeros(0,2);     % 初始化记录个体中的边

for j = 1 : bns-1
    for k = j+1 :bns
        if ss(j,k)
            % 统计 SS 中的边的个数及连接
            l_cnt = l_cnt + 1;
            l_map(l_cnt,:) = [j,k];
            for i = 1:N
                % 随机产生边的概率 1/2 ，若产生的边过多则改为 bns
                switch(randi(4))
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


end