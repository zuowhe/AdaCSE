function [dag,g_best_score,conv,iterations] = MYGA_OnceMuta_AdaptCI_process(data,N,M,MP,scoring_fn,bnet,tour,saved_filename,p_value)

BN_NodesNum = size(bnet.dag,1);
ns = bnet.node_sizes;
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
iterations = 0;
max_realtime = get_max_realtime(BN_NodesNum);
inStart = tic;
N2 = bitsll(N,1);

[MI,norm_MI] = get_MI(data,ns); 
norm_MI(isnan(norm_MI)) = 0;
[~,dataNum] = size(data);

p_avg = mean(p_value(:));
fprintf('Average p-value: %2.3f\n', p_avg);
[alpha_candidate,count_CIchange] = updateCI(p_avg, N, M, BN_NodesNum, 0, 0, 0);
   
CI_init = alpha_candidate;
fprintf('Initial CI threshold: %9.5f     ', CI_init);

SuperStructure = xor(true(BN_NodesNum), diag(true(1, BN_NodesNum))); 
for i = 1:BN_NodesNum-1
    for j = i+1:BN_NodesNum
        if p_value(i, j) > CI_init
            SuperStructure(i, j) = false; SuperStructure(j, i) = false;
        end
    end
end
[pop,l_map_MI] = MYGA_initialization(SuperStructure,N2,norm_MI); 
fprintf('Number of bidirectional edges in the initial superstructure: %d\n', size(l_map_MI,1));

pop = MIGA_del_loop_MI(pop,MI,MP);

saved_file = fopen(saved_filename,'w');

max_cache_size = 100*BN_NodesNum;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end

total_overwrite = 0;

[score, cache, once_cache_hits] = score_dags_recover(data, ns, pop,...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);
total_overwrite = total_overwrite + once_cache_hits;

[g_best,g_best_score] = get_best(score,pop);

CI_new = CI_init;
l_map_MI2 = l_map_MI;
Dif_BIC = 0;
for i=1:M
    if toc(inStart) > max_realtime
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    
    [norm_score, ~] = score_normalize(score,g_best_score,false);
    if ~isempty(find(norm_score,1))
        [pop_1,~] = selection_tournament(N,N2,pop,score,tour);
        conf = get_confidence(pop_1(1:N));
        pop_1 = MIGA_crossover(N,pop_1,l_map_MI2,conf,i,M);
    else
        pop_1 = pop;
    end
    
    pop = bitflip_mutation(N2,l_map_MI2,pop_1);
    
    [l_map_MI2] = AdaptiveCI(BN_NodesNum,p_value,norm_MI,CI_new);
    
    pop = MIGA_del_loop_MI(pop,MI,MP);
    
    [score, cache, once_cache_hits] = score_dags_recover(data, ns, pop,...
        'scoring_fn', scoring_fn, ...
        'cache', cache, ...
        'max_cache_size', max_cache_size);
    total_overwrite = total_overwrite + once_cache_hits;
    
    [~,g_best_score2] = get_best(score,pop);
    Dif_BIC = g_best_score2 - g_best_score;
    Dif_BIC = Dif_BIC/log(dataNum);
    [CI_new,count_CIchange] = updateCI(p_avg, N, M, BN_NodesNum, Dif_BIC, CI_new,count_CIchange);
    
    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);

    conv = update_conv(conv,g_best,g_best_score,bnet.dag,i);
    fprintf(saved_file,'%d\n',g_best_score);

    iterations = i;
end
dag = {g_best};
fclose(saved_file);
end