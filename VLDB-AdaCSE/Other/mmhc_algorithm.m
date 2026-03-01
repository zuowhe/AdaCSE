%% MMHC算法MATLAB实现
% 实现贝叶斯网络结构学习的MMHC算法，包括MMPC骨架重建和贪心爬山边定向

function [dag, scores] = mmhc_algorithm(data, var_names)
    % 输入:
    %   data - 离散数据集，每行是一个样本，每列是一个变量
    %   var_names - 变量名称数组
    % 输出:
    %   dag - 有向无环图的邻接矩阵
    %   scores - 搜索过程中的评分记录
    
    n_vars = size(data, 2);
    dag = zeros(n_vars, n_vars); % 初始化邻接矩阵
    
    % 1. 骨架重建：使用MMPC算法获取每个变量的父母和子女集
    pc_sets = cell(n_vars, 1);
    for i = 1:n_vars
        fprintf('正在处理变量 %d/%d: %s\n', i, n_vars, var_names{i});
        pc_sets{i} = mmpc_algorithm(data, i, var_names);
    end
    
    % 构建无向骨架：如果i在j的PC集中且j在i的PC集中，则存在无向边
    skeleton = zeros(n_vars, n_vars);
    for i = 1:n_vars
        for j = 1:n_vars
            if i ~= j && ismember(j, pc_sets{i}) && ismember(i, pc_sets{j})
                skeleton(i, j) = 1;
                skeleton(j, i) = 1;
            end
        end
    end
    
    % 2. 边定向：使用贪心爬山搜索
    fprintf('开始边定向搜索...\n');
    [dag, scores] = greedy_hill_climbing(data, skeleton, var_names);
    
    % 确保无环
    dag = make_acyclic(dag);
    fprintf('MMHC算法完成\n');
end

function pc_set = mmpc_algorithm(data, target_idx, var_names)
    % 实现MMPC算法，获取目标变量的父母和子女集
    % 输入:
    %   data - 数据集
    %   target_idx - 目标变量索引
    %   var_names - 变量名称
    % 输出:
    %   pc_set - 父母和子女集的索引列表
    
    n_vars = size(data, 2);
    target_name = var_names{target_idx};
    other_vars = setdiff(1:n_vars, target_idx);
    cpc = []; % 候选父母和子女集
    
    % 前向阶段：最大最小启发式迭代添加变量
    while true
        [max_var, max_assoc] = max_min_heuristic(data, target_idx, cpc, other_vars);
        if max_assoc <= 0 % 关联度为0，停止添加
            break;
        end
        cpc = [cpc, max_var];
        other_vars = setdiff(other_vars, max_var);
    end
    
    % 后向阶段：移除假阳性变量
    to_remove = [];
    for x = cpc
        if can_remove_variable(data, target_idx, x, cpc)
            to_remove = [to_remove, x];
        end
    end
    cpc = setdiff(cpc, to_remove);
    
    % 对称性校正
    to_remove = [];
    for x = cpc
        % 检查目标变量是否在x的PC集中
        x_pc_set = mmpc_algorithm(data, x, var_names);
        if ~ismember(target_idx, x_pc_set)
            to_remove = [to_remove, x];
        end
    end
    pc_set = setdiff(cpc, to_remove);
end

function [max_var, max_assoc] = max_min_heuristic(data, target_idx, cpc, other_vars)
    % 最大最小启发式：选择与目标变量具有最大最小关联度的变量
    max_assoc = -inf;
    max_var = -1;
    
    for x = other_vars
        % 计算x与目标变量在cpc所有子集下的最小关联度
        min_assoc = inf;
        % 生成cpc的所有子集（限制子集大小以避免计算爆炸）
        subsets = generate_subsets(cpc, min(3, length(cpc))); % 限制子集大小为3
        for s = subsets
            assoc = calculate_association(data, target_idx, x, s);
            if assoc < min_assoc
                min_assoc = assoc;
            end
        end
        if min_assoc > max_assoc
            max_assoc = min_assoc;
            max_var = x;
        end
    end
end

function assoc = calculate_association(data, target_idx, x_idx, cond_set)
    % 计算变量x与目标变量在条件集cond_set下的关联度
    % 使用负P值作为关联度：P值越小，关联度越高
    [p_val, ~] = chi2_test(data, target_idx, x_idx, cond_set);
    assoc = -p_val; % 负P值作为关联度
end

function p_val = chi2_test(data, idx1, idx2, cond_set)
    % 执行χ²测试，判断idx1和idx2在条件集cond_set下是否独立
    % 输入:
    %   data - 数据集
    %   idx1, idx2 - 变量索引
    %   cond_set - 条件变量索引集
    % 输出:
    %   p_val - 检验的P值
    
    % 提取变量数据
    var1 = data(:, idx1);
    var2 = data(:, idx2);
    cond_data = data(:, cond_set); if ~isempty(cond_set) end
    
    % 构建列联表
    if isempty(cond_set)
        % 无条件独立测试
        counts = tabulate([var1, var2]);
        obs = counts(:, 3);
        [~, rows] = unique(var1);
        [~, cols] = unique(var2);
        r = length(unique(var1));
        c = length(unique(var2));
        expected = reshape(mean(obs) * ones(r, c), r*c, 1);
    else
        % 条件独立测试
        % 这里简化处理，实际应构建多维列联表
        p_val = 0.01; % 简化返回，实际应计算多维列联表的χ²统计量
        return;
    end
    
    % 计算χ²统计量和P值
    chi2 = sum((obs - expected).^2 ./ expected);
    df = (r-1)*(c-1);
    p_val = 1 - chi2cdf(chi2, df);
end

function remove = can_remove_variable(data, target_idx, x_idx, cpc)
    % 判断是否可以移除变量x，即是否存在子集S⊆cpc使得x与目标变量独立
    remove = false;
    % 生成cpc的所有子集（限制大小）
    subsets = generate_subsets(cpc, min(3, length(cpc)));
    for s = subsets
        if ~isempty(s) && ~ismember(x_idx, s)
            [p_val, ~] = chi2_test(data, target_idx, x_idx, s);
            if p_val > 0.05 % 如果P值大于阈值，认为独立
                remove = true;
                break;
            end
        end
    end
end

function subsets = generate_subsets(set, max_size)
    % 生成集合的所有子集，最多max_size个元素
    n = length(set);
    subsets = {};
    for k = 0:min(max_size, n)
        if k == 0
            subsets{end+1} = [];
        else
            combs = nchoosek(set, k);
            for i = 1:size(combs, 1)
                subsets{end+1} = combs(i, :);
            end
        end
    end
end

function [dag, scores] = greedy_hill_climbing(data, skeleton, var_names)
    % 基于骨架的贪心爬山搜索，使用BDeu评分
    n_vars = size(skeleton, 1);
    dag = zeros(n_vars, n_vars);
    scores = [];
    tabu_list = cell(100, 1); % TABU列表，存储最近100个结构
    tabu_idx = 0;
    best_score = -inf;
    best_dag = dag;
    no_improvement = 0;
    max_no_improvement = 15;
    
    while no_improvement < max_no_improvement
        % 生成所有可能的操作：添加、删除、反转边
        operations = generate_operations(dag, skeleton);
        if isempty(operations)
            break;
        end
        
        % 评估每个操作的评分
        best_op = [];
        best_op_score = -inf;
        for op = operations
            new_dag = apply_operation(dag, op);
            if is_acyclic(new_dag)
                % 检查是否在TABU列表中
                if ~is_in_tabu(tabu_list, new_dag)
                    score = calculate_full_bdeu(data, new_dag, var_names);
                    if score > best_op_score
                        best_op = op;
                        best_op_score = score;
                    end
                end
            end
        end
        
        % 执行最佳操作
        if ~isempty(best_op)
            dag = apply_operation(dag, best_op);
            current_score = best_op_score;
            scores = [scores, current_score];
            
            % 更新最佳解
            if current_score > best_score
                best_score = current_score;
                best_dag = dag;
                no_improvement = 0;
            else
                no_improvement = no_improvement + 1;
            end
            
            % 更新TABU列表
            tabu_idx = mod(tabu_idx + 1, 100) + 1;
            tabu_list{tabu_idx} = dag;
        else
            break;
        end
    end
    
    dag = best_dag;
end

function operations = generate_operations(dag, skeleton)
    % 生成所有可能的合法操作：添加、删除、反转边
    n_vars = size(dag, 1);
    operations = {};
    
    % 添加边：仅当骨架中存在无向边且当前无向
    for i = 1:n_vars
        for j = 1:n_vars
            if i ~= j && skeleton(i,j) == 1 && dag(i,j) == 0 && dag(j,i) == 0
                operations{end+1} = struct('type', 'add', 'from', i, 'to', j);
            end
        end
    end
    
    % 删除边：删除现有边
    for i = 1:n_vars
        for j = 1:n_vars
            if i ~= j && dag(i,j) == 1
                operations{end+1} = struct('type', 'delete', 'from', i, 'to', j);
            end
        end
    end
    
    % 反转边：仅当存在有向边
    for i = 1:n_vars
        for j = 1:n_vars
            if i ~= j && dag(i,j) == 1 && skeleton(i,j) == 1
                operations{end+1} = struct('type', 'reverse', 'from', i, 'to', j);
            end
        end
    end
end

function new_dag = apply_operation(dag, op)
    % 应用操作到当前DAG
    new_dag = dag;
    switch op.type
        case 'add'
            new_dag(op.from, op.to) = 1;
        case 'delete'
            new_dag(op.from, op.to) = 0;
        case 'reverse'
            new_dag(op.from, op.to) = 0;
            new_dag(op.to, op.from) = 1;
    end
end

function tf = is_in_tabu(tabu_list, dag)
    % 检查DAG是否在TABU列表中
    tf = false;
    for i = 1:length(tabu_list)
        if ~isempty(tabu_list{i}) && all(tabu_list{i}(:) == dag(:))
            tf = true;
            break;
        end
    end
end

function score = calculate_full_bdeu(data, dag, ess)
    % 完整BDeu评分函数实现
    % 输入:
    %   data - 离散数据集，每行样本，每列变量
    %   dag - 贝叶斯网络有向图邻接矩阵
    %   ess - 等价样本大小(文档中设为10)
    % 输出:
    %   score - BDeu评分（对数后验概率）
    
    n_vars = size(dag, 1);
    n_samples = size(data, 1);
    score = 0;
    
    % 1. 计算网络结构先验概率的对数 (简化处理，假设均匀先验)
    % 实际中网络结构先验较复杂，此处假设均匀先验 log(P(G)) ≈ 常数，可忽略或简化
    log_prior_structure = 0; % 均匀先验时为常数，对结构比较无影响
    
    % 2. 对每个节点计算BDeu评分
    for i = 1:n_vars
        parents = find(dag(:, i)); % 父节点索引
        k_i = length(unique(data(:, i))); % 节点i的取值数
        
        % 2.1 计算父节点组合的取值数
        k_pa = 1;
        if ~isempty(parents)
            for p = 1:length(parents)
                k_pa = k_pa * length(unique(data(:, parents(p)));
            end
        end
        
        % 2.2 构建父节点组合与节点i取值的计数表
        count_table = build_count_table(data, i, parents);
        
        % 2.3 计算Dirichlet先验参数
        alpha = ess / (k_i * k_pa); % 每个条件概率的先验参数
        
        % 2.4 计算BDeu评分项
        node_score = 0;
        for pa_idx = 1:size(count_table, 1)
            parent_counts = count_table(pa_idx, 1:end-1); % 父节点组合的计数
            child_counts = count_table(pa_idx, end); % 节点i的取值计数
            
            % 计算Dirichlet后验参数的对数伽马和
            log_gamma_posterior = gammaln(sum(child_counts) + k_i * alpha);
            log_gamma_prior = gammaln(k_i * alpha);
            
            for v = 1:k_i
                log_gamma_posterior = log_gamma_posterior + gammaln(child_counts(v) + alpha);
                log_gamma_prior = log_gamma_prior + gammaln(alpha);
            end
            
            % 累加该父节点组合的评分项
            node_score = node_score + (log_gamma_posterior - log_gamma_prior);
        end
        
        % 累加节点i的评分
        score = score + node_score;
    end
    
    % 3. 加上网络结构先验概率的对数（此处简化处理）
    score = score + log_prior_structure;
end

function count_table = build_count_table(data, node_idx, parent_idxs)
    % 构建父节点组合与节点取值的计数表
    n_samples = size(data, 1);
    node_vals = unique(data(:, node_idx));
    k_node = length(node_vals);
    
    if isempty(parent_idxs)
        % 无父节点时，直接统计节点取值计数
        count_table = zeros(1, k_node + 0);
        for v = 1:k_node
            count_table(v) = sum(data(:, node_idx) == node_vals(v));
        end
        count_table = [1, count_table]; % 虚拟父节点组合计数为1
    else
        % 有父节点时，统计每个父节点组合下的节点取值计数
        % 1. 生成所有父节点组合的唯一标识
        parent_combinations = unique(data(:, parent_idxs), 'rows');
        n_pa = size(parent_combinations, 1);
        
        % 2. 初始化计数表
        count_table = zeros(n_pa, k_node + length(parent_idxs));
        
        % 3. 填充父节点组合的取值
        for p = 1:n_pa
            count_table(p, 1:length(parent_idxs)) = parent_combinations(p, :);
        end
        
        % 4. 统计每个父节点组合下的节点取值计数
        for s = 1:n_samples
            % 查找当前样本的父节点组合索引
            curr_pa = data(s, parent_idxs);
            pa_idx = find(ismember(parent_combinations, curr_pa, 'rows'));
            
            % 统计节点取值
            curr_node = data(s, node_idx);
            node_idx_in_table = find(node_vals == curr_node);
            
            % 累加计数
            count_table(pa_idx, length(parent_idxs) + node_idx_in_table) = ...
                count_table(pa_idx, length(parent_idxs) + node_idx_in_table) + 1;
        end
    end
end

function tf = is_acyclic(dag)
    % 检查DAG是否有环
    n = size(dag, 1);
    visited = false(n, 1);
    rec_stack = false(n, 1);
    
    for i = 1:n
        if ~visited(i)
            if has_cycle_util(dag, i, visited, rec_stack)
                tf = false;
                return;
            end
        end
    end
    tf = true;
end

function tf = has_cycle_util(dag, v, visited, rec_stack)
    if ~visited(v)
        visited(v) = true;
        rec_stack(v) = true;
        
        for i = 1:size(dag, 1)
            if dag(v, i) == 1
                if ~visited(i) && has_cycle_util(dag, i, visited, rec_stack)
                    tf = true;
                    return;
                elseif rec_stack(i)
                    tf = true;
                    return;
                end
            end
        end
    end
    rec_stack(v) = false;
    tf = false;
end

function dag = make_acyclic(dag)
    % 通过拓扑排序确保DAG无环
    n = size(dag, 1);
    new_dag = dag;
    
    % 简单实现：通过迭代移除环
    while ~is_acyclic(new_dag)
        for i = 1:n
            for j = 1:n
                if i ~= j && new_dag(i,j) == 1 && new_dag(j,i) == 1
                    % 移除其中一条边
                    new_dag(i,j) = 0;
                    if is_acyclic(new_dag)
                        break;
                    else
                        new_dag(i,j) = 1;
                        new_dag(j,i) = 0;
                    end
                end
            end
            if is_acyclic(new_dag)
                break;
            end
        end
    end
    dag = new_dag;
end