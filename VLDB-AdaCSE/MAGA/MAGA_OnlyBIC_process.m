function [dag, g_best_score, conv, iterations] = MAGA_OnlyBIC_process(SuperStructure, data, N, M, MP, scoring_fn, bnet, tour,saved_filename)
% MAGA主函数
% 输入参数变化: 
% N (原种群大小) -> L_size (网格边长)

%=========================== MAGA 参数设置 ===========================
Pc = 0.95; % 交叉概率
Pm = 0.01; % 变异概率
Pr = 0.01;
Init_Edge_Prob = 0.1; % 初始化的边概率


% 自我学习算子参数
sL_size = 3;      % 小网格边长
sGen = 5;         % 小网格迭代次数
sPm = 0.01;       % 小网格变异概率
sPr = 0.05;       % 小网格劣解替换概率

N_total = 10 * 10; % 智能体总数
BN_NodesNum = size(bnet.dag, 1);
ns = bnet.node_sizes;
iterations = 0;
conv = struct('f1', zeros(1,M), 'se', zeros(1,M), 'sp', zeros(1,M), 'sc', zeros(1,M));


max_realtime = get_max_realtime(BN_NodesNum);
inStart = tic;

% 初始化 cache
max_cache_size = 10000;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end

% fprintf('Initializing population using Binomial Graph Generation (p=%.2f)...\n', Init_Edge_Prob);
% 1. 使用论文方法生成初始种群 (随机图)
pop = initialize_population_maga(SuperStructure,N_total, BN_NodesNum, Init_Edge_Prob);             %生成初始种群 (随机图)
%pop = initialize_population_efficient(N_total, BN_NodesNum, Init_Edge_Prob);


% 初始去环
for i = 1:numel(pop)
    pop{i} = repair_operator_dfs(pop{i}, BN_NodesNum);
end


% 初始评分
[score, cache, once_cache_hits] = MAGA_score_dags_recover(data, ns, pop, ...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);

[g_best, g_best_score] = get_best(score, pop);

%=========================== 文件操作 (保持不变) ===========================
[path_str, ~, ~] = fileparts(saved_filename);
if ~isempty(path_str) && ~isfolder(path_str)
    mkdir(path_str);
end
saved_file = fopen(saved_filename, 'w');
if saved_file == -1, error('无法打开文件：%s', saved_filename); end
%==========================================================================

%% MAGA Main Loop
for i = 1:M
    if toc(inStart) > max_realtime
        iterations = i;
        [g_best_score, conv] = finalize_output(g_best, data, bnet, scoring_fn, M, conv, iterations);
        break;
    end
    
    % ------------------- 1. 交叉 (与最佳邻居) -------------------
    new_pop_after_crossover = pop;
    for k = 1:N_total
        if rand < Pc
            neighbor_indices = get_neighbor_indices(k, 10);
            neighbor_scores = score(neighbor_indices);
            [~, best_local_idx] = max(neighbor_scores);
            best_neighbor_idx = neighbor_indices(best_local_idx);
            
            % 调用交叉函数，并接收返回的 updated_cache
            [child, jiao_best_score,cache] = maga_crossover(pop{k}, pop{best_neighbor_idx}, ...
                                            data, ns, scoring_fn, cache, max_cache_size,BN_NodesNum);
            score(k) =   jiao_best_score;                        
            new_pop_after_crossover{k} = child;
        end
    end
    pop = new_pop_after_crossover;

    % ------------------- 2. 变异 ------------------
    for k = 1:N_total
        % 对每个智能体，以概率 Pm 触发变异过程
        if rand < Pm
            original_agent = pop{k};
            original_score = score(k);
    
            mutated_agent = maga_mutation(original_agent, BN_NodesNum);
    
            repaired_mutated_agent_cell = repair_operator_dfs(mutated_agent, BN_NodesNum);


            repaired_mutated_agent = repaired_mutated_agent_cell;
    
            %    这是一个单次调用，会更新缓存
            [new_scores, updated_cache, ~] = MAGA_score_dags_recover(data, ns, {repaired_mutated_agent}, ...
                'scoring_fn', scoring_fn, 'cache', cache, 'max_cache_size', max_cache_size);
            
            % e. 更新主缓存并获取新分数
            cache = updated_cache;
            new_score = new_scores(1);
    
            % f. 应用论文中的接受准则
            if new_score > original_score
                % --- 如果变异解更优，总是接受 ---
                pop{k} = repaired_mutated_agent;
                score(k) = new_score; % 直接更新种群和分数数组
                
            elseif rand <= Pr
                % --- 如果变异解更差，以概率 Pr 仍然接受 ---
                pop{k} = repaired_mutated_agent;
                score(k) = new_score; 
            end
            
        end
    end

    % ------------------- 3. 修复 (去环) -------------------
    for ii = 1:numel(pop)
        pop{ii} = repair_operator_dfs(pop{ii}, BN_NodesNum);
    end
    
    % ------------------- 4. 重新评分 (对整个种群) -------------------
    [score, cache, once_cache_hits] = MAGA_score_dags_recover(data, ns, pop, ...
        'scoring_fn', scoring_fn, ...
        'cache', cache, ...
        'max_cache_size', max_cache_size);
        
    % ------------------- 5. 自我学习算子 -------------------
    % a. 找到当前代的最佳智能体
    [c_best_score, c_best_idx] = max(score);
    current_best_agent = pop{c_best_idx};
    
    % b. 应用自我学习算子 
    [improved_agent, improved_score, cache] = self_learning_operator(current_best_agent, ...
    sL_size, sGen, sPm, sPr, Pc, ...
    data, ns, scoring_fn, cache, max_cache_size, ...
    MP, BN_NodesNum);
    
    for ii = 1:numel(pop)
        pop{ii} = repair_operator_dfs(pop{ii}, BN_NodesNum);
    end


    % c. 更新种群和分数 
    pop{c_best_idx} = improved_agent;
    score(c_best_idx) = improved_score;
    
    % ------------------- 6. 更新全局最优解 -------------------
    [current_g_best, current_g_best_score] = get_best(score, pop);
    if current_g_best_score > g_best_score
        g_best = current_g_best;
        g_best_score = current_g_best_score;
    end
    
    % ------------------- 7. 记录与输出 -------------------
    %conv = update_conv(conv, g_best, g_best_score, bnet.dag, i);
    fprintf(saved_file, '%f\n', g_best_score); % 建议保存为浮点数
    %fprintf('Generation %d, Best Score: %f\n', i, g_best_score);
    iterations = i;
end

dag = {g_best};
fclose(saved_file);
end