function [dag,g_best_score,conv,iterations] = ga_confcross_v1(ss,data,N,M,MP,scoring_fn,bnet,tour,saved_filename)
% MIGA / MI初始化 / 锦标赛选择 / MI 去环 / 支持度MI交叉
% stop_gate = 50;                 % 判断终止条件
%% Init
bns = size(bnet.dag,1);         % #nodes
ns = bnet.node_sizes;           % node sizes
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
iterations = 0;                 % #generations completed in the allotted time

if isempty(find(ss,1))          % input ss has no edges
    [g_best_score,conv] = finalize_output(ss,data,bnet,scoring_fn,M,conv,1);
    dag = {ss};
    return
end

max_realtime = get_max_realtime(bns);   % get max allotted real time
% start = cputime;              % tic
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群 population size before selection

% cache_dim = 256*bns;          % Cache原始值 256
cache_dim = 4*max(64,bns)*max(64,bns);                                      % Cache设置
cache = score_init_cache(bns,cache_dim);
% cache = my_score_init_cache(bns,cache_dim);

[MI,norm_MI] = get_MI(data,ns);
% MI = calculate_mutual_information_array(data);

[pop,pop_a,l_map_MI] = init_pop_ss_MI(ss,N2,norm_MI);                       % 初始化

% 利用互信息去环：_naive最简单的贪心删边
pop = del_loop_MI_naive(pop,MI,MP);                                         % MI去环，添加了对于父集的限制

[score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
[g_best,g_best_score] = get_best(score,pop);    % Get-Elite-Individual 初始化种群最优解
% final_model = g_best;       stop_cnt = 0;     % 保存最后一次的模型进行比较

saved_file=fopen(saved_filename,'w');

%% Main Loop
for i=1:M
%     if cputime-start > max_time   % toc
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    
    [norm_score, ~] = score_normalize(score,g_best_score,false);
    if ~isempty(find(norm_score,1)) % all individuals are not the same
        [pop_1,score_1] = selection_tournament(N,N2,pop,score,tour);        % 选择：锦标赛选择
        conf = get_confidence(pop_1(1:N));
        pop_1 = crossover_confidence(N,pop_1,l_map_MI,conf,i,M);            % 交叉：产生新的后代 N→2N

    else
        pop_1 = pop;
    end
    
    pop = bitflip_mutation(N2,l_map_MI,pop_1);                              % 变异：单点变异
    pop = del_loop_MI_naive(pop,MI,MP);                                     % 去环：MI 

    [score, cache] = score_dags(data,ns,pop,...                             % 评分
        'scoring_fn',scoring_fn,'cache',cache);

    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);   % Get&Place-Elite-Individual
    conv = update_conv(conv,g_best,g_best_score,bnet.dag,i);
    
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件

    iterations = i;
    
end

dag = {g_best};
fclose(saved_file);

end



