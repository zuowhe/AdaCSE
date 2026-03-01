%% 根据给定的数据集和贝叶斯网络结构，利用零阶条件独立性检验（0th-order CI tests）获取超结构（super-structure）。
function [ss] = Mutual_dependencies_He(data,bnet,tol)
% Get super-structure by applying 0th-order CI tests.
n = size(bnet.dag,1);   % #nodes
ss = xor(true(n),diag(true(1,n)));      % init super-structure
for i = 1:n-1
    for j = i+1:n
        ci = cond_indep_chisquare(i,j,[],data,'LRT',tol,bnet.node_sizes);
        if ci == 1
            ss(i,j) = false; ss(j,i) = false;   % remove edge
        end
    end
end
end