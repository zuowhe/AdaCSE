function key = get_dag_key(dag_matrix)
% GET_DAG_KEY 生成 DAG 矩阵的唯一字符串标识
%
% 输入:
%   dag_matrix: 节点连接矩阵 (N x N)
% 输出:
%   key: 唯一字符串 key，表示该 DAG 结构

[row, col] = find(dag_matrix == 1);
key = generate_unique_key([row, col]);
end

%-------------------------------------------------------------------------
% 嵌套函数：生成唯一字符串键
%-------------------------------------------------------------------------
function key = generate_unique_key(edges)
if isempty(edges)
    key = 'empty';
    return;
end
sorted_edges = sortrows(edges);
key_parts = cell(size(sorted_edges, 1), 1);
for i = 1:size(sorted_edges, 1)
    key_parts{i} = sprintf('%d_%d', sorted_edges(i,1), sorted_edges(i,2));
end
key = strjoin(key_parts, '_');
end