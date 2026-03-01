function [repeat_indices, all_repeats] = Find_repeated_arrays(pop)
    N = length(pop);  % 获取pop中的元素数量
    repeat_indices = {};  % 初始化用于存储重复项及其索引
    all_repeats = [];  % 初始化用于存储所有除首个外的重复索引
    
    % 遍历每个元素
    for j = 1:N
        if isnan(pop{j})  % 如果当前元素已经是处理过的重复项，则跳过
            continue;
        end
        
        % 查找与pop{j}相同的数组的索引
        same_indices = j;  % 初始化为j，因为至少包含它自己
        for k = j+1:N
            if isequal(pop{j}, pop{k})
                same_indices = [same_indices, k];  % 添加k到相同数组的索引列表
                pop{k} = NaN;  % 标记为已处理以避免重复计数
            end
        end
        
        % 如果有重复（即除了自身外还有其他索引），则保存
        if length(same_indices) > 1
            repeat_indices{end+1} = same_indices;  % 保存重复组
            all_repeats = [all_repeats, same_indices(2:end)];  % 将除首个外的所有重复索引添加到all_repeats
        end
    end
end