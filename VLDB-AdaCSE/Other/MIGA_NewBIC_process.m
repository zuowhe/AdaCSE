function [dag, g_best_score, conv, iterations] = MIGA_NewBIC_process(SuperStructure, data, N, M, MP, scoring_fn, bnet, tour, saved_filename)
% MIGA / MI初始化 / 锦标赛选择 / MI 去环 / 支持度MI交叉

BN_NodesNum = size(bnet.dag, 1);
ns = bnet.node_sizes;
conv = struct('f1', zeros(1,M), 'se', zeros(1,M), 'sp', zeros(1,M), 'sc', zeros(1,M));
iterations = 0;

if isempty(find(SuperStructure, 1))
    [g_best_score, conv] = finalize_output(SuperStructure, data, bnet, scoring_fn, M, conv, 1);
    dag = {SuperStructure};
    return
end

max_realtime = get_max_realtime(BN_NodesNum);
inStart = tic;

N2 = bitsll(N, 1);

% 初始化 cache 并设置最大缓存条目数
max_cache_size = 10*BN_NodesNum;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end

[MI, norm_MI] = get_MI(data, ns);
[pop, l_map_MI] = MIGA_initialization(SuperStructure, N2, norm_MI);
pop = MIGA_del_loop_MI(pop, MI, MP);

% 初始化种群去重结构体
pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');
score_history = [];
number_edges = [];
length_history = 0;
flag_cache = true;

% 第一次评分
[score, pop_history, score_history, number_edges, repeated_count1, length_history, flag_cache, cache,total_onec_overwrite] = ...
    Dagzip_repeat_Node(data, N2, ns, pop, pop_history, score_history, number_edges, length_history, scoring_fn, flag_cache, cache,max_cache_size);
once_cache_hits = repeated_count1;
total_overwrite = total_onec_overwrite;
[g_best, g_best_score] = get_best(score, pop);

saved_file = fopen(saved_filename, 'w');
if saved_file == -1
    error('无法打开文件：%s', saved_filename);
end

%% Main Loop
for i = 1:M
    if toc(inStart) > max_realtime
        iterations = i;
        [g_best_score, conv] = finalize_output(g_best, data, bnet, scoring_fn, M, conv, iterations);
        break;
    end

    [norm_score, ~] = score_normalize(score, g_best_score, false);
    if ~isempty(find(norm_score, 1))
        [pop_1, ~] = selection_tournament(N, N2, pop, score, tour);
        conf = get_confidence(pop_1(1:N));
        pop_1 = MIGA_crossover(N, pop_1, l_map_MI, conf, i, M);
    else
        pop_1 = pop;
    end

    pop = bitflip_mutation(N2, l_map_MI, pop_1);
    pop = MIGA_del_loop_MI(pop, MI, MP);

    % 再次评分
    [score, pop_history, score_history, number_edges, repeated_count1, length_history, flag_cache, cache,total_onec_overwrite] = ...
        Dagzip_repeat_Node(data, N2, ns, pop, pop_history, score_history, number_edges, length_history, scoring_fn, flag_cache, cache,max_cache_size);
    once_cache_hits = once_cache_hits + repeated_count1;
    total_overwrite = total_overwrite + total_onec_overwrite;
    
    [g_best, g_best_score, pop, score] = update_elite(g_best, g_best_score, pop, score);
    conv = update_conv(conv, g_best, g_best_score, bnet.dag, i);
    fprintf(saved_file, '%d\n', g_best_score);
    iterations = i;
end

fprintf('重复计算次数为: %d\n', once_cache_hits);
fprintf('循环覆盖的次数为:%d\n', total_overwrite);
dag = {g_best};
fclose(saved_file);
end