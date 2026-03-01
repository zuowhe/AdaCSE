function [dag,g_best_score,conv,iterations] = ekga_bn(ss,data,N,M,MP,elite_gate,d,scoring_fn,bnet,tour,tour_limit,saved_filename)
% BNsGA 主算法流程
eval_times = 1;         % 记得保存评分记录
M = M / eval_times;
%% Init
bns = size(bnet.dag,1);             % bnet size 节点数
ns = bnet.node_sizes;               % node sizes 节点大小
iterations = M;                     % #generations completed in the allotted time
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));

if isempty(find(ss,1))              % input ss has no edges
    [g_best_score,conv] = finalize_output(ss,data,bnet,scoring_fn,M,conv,1);
    dag = {ss};
    return
end

max_realtime = get_max_realtime(bns);   % get max allotted real time
% start = cputime;                  % tic
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群 population size before selection

% cache_dim = 256*bns;              % Cache原始值 256
cache_dim = 4*max(64,bns)*max(64,bns);                                      % Cache设置
cache = score_init_cache(bns,cache_dim);

% [score, cache] = score_dags(data, ns, {bnet.dag}, 'scoring_fn', scoring_fn, 'cache',cache);
% fprintf('std score :                                    %9.5f\n',score(1));

dm = d.m0;              dM = d.M0;  % time-sensitive healthy diversity interval
dms = (d.m1-d.m0)/M;    dMs = (d.M1-d.M0)/M;

[pop,l_map,l_cnt] = init_pop_ss(ss,N2);                                     % 初始化
pop = make_dag(pop,MP);             % 对种群的父集进行限制，去环
[score, cache] = score_dags(data, ns, pop, 'scoring_fn', scoring_fn, 'cache',cache);

[g_best,g_best_score] = get_best(score,pop);    % 初始化种群最优解

MP = repmat(MP,1,bns);    % useful to comply with aesl_ga & simplify make_dag_elite() logic
pwm = ones(l_cnt,3)/3;              % 初始化 位置权重矩阵 pwm

saved_file=fopen(saved_filename,'w');
%% Main Loop
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

        pop2 = uniform_crossover(N,pop2,l_map);
        % 最小反馈弧集算法，去环
        pop2(N+1:N2) = make_dag_elite(pop2(N+1:N2),MP,l_map,pwm); % Make-DAG & Elite-Guided-Limit-Parents
        [score2(N+1:N2),cache] = score_dags(data,ns,pop2(N+1:N2),'scoring_fn',scoring_fn,'cache',cache);
        [g_best2,g_best_score2] = get_best(score2,pop2);
        fprintf(saved_file,'%d\n',g_best_score2);                           % 将每一次迭代的最佳个体评分写入文件
        
        [norm_score2, ~] = score_normalize(score2, g_best_score2,false);
        
        % elite set (es) initialize
        [elite_set, elite_score] = form_elite_set(elite_gate,N2,pop2,norm_score2);
        elite_gate = update_alpha(l_map,g_best2,elite_set,elite_gate,dm,dM);
        
        % 获取精英集中的共同部分 es_common_s (elite set common struct)
        es_common_s = get_common_s(elite_set,l_map);
        pwm = construct_pwm(l_cnt,elite_score,elite_set,ss);
    else
        pop2 = pop;
        norm_score2 = norm_score;
        pwm = ones(l_cnt,3)/3;      % uniform pwm
    end
    pop = sirg_mutation(N2,l_map,pop2,norm_score2,pwm);
    pop = make_dag_elite(pop,MP,l_map,pwm);
    
    % Algo2: Knowledge-driven mutation Procedure
    % 根据精英集的共同部分进行变异
    pop = mutate_common_s(N,pop,es_common_s,l_map);
    
    pop = make_dag_elite(pop,MP,l_map,pwm);
    [score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);   % Get&Place-Elite-Individual
    conv = update_conv(conv, g_best,g_best_score,bnet.dag,i);
    dm = dm+dms;    dM = dM+dMs;    % healthy diversity interval update
    
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件
    
end
dag = {g_best};
fclose(saved_file);

end


