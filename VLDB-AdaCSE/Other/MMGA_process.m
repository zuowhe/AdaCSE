function [dag, g_best_score, conv, iterations] = MIGA_OnlyBIC_process(SuperStructure, data, N, M, MP, scoring_fn, bnet, tour, saved_filename)
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
max_cache_size = 100;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end

[MI, norm_MI] = get_MI(data, ns);
[pop, l_map_MI] = MMGA_initialization(SuperStructure, N2, norm_MI);
pop = MIGA_del_loop_MI(pop, MI, MP);

total_overwrite = 0;

[score, cache,once_cache_hits] = score_dags_recover(data, ns, pop,...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);
once_cache_hits = total_overwrite + once_cache_hits;

[g_best, g_best_score] = get_best(score, pop);

saved_file = fopen(saved_filename, 'w');
if saved_file == -1
    error('无法打开文件：%s', saved_filename);
end
max_parents = 3;


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
        pop_1 = crossover_confidence(N,pop_1,l_map_MI,conf,i,M);            % 交叉：产生新的后代 N→2N
    else
        pop_1 = pop;
    end

    pop = MMGA_mutation(N2,l_map_MI,pop_1,i,M);
    
    
    pop = MIGA_del_loop_MI(pop, MI, MP);
    
    % 最大父节点限制策略
    pop = parent_node_constraint(pop, MI, max_parents, i, M);

    [score, cache,once_cache_hits] = score_dags_recover(data, ns, pop,...
        'scoring_fn', scoring_fn, ...
        'cache', cache, ...
        'max_cache_size', max_cache_size);
    once_cache_hits = total_overwrite + once_cache_hits;

    [g_best, g_best_score, pop, score] = update_elite(g_best, g_best_score, pop, score);
    conv = update_conv(conv, g_best, g_best_score, bnet.dag, i);
    fprintf(saved_file, '%d\n', g_best_score);
    iterations = i;
end
fprintf('循环覆盖的次数为:%d\n', once_cache_hits);
dag = {g_best};
fclose(saved_file);
end