function [l_map_MI] = AdaptiveCI_other(n,p_value,alpha)
    
    ss = xor(true(n), diag(true(1, n)));      % init super-structure 
    l_map_MI = zeros(0,2);  % 初始化记录个体中的边
    l_cnt = 0;              % 边的个数%     
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
                l_cnt = l_cnt + 1;
                l_map_MI(l_cnt,:) = [j,k];
            end
        end
    end
end