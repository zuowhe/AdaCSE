function [score,pop_history, score_history,number_edges,repeated_count1,length_history, flag_cache] = Dagzip_repeat_score(data, N2, ns, pop, pop_history, score_history, number_edges,length_history,scoring_fn)
    global cache
    % 检查当前代的个体是否已经计算过评分，避免重复计算
    score = zeros(1, N2);  % 初始化当前代的评分
    repeated_count1 = 0;
%     flag_cache = 0;
    % 新增：用于存储压缩后的pop
%     compressed_pop = cell(1, N2);
    
    % 压缩pop中每个个体
    for j = 1:N2
        % 获取当前个体矩阵
%         current_matrix = pop{j};
        
        % 压缩：存储1的位置和1的个数
        [row, col] = find(pop{j} == 1);  % 找到1的位置
        num_ones = numel(row);  % 1的个数     

        repeated = false;
        % 对每个个体检查是否已经计算过评分
        for k = 1:length_history
            if number_edges(k) == num_ones && isequal([row, col], pop_history{k})
                score(j) = score_history(k);  % 使用已保存的评分
                repeated = true;
                repeated_count1 = repeated_count1 + 1;
                break;
            end
        end
        
        if ~repeated
            % 计算该个体的评分并保存
%             [individual_score, cache] = score_dags(data, ns, pop(j), 'scoring_fn', scoring_fn, 'cache', cache);
            [individual_score, cache, flag_cache] = he_score_dags(data,ns,pop(j),'scoring_fn',scoring_fn,'cache',cache);
            score(j) = individual_score;
            
            % 保存当前个体和其评分
            length_history = length_history + 1;
            number_edges(length_history) = num_ones;
            pop_history{length_history} = [row, col];  % 保存压缩后的个体
            score_history(length_history) = individual_score;
        end
    end
%     if flag_cache 
%         fprintf('预分配的内存不足~');
%     end
end
