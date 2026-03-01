function [dag,g_best_score,conv,iterations] = EKGA_AdaCI(data,N,M,MP,elite_gate,d,scoring_fn,bnet,tour,tour_limit,saved_filename,p_value)
% BNsGA 主算法流程
eval_times = 2;         % 记得保存评分记录
M = M / eval_times;
%% Init
BN_NodesNum = size(bnet.dag,1);             % bnet size 节点数
ns = bnet.node_sizes;               % node sizes 节点大小
iterations = M;                     % #generations completed in the allotted time
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));

max_realtime = get_max_realtime(BN_NodesNum);   % get max allotted real time
% start = cputime;                  % tic
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群 population size before selection

%% 自适应CI
[~,dataNum] = size(data);
% 计算初始CI阈值
p_avg = mean(p_value(:));  % 所有p_value的平均值
fprintf('p-value的均值为: %2.3f\n', p_avg);
[alpha_candidate,count_CIchange] = updateCI(p_avg, N, M, BN_NodesNum, 0, 0, 0);
CI_init = alpha_candidate;
fprintf('CI的初始阈值:%9.5f     ', CI_init);

% 构造超结构，然后初始化种群
SuperStructure = xor(true(BN_NodesNum), diag(true(1, BN_NodesNum))); 
for i = 1:BN_NodesNum-1
    for j = i+1:BN_NodesNum
        if p_value(i, j) > CI_init
            SuperStructure(i, j) = false; SuperStructure(j, i) = false;   % remove edge
        end
    end
end

dm = d.m0;              dM = d.M0;  % time-sensitive healthy diversity interval
dms = (d.m1-d.m0)/M;    dMs = (d.M1-d.M0)/M;

[pop,l_map,l_cnt] = init_pop_ss(SuperStructure,N2);                                     % 初始化
pop = make_dag(pop,MP);             % 对种群的父集进行限制，去环

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

[g_best,g_best_score] = get_best(score,pop);    % 初始化种群最优解

MP = repmat(MP,1,BN_NodesNum);    % useful to comply with aesl_ga & simplify make_dag_elite() logic
pwm = ones(l_cnt,3)/3;              % 初始化 位置权重矩阵 pwm

saved_file=fopen(saved_filename,'w');
%% Main Loop
CI_new = CI_init;
for i = 1:M
%     if cputime-start > max_time   % toc
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    [norm_score, ~] = score_normalize(score, g_best_score, false);
    if ~isempty(find(norm_score, 1))
        % Algo1: Diversity-guided HC Tournament Selection
        % 锦标赛选择，限制单个个体最大数量 ~=norm_score2
        [pop2,score2,~] = tournament_selection_limit(N,N2,pop,score,norm_score,tour,tour_limit);
        % 爬山法变异，选最优进行替换
        [pop2,score2] = HC_mutation(pop2,score2,N);
        
        [l_map_MI2] = AdaptiveCI_other(BN_NodesNum,p_value,CI_new);
        pop2 = uniform_crossover(N,pop2,l_map_MI2);
        
        % 最小反馈弧集算法，去环
        pop2(N+1:N2) = make_dag_naive(pop2(N+1:N2),MP); % Make-DAG & Elite-Guided-Limit-Parents
%         [score2(N+1:N2),cache] = score_dags(data,ns,pop2(N+1:N2),'scoring_fn',scoring_fn,'cache',cache);
        [score2(N+1:N2), cache,once_cache_hits] = score_dags_recover(data,ns,pop2(N+1:N2),...
                                            'scoring_fn', scoring_fn, ...
                                            'cache', cache, ...
                                            'max_cache_size', max_cache_size);
        total_overwrite = total_overwrite + once_cache_hits;
        % 更新CI                                    
        [g_best2,g_best_score2] = get_best(score2,pop2);
        
        fprintf(saved_file,'%d\n',g_best_score2);                           % 将每一次迭代的最佳个体评分写入文件
        
        [norm_score2, ~] = score_normalize(score2, g_best_score2,false);
        
        % elite set (es) initialize
        [elite_set, elite_score] = form_elite_set(elite_gate,N2,pop2,norm_score2);
        elite_gate = update_alpha(l_map_MI2,g_best2,elite_set,elite_gate,dm,dM);
        
        % 获取精英集中的共同部分 es_common_s (elite set common struct)
        es_common_s = get_common_s_0(elite_set,l_map_MI2);
        pwm = construct_pwm(l_cnt,elite_score,elite_set,SuperStructure);
    else
        pop2 = pop;
        norm_score2 = norm_score;
        pwm = ones(l_cnt,3)/3;      % uniform pwm
    end
    pop = sirg_mutation(N2,l_map,pop2,norm_score2,pwm);
    pop = make_dag_naive(pop,MP);
    
    % Algo2: Knowledge-driven mutation Procedure
    % 根据精英集的共同部分进行变异
    pop = mutate_common_s_0(N2,pop,es_common_s,l_map);
    
    pop = make_dag_naive(pop,MP);
    [score, cache,once_cache_hits] = score_dags_recover(data, ns, pop,...
                                            'scoring_fn', scoring_fn, ...
                                            'cache', cache, ...
                                            'max_cache_size', max_cache_size);
                                            total_overwrite = total_overwrite + once_cache_hits;
%     [score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);

    
    [g_best,g_best_score,pop,score] = update_elite(g_best2,g_best_score2,pop,score);   % Get&Place-Elite-Individual
    Dif_BIC = g_best_score2 - g_best_score;
    Dif_BIC = Dif_BIC/log(dataNum);
    [CI_new,count_CIchange] = updateCI(p_avg, N, M, BN_NodesNum, Dif_BIC, CI_new,count_CIchange);
    conv = update_conv(conv, g_best,g_best_score,bnet.dag,i);
    dm = dm+dms;    dM = dM+dMs;    % healthy diversity interval update
    
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件
    
end
fprintf('最终阈值为:%f     ', CI_new);
fprintf('循环覆盖的次数为:%d\n', total_overwrite);
dag = {g_best};
fclose(saved_file);

end


