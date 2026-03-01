function [pop,score] = HC_mutation(pop,score,N)
% 爬山法算子，20220116针对小dataset的死循环进行了修复
% 比较现有个体中仅差一个边的个体，选最优进行替换
dist_matrix = zeros(N,N)-1;
% 计算每两个图之间的距离矩阵 dist_matrix
for i = 1:N
    for j = i+1:N
        dist = cal_dist(pop{i},pop{j});
        dist_matrix(i,j) = dist;
        dist_matrix(j,i) = dist;
    end
end

unique_matrix_num = get_diff_matrix(pop,N);
if unique_matrix_num > 10
    pop_cpy = pop;
    for i = 1:N
        L_better_index = find(dist_matrix(i,:) < 2);
        L_better_score = score(L_better_index);
        if rand<0.5 && max(L_better_score)>score(i)
            L_better_top_index = find(L_better_score==max(L_better_score));
            L_better_top_1 = L_better_index(L_better_top_index(1));
        else
            L_better_top_1 = i;
        end
        pop{i} = pop_cpy{L_better_top_1};
        score(i) = score(L_better_top_1);
    %     norm_score(i) = norm_score(L_better_top_1);
    end
end
end


function [dist] = cal_dist(p1,p2)
% 计算两个dag之间的距离
n = size(p1,1);
xor_g = xor(p1,p2);     % p1,p1中不同的边的个数
dist = sum(sum(xor_g));
for i = 1:n
    for j = i+1:n
        % p1与p2恰好指向相反
        if xor_g(i,j) == 1 && xor_g(j,i) == 1
            dist = dist-1;
        end
    end
end
end

function [diffGraphNum] = get_diff_matrix(p,N)
matrix_list = cell(1,N);
diffGraphNum = 1;
base_matrix = p{1};
matrix_list{1} = base_matrix;
for i=2:N
    for j=1:diffGraphNum
        graph_dist = dist_between_graphs(p{i},matrix_list{j});
        if graph_dist~=0
            diffGraphNum = diffGraphNum + 1;
            matrix_list{diffGraphNum} = p{i};
            break;
        end
    end
end
end


function [dist] = dist_between_graphs(graph1,graph2)
node_num = size(graph1,1);
xor_g = xor(graph1,graph2);
dist = sum(sum(xor_g));
for i=1:node_num
    for j=i+1:node_num
        if xor_g(i,j) == 1 && xor_g(j,i)==1
            dist = dist - 1;
        end
    end
end
end
