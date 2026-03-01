function [dag,g_best_score,conv,iterations] = aesl_ga(ss,data,N,M,MP,alpha,d,scoring_fn,bnet,saved_filename)
% Adaptive Elite-based Structure Learner using GA
eval_times = 1;         % 记得保存评分记录
M = M / eval_times;
%% Init
BN_NodesNum = size(bnet.dag,1);   % #nodes
ns = bnet.node_sizes;   % node sizes
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
iterations = M;           % #generations completed in the allotted time

if isempty(find(ss,1))  % input ss has no edges
    [g_best_score,conv] = finalize_output(ss,data,bnet,scoring_fn,M,conv,1);
    dag = {ss};
    return
end

max_realtime = get_max_realtime(BN_NodesNum);   % get max allotted real time
% start = cputime;                % tic
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);       % population size before selection

% % cache_dim = 256*bns;          % Cache原始值 256
% cache_dim = 4*max(64,bns)*max(64,bns);                                      % Cache设置
% cache = score_init_cache(bns,cache_dim);

dm = d.m0;              dM = d.M0;  % time-sensitive healthy diversity interval
dms = (d.m1-d.m0)/M;    dMs = (d.M1-d.M0)/M;

[pop,l_map,l_cnt] = init_pop_ss(ss,N2);                                     % 初始化
pop = make_dag(pop,MP);   % Make-DAG & Naive-Limit-Parents

MP = repmat(MP,1,BN_NodesNum);        % dynamic MP thresholds array init
pwm = ones(l_cnt,3)/3;  % uniform pwm

% 初始化 cache 并设置最大缓存条目数
max_cache_size = 100*BN_NodesNum;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end
total_overwrite = 0;

[score, cache,once_cache_hits] = score_dags_recover(data, ns, pop,...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);
total_overwrite = total_overwrite + once_cache_hits;
[g_best,g_best_score] = get_elite(score,pop); % Get-Elite-Individual

saved_file=fopen(saved_filename,'w');

%% Main Loop
for i=1:M
%     if cputime-start > max_time   % toc
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    
    [norm_score,sum_norm_score] = score_normalize(score,g_best_score,true);
    if ~isempty(find(norm_score,1))     % all individuals are not the same
        [p2,score2] = proportional_selection(N,N2,pop,score,norm_score,sum_norm_score);
        p2 = uniform_crossover(N,p2,l_map);
        p2(N+1:N2) = make_dag_elite(p2(N+1:N2),MP,l_map,pwm); % Make-DAG & Elite-Guided-Limit-Parents
%         [score2(N+1:N2),cache] = score_dags(data,ns,p2(N+1:N2),'scoring_fn',scoring_fn,'cache',cache);
        [score2(N+1:N2),cache] = score_dags_recover(data,ns,p2(N+1:N2),...
                        'scoring_fn', scoring_fn, ...
                        'cache', cache, ...
                        'max_cache_size', max_cache_size);
        total_overwrite = total_overwrite + once_cache_hits;
        
        [g_best2,g_best_score2] = get_elite(score2,p2);
        fprintf(saved_file,'%d\n',max(g_best_score2,g_best_score));                                % 将每一次迭代的最佳个体评分写入文件
        
        [norm_score2,~] = score_normalize(score2,g_best_score2,false);
        [es,e_score] = form_elite_set(alpha,N2,p2,norm_score2);
        alpha = update_alpha(l_map,g_best2,es,alpha,dm,dM);
        pwm = construct_pwm(l_cnt,e_score,es,ss);
    else
        p2 = pop;
        norm_score2 = norm_score;
        pwm = ones(l_cnt,3)/3;  % uniform pwm
    end 
    pop = sirg_mutation(N2,l_map,p2,norm_score2,pwm);
    MP = update_mp(MP,MP,es);
    pop = make_dag_elite(pop,MP,l_map,pwm);
%     [score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
    [score, cache,once_cache_hits] = score_dags_recover(data, ns, pop,...
                            'scoring_fn', scoring_fn, ...
                            'cache', cache, ...
                            'max_cache_size', max_cache_size);
    total_overwrite = total_overwrite + once_cache_hits;
    [g_best,g_best_score] = get_elite(score,pop); % Get-Elite-Individual

    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);   % Get&Place-Elite-Individual
    if g_best_score2 > g_best_score
        g_best_score = g_best_score2;
    end
    conv = update_conv(conv,g_best,g_best_score,bnet.dag,i);
    
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件

    iterations = i;
    
    dm = dm+dms;    dM = dM+dMs;    % healthy diversity interval update
end
fprintf('循环覆盖的次数为:%d\n', total_overwrite);
dag = {g_best};
fclose(saved_file);
end
