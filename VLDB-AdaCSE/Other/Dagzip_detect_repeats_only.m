function [repeated_indices, repeated_scores] = Dagzip_detect_repeats_only(pop, pop_history)
% DAGZIP_DETECT_REPEATS_ONLY
%   检测当前种群中与历史个体重复的索引和评分（仅读模式）
%
% 输入：
%   pop: 当前种群，cell array of DAG 矩阵
%   pop_history: containers.Map，键为 DAG 唯一标识，值为评分
%
% 输出：
%   repeated_indices: 重复个体在 pop 中的索引（1-based）
%   repeated_scores: 对应的历史评分

repeated_indices = [];
repeated_scores = [];

% 如果历史为空或不是 Map，直接返回空
if isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    return;
end

N2 = length(pop);
for j = 1:N2
    current_matrix = pop{j};
    [row, col] = find(current_matrix == 1);
    key = generate_unique_key([row, col]);
    
    if isKey(pop_history, key)
        repeated_indices(end + 1) = j;
        repeated_scores(end + 1) = pop_history(key);
    end
end

end


%-------------------------------------------------------------------------
% 子函数：生成唯一字符串键
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