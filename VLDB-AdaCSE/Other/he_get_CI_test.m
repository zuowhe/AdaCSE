function [p_value] = he_get_CI_test(data, bnet, tol)
    % Get super-structure by applying 0th-order CI tests.
    n = size(bnet.dag, 1);   % #nodes
    ss = xor(true(n), diag(true(1, n)));      % init super-structure   
    
%% 自己的版本
    p_value = double(ss);
    for i = 1:n-1
        for j = i+1:n
%             [ci, ~, alpha2] = cond_indep_chisquare(i, j, [], data, 'LRT', tol, bnet.node_sizes);
            [~, ~, alpha2] = he_cond_indep(i, j, [], data, 'pearson', tol, bnet.node_sizes);
            p_value(i, j) = alpha2;  p_value(j, i) = alpha2;
        end
    end
    
end
