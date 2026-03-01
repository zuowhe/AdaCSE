function [l_map_MI] = AdaptiveCI(n,p_value,norm_MI,alpha)
    
    ss = xor(true(n), diag(true(1, n)));      % init super-structure 
    l_map_MI = zeros(0,3);  % 初始化记录个体中的边
    l_cnt = 0;              % 边的个数
%     fprintf('CI的初始阈值: %9.5f\n', alpha);
    for i = 1:n-1
        for j = i+1:n
            if p_value(i, j) > alpha
                ss(i, j) = false; ss(j, i) = false;   % remove edge
            end
        end
    end

    for j = 1 : n-1
        for k = j+1 :n
            if ss(j,k)
                % 统计 SS 中的边的个数及连接
                l_cnt = l_cnt + 1;
                l_map_MI(l_cnt,:) = [j,k,norm_MI(j,k)];
            end
        end
    end
end