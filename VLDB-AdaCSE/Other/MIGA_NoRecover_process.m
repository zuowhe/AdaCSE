function [dag, g_best_score, conv, iterations] = MIGA_NoRecover_process(SuperStructure, data, N, M, MP, scoring_fn, bnet, tour, saved_filename)
%% Init
BN_NodesNum = size(bnet.dag, 1);
ns = bnet.node_sizes;
conv = struct('f1', zeros(1,M), 'se', zeros(1,M), 'sp', zeros(1,M), 'sc', zeros(1,M));
iterations = 0;

max_realtime = get_max_realtime(BN_NodesNum);
inStart = tic;
N2 = bitsll(N, 1); % 2*N

[MI, norm_MI] = get_MI(data, ns);

[pop, l_map_MI] = MIGA_initialization(SuperStructure, N2, norm_MI);
pop = MIGA_del_loop_MI(pop, MI, MP);

cache = containers.Map('KeyType', 'double', 'ValueType', 'any');


[score, cache] = score_dags_NewRecover(data, ns, pop, 'cache', cache);

[g_best, g_best_score] = get_best(score, pop);


saved_file = fopen(saved_filename, 'w');
if saved_file == -1
    error('Cannot open file: %s', saved_filename);
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

    [score, cache] = score_dags_NewRecover(data, ns, pop, 'cache', cache);

    [g_best, g_best_score, pop, score] = update_elite(g_best, g_best_score, pop, score);
    conv = update_conv(conv, g_best, g_best_score, bnet.dag, i);

    fprintf(saved_file, '%d\n', g_best_score);
    iterations = i;
end

fclose(saved_file);
dag = {g_best};

end