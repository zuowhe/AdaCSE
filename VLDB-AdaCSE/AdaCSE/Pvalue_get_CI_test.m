function [p_value] = Pvalue_get_CI_test(data, bnet, tol)
    % Get super-structure by applying 0th-order CI tests.
    n = size(bnet.dag, 1);   % #nodes
    ss = xor(true(n), diag(true(1, n)));      % init super-structure   
    
    p_value = double(ss);
    for i = 1:n-1
        for j = i+1:n
            [~, ~, alpha2] = Pvalue_cond_indep(i, j, [], data, 'LRT', tol, bnet.node_sizes);
            p_value(i, j) = alpha2;  p_value(j, i) = alpha2;
        end
    end
    
end
