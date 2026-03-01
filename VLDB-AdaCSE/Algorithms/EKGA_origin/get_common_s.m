function [common_struct] = get_common_s(pop,l_map)
% 找出所给种群的共同结构，用以在后面的突变中进行保留
% 对于个体中与common_s不同的边，进行变异
Ne = size(pop,2);     % 精英集大小
l_cnt = size(l_map,1);
common_struct = zeros(0,2);     % 共同结构
common_lcnt = 0;
for l = 1:l_cnt
    % 边(j,k)或(k,j): j-k
    j = l_map(l,1);
    k = l_map(l,2);
    for i = 1:Ne
        if pop{i}(j,k)~=pop{1}(j,k) || pop{i}(k,j)~=pop{1}(k,j)
            break;      % 若个体i中不存在这个边 j-k，则该边不会出现在共同结构中
        end
        if i==Ne
            % 所有个体中都存在边 j-k，则将这条边加入共同结构中
            if pop{1}(j,k)==1 || pop{1}(k,j)==1
                common_lcnt = common_lcnt +1;
                common_struct(common_lcnt,:) = [j k];
            end
        end
    end     
    % 关于边 j-k 遍历完成
end

end