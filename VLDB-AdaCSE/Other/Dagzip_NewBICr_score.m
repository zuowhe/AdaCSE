function [score, pop_history, score_history, repeated_count1, length_history, cache, flag_cache] = ...
         Dagzip_NewBICr_score(data, N2, ns, pop, pop_history, score_history, length_history, cache, flag_cache)
% 输入参数：
%   data: 数据矩阵 (n_vars x n_samples)
%   N2: 当前代种群数量
%   ns: 每个变量的状态数
%   pop: 当前代种群（DAGs 的 cell 数组）
%   pop_history: 历史个体缓存（key-value 形式）
%   score_history: 历史评分记录
%   length_history: 历史长度计数器
%   cache: 分层LRU缓存结构
%   flag_cache: 是否命中缓存标志
%
% 输出参数：
%   score: 当前代每个个体的BIC得分
%   pop_history: 更新后的个体缓存
%   score_history: 更新后的评分记录
%   repeated_count1: 当前代重复个体数量
%   length_history: 更新后的长度计数器
%   cache: 更新后的缓存结构
%   flag_cache: 是否命中缓存标志

repeated_count1 = 0;
% flag_cache = 0;

% 初始化当前代评分向量
score = zeros(1, N2);

% 如果历史种群为空或不是 containers.Map，则初始化
if isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

% 遍历当前代的每一个个体
for j = 1:N2
    % 获取当前 DAG
    dags = pop{j};
    
    % 提取边信息并生成唯一键值
    [row, col] = find(dags == 1);
    key = generate_unique_key([row, col]);

    % 检查是否在历史缓存中存在该结构
    if isKey(pop_history, key)
        % 命中缓存，直接获取评分
        score(j) = pop_history(key);
        repeated_count1 = repeated_count1 + 1;
    else
        % 未命中缓存，调用评分函数计算 BIC
        [individual_score, cache, hit] = Fast_score_dags_with_LFU3(data, ns, dags, 'cache', cache);
        score(j) = individual_score;

        % 将当前个体及其评分加入历史缓存
        pop_history(key) = individual_score;

        % 更新历史记录
        length_history = length_history + 1;
        score_history(length_history) = individual_score;

%         if hit
%             flag_cache = 1;  % 标记为命中缓存
%         end
    end
end

end
function key = generate_unique_key(edges)
% 辅助函数：根据 DAG 的边生成唯一字符串 key
% edges: 一个两列矩阵，表示边的起点和终点

if isempty(edges)
    key = 'empty';
    return;
end

% 按字典序排序边
sorted_edges = sortrows(edges);

% 转换为字符串形式的 key
key_str = '';
for i = 1:size(sorted_edges, 1)
    key_str = [key_str, sprintf('%d_%d_', sorted_edges(i, 1), sorted_edges(i, 2))];
end

% 去掉最后的下划线
if ~isempty(key_str)
    key_str(end) = [];
end

key = key_str;
end