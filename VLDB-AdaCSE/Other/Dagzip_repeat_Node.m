function [score, pop_history, score_history, number_edges, repeated_count1, length_history, flag_cache, cache, total_onec_overwrite, repeated_indices] = ...
    Dagzip_repeat_Node(data, N2, ns, pop, pop_history, score_history, number_edges, length_history, scoring_fn, flag_cache, cache, max_cache_size)
% DAGZIP_REPEAT_NODE
%   计算种群中每个个体的评分，使用历史缓存避免重复计算。
%   同时记录重复个体在当前种群中的索引位置。
%
% 输入：
%   data: 数据矩阵
%   N2: 种群规模
%   ns: 节点状态数
%   pop: 当前种群（cell array of DAGs）
%   pop_history: containers.Map，记录已计算过的 DAG 及其评分
%   score_history: 历史评分记录
%   number_edges: 历史边数记录
%   length_history: 历史记录长度
%   scoring_fn: 评分函数（如 'bic'）
%   flag_cache: 内存预分配标志
%   cache: 评分缓存（按节点父集缓存）
%   max_cache_size: 最大缓存条目数
%
% 输出：
%   score: 当前种群评分向量
%   pop_history: 更新后的种群历史
%   score_history: 更新后的评分历史
%   number_edges: 更新后的边数历史
%   repeated_count1: 本次重复个体数量
%   length_history: 更新后历史长度
%   flag_cache: 缓存是否溢出
%   cache: 更新后的缓存
%   total_onec_overwrite: 本次缓存覆盖次数
%   repeated_indices: 本次重复个体在 pop 中的索引（1-based）

score = zeros(1, N2);
repeated_count1 = 0;
total_onec_overwrite = 0;
repeated_indices = [];  % 存储重复个体索引

% 初始化历史结构体（若为空）
if isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

for j = 1:N2
    current_matrix = pop{j};
    [row, col] = find(current_matrix == 1);
    key = generate_unique_key([row, col]);

    if isKey(pop_history, key)
        % 命中缓存：直接赋分
        score(j) = pop_history(key);
        repeated_count1 = repeated_count1 + 1;
        repeated_indices = [repeated_indices, j];  % ✅ 记录索引
    else
        % 未命中：计算评分
        dags = {current_matrix};
        [individual_score, cache, overwrite_count] = score_dags_NewRecover(...
            data, ns, dags, ...
            'scoring_fn', scoring_fn, ...
            'cache', cache, ...
            'max_cache_size', max_cache_size);

        score(j) = individual_score(1);
        total_onec_overwrite = total_onec_overwrite + overwrite_count;

        % 更新历史
        pop_history(key) = score(j);
        length_history = length_history + 1;
        number_edges(length_history) = length(row);
        score_history(length_history) = score(j);
    end
end

end


%-------------------------------------------------------------------------
% 子函数：生成唯一字符串键
%-------------------------------------------------------------------------
function key = generate_unique_key(edges)
% 将边列表排序后编码为字符串键
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