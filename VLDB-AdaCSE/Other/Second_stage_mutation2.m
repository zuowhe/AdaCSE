function [p] = Second_stage_mutation2(l_map, p, all_repeats)
    nrep = length(all_repeats);          % 要变异的个体数量
    npos = size(l_map, 1);               % 可变异的位置总数
    num_to_mutate = nrep;

    % 步骤1: 确定要进行变异的位置对 (j,k) 和 (k,j)
    if num_to_mutate <= npos
        % 情况1: 个体数 <= 位置数 → 随机选择 num_to_mutate 个不同位置
        selected_pos_idx = randperm(npos, num_to_mutate);
    else
        % 情况2: 个体数 > 位置数
        % 先让所有位置都参与一次变异
        selected_pos_idx = 1:npos;
        % 剩下的个体数
        remaining = num_to_mutate - npos;
        % 额外随机选择 'remaining' 个位置（允许重复）
        extra_pos_idx = randi(npos, [1, remaining]);
        % 合并：所有位置 + 额外随机位置
        selected_pos_idx = [selected_pos_idx, extra_pos_idx];
    end

    % 步骤2: 将 selected_pos_idx 与 all_repeats 对应起来
    % 我们打乱个体顺序，然后逐个分配给 selected_pos_idx 指定的位置
    shuffled_repeats = all_repeats(randperm(nrep)); % 打乱个体顺序，避免偏置

    % 步骤3: 遍历每一个要变异的“任务”（个体i 在位置 L 上变异）
    for idx = 1:num_to_mutate
        i = shuffled_repeats(idx);        % 当前要变异的个体
        L = selected_pos_idx(idx);        % 当前要变异的位置索引
        j = l_map(L, 1);
        k = l_map(L, 2);
        prob = l_map(L, 3);               % 该位置的变异参数（阈值）

        % 获取当前等位基因状态
        l_val = get_allele(p{i}(j,k), p{i}(k,j));

        % 执行变异（与原逻辑一致）
        if rand < (1/l_map(size(l_map,1),1)) % 使用原 m = 1/l_cnt 作为变异触发概率
            switch l_val
                case 1
                    if rand > 0.5
                        p{i}(j,k) = false; p{i}(k,j) = true;
                    else
                        p{i}(j,k) = true; p{i}(k,j) = false;
                    end
                case 2
                    if prob > rand
                        p{i}(j,k) = true; p{i}(k,j) = false;
                    else
                        p{i}(j,k) = false; p{i}(k,j) = false;
                    end
                case 3
                    if prob > rand
                        p{i}(j,k) = false; p{i}(k,j) = true;
                    else
                        p{i}(j,k) = false; p{i}(k,j) = false;
                    end
            end
        end
    end
end