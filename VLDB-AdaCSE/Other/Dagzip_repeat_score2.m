function [score, pop_history, score_history, number_edges, repeated_count1, length_history,flag_cache,cache] = ...
    Dagzip_repeat_score2(data, N2, ns, pop, pop_history, score_history, number_edges, length_history, scoring_fn,flag_cache,cache)
%     global cache
    % 检查当前代的个体是否已经计算过评分，避免重复计算
    score = zeros(1, N2);  % 初始化当前代的评分
    repeated_count1 = 0;
    
    % 使用散列表存储历史种群
    if isempty(pop_history) || ~isa(pop_history, 'containers.Map')
        pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');  % 初始化散列表
    end
    
    % 压缩pop中每个个体
    for j = 1:N2
        % 获取当前个体矩阵
        current_matrix = pop{j};
        
        % 压缩：存储1的位置和1的个数
        [row, col] = find(current_matrix == 1);  % 找到1的位置
        num_ones = numel(row);  % 1的个数
        
        % 将压缩后的个体转换为唯一键值
        key = generate_unique_key([row, col]);
        
        % 检查散列表中是否已存在该键
        if isKey(pop_history, key)
            % 如果存在，则直接获取评分
            score(j) = pop_history(key);
            repeated_count1 = repeated_count1 + 1;
        else
            % 如果不存在，则计算评分并保存到散列表中
            [individual_score, cache, flag_cache] = he_score_dags3(data, ns, pop{j}, 'scoring_fn', scoring_fn, 'cache', cache);
            score(j) = individual_score;
            
            % 保存当前个体和其评分到散列表
            pop_history(key) = individual_score;
            
            % 更新其他历史记录
            length_history = length_history + 1;
            number_edges(length_history) = num_ones;
            score_history(length_history) = individual_score;
        end
    end
    
%    if flag_cache
%         fprintf('预分配的内存不足~');
%     end
end

% 辅助函数：生成唯一键值
function key = generate_unique_key(edges)
    % 将边的位置按字典序排序
    sorted_edges = sortrows(edges);
    
    % 将边位置转换为字符串形式的键值
    key_str = '';
    for i = 1:size(sorted_edges, 1)
        key_str = [key_str, sprintf('%d_%d_', sorted_edges(i, 1), sorted_edges(i, 2))];
    end
    
    % 去掉最后多余的下划线
    if ~isempty(key_str)
        key_str(end) = [];
    end
    
    key = key_str;
end