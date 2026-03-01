function [dag,sc_star,conv,last_gen] = hybrid_SLA_AdaptCI(data,N,M,MP,scoring_fn,bnet,saved_filename,p_value)
% Standard GA implementing Parent Set Crossover


%% Init
BN_NodesNum = size(bnet.dag,1);   % #nodes
ns = bnet.node_sizes;   % node sizes
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
last_gen = M;           % #generations completed in the allotted time


max_realtime = get_max_realtime(BN_NodesNum);   % get max allotted real time
% start = cputime;                % tic
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);   % population size before selection

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

[pop,l_map,~] = init_pop_ss(SuperStructure,N2);                                           % 初始化
pop = make_dag(pop,MP);     % Make-DAG & Limit-Parents


% % 初始化 cache 并设置最大缓存条目数
max_cache_size = 1000*BN_NodesNum;
cache = cell(1, BN_NodesNum);
for k = 1:BN_NodesNum
    cache{k} = struct('masks', [], 'scores', []);
end

total_overwrite = 0;

[score, cache,once_cache_hits] = score_dags_NewRecover(data, ns, pop,...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);
total_overwrite = total_overwrite + once_cache_hits;

[~,g_best_score] = get_best(score,pop);
[x_star,sc_star] = get_elite(score,pop);  % Get-Elite-Individual

saved_file=fopen(saved_filename,'w');

%% Main Loop
CI_new = CI_init;

for i=1:M
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        last_gen = i;
        [sc_star,conv] = finalize_output(x_star,data,bnet,scoring_fn,M,conv,last_gen);
        break;
    end
    [l_map_MI2] = AdaptiveCI_other(BN_NodesNum,p_value,CI_new);
    [norm_score, ~] = score_normalize(score,sc_star,true);
    
    if ~isempty(find(norm_score,1)) % all individuals are not the same
        [pop2,~] = CHC_selection(N,pop,score);
        pop2 = CHC_crossover(N,pop2,l_map_MI2);
        pop2(N+1:N2) = make_dag_naive(pop2(N+1:N2),MP);
    else
        pop2 = pop;
    end
    
    pop = CHC_mutation(N2,l_map_MI2,pop2);
    pop = make_dag_naive(pop,MP);
    
    [score, cache,once_cache_hits] = score_dags_NewRecover(data, ns, pop,...
    'scoring_fn', scoring_fn, ...
    'cache', cache, ...
    'max_cache_size', max_cache_size);
    total_overwrite = total_overwrite + once_cache_hits;
    
    % 更新CI
    [~,g_best_score2] = get_best(score,pop);
    Dif_BIC = (g_best_score2 - g_best_score) / log(dataNum);
    [CI_new, count_CIchange] = updateCI(p_avg, N, M, BN_NodesNum, Dif_BIC, CI_new, count_CIchange);
    g_best_score = g_best_score2;
    
    [x_star,sc_star,pop,score] = update_elite(x_star,sc_star,pop,score);   % Get&Place-Elite-Individual
    
    conv = update_conv(conv,x_star,sc_star,bnet.dag,i);

    
    fprintf(saved_file,'%d\n',sc_star);
end
fprintf('最终阈值为:%f     ', CI_new);
fprintf('循环覆盖的次数为:%d\n', total_overwrite);
dag = {x_star};
fclose(saved_file);
end

function [p_next,score_next] = CHC_selection(N,p,score)
% 取评分最好的一半个体
% input:p(N),p_prev(N)
% output:p_next(N)
[tmp_score_sort, ind] = sort(score,'descend');
tmp_p_sort = p(ind);
tmp_p_sort = tmp_p_sort(1:N);
tmp_score_sort = tmp_score_sort(1:N);
randIndex = randperm(N);
p_next = tmp_p_sort(randIndex);
score_next = tmp_score_sort(randIndex);
end

function [s] = CHC_crossover(N,s,l_map)
% 0.75随父亲，0.25随母亲
l_cnt = size(l_map,1);
for i=1:N
    j = i;
    while i==j
        j = randi(N);
    end
    s{N+i} = s{i};
    for l=1:l_cnt
        e1 = l_map(l,1);    e2 = l_map(l,2);
        if 0.75 >= rand
            s{N+i}(e1,e2) = s{i}(e1,e2);    s{N+i}(e2,e1) = s{i}(e2,e1);
        else
            s{N+i}(e1,e2) = s{j}(e1,e2);    s{N+i}(e2,e1) = s{j}(e2,e1);
        end
    end
end
end

function [p] = CHC_mutation(N,l_map,p)
% 取一半个体随机变异
l_cnt = size(l_map,1);
m = 0.01;            % mutation rate
for l=1:l_cnt
    j = l_map(l,1);     k = l_map(l,2);
    for i=(N/2):N
        l_val = get_allele(p{i}(j,k),p{i}(k,j));
        if m >= rand
            l_val_new = mod(l_val + round(rand),3)+1;   % randomly pick one of remaining alleles
            switch l_val_new
                case 1
                    p{i}(j,k)=false; p{i}(k,j)=false;
                case 2
                    p{i}(j,k)=false; p{i}(k,j)=true;
                case 3
                    p{i}(j,k)=true; p{i}(k,j)=false;
            end
        end
    end
end
end