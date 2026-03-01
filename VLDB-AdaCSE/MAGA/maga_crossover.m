function [best_child,best_score, cache] = maga_crossover(parent1, parent2, data, ns, scoring_fn, cache, max_cache_size,BN_NodesNum)

    % 1. 初始化
    len = numel(parent1);
    child1 = zeros(1, len);
    child2 = zeros(1, len);

    % 2. 遍历所有基因位，生成两个子代
    for i = 1:len
        if parent1(i) == parent2(i)
            % --- 保留共识 ---
            % 如果两个父代基因相同，子代直接继承
            child1(i) = parent1(i);
            child2(i) = parent1(i);
        else
            % --- 随机探索分歧 ---
            % 如果基因不同，每个子代独立地随机选择一个父代的基因
            % 这是对 "the donator parent is randomly chosen" 的忠实实现
            
            % 为 child1 随机选择
            if rand < 0.5
                child1(i) = parent1(i);
            else
                child1(i) = parent2(i);
            end

            % 为 child2 独立地随机选择
            if rand < 0.5
                child2(i) = parent1(i);
            else
                child2(i) = parent2(i);
            end
        end
    end

    % 3. 对生成的两个子代进行评分
    %    注意：这里必须传入和传出 cache，因为评分会更新缓存
  repaired_children = cell(1, 2);
    repaired_children{1} = repair_operator_dfs(child1, BN_NodesNum);


    repaired_children{2} = repair_operator_dfs(child2, BN_NodesNum);
    
    % --- 对修复后的、保证无环的子代进行评分 ---
    [scores, updated_cache, ~] = MAGA_score_dags_recover(data, ns, repaired_children, ...
        'scoring_fn', scoring_fn, 'cache', cache, 'max_cache_size', max_cache_size);
%     [scores,updated_cache] = score_dags(data,ns,repaired_children,'scoring_fn',scoring_fn,'cache',cache);
    
    % 将主函数中的 cache 更新为评分后返回的 cache
    cache = updated_cache;

    % 4. 选择并返回更优的子代
    if scores(1) > scores(2)
        best_child = repaired_children{1};
        best_score = scores(1); 
    else
        best_child = repaired_children{2};
        best_score = scores(2); 
    end
end