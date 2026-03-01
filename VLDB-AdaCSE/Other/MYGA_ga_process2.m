function [dag,g_best_score,conv,iterations] = MYGA_ga_process2(SuperStructure,data,N,M,MP,scoring_fn,bnet,tour,saved_filename,CI_values, avg_ss1)
% MIGA / MI初始化 / 锦标赛选择 / MI 去环 / 支持度MI交叉
%% Init
BN_NodesNum = size(bnet.dag,1);         % #网络规模，即网络节点的数量
ns = bnet.node_sizes;           % node sizes
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
iterations = 0;                 % 计数：在指定时间内完成的迭代次数


if isempty(find(SuperStructure,1))          
    [g_best_score,conv] = finalize_output(SuperStructure,data,bnet,scoring_fn,M,conv,1);
    dag = {SuperStructure};
    return
end

max_realtime = get_max_realtime(BN_NodesNum);   % 获取预设的最大运行时间
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群规模，bitsll对输入参数 N 进行二位数上逻辑左移一位操作。

cache_dim = 4*max(64,BN_NodesNum)*max(64,BN_NodesNum);                                      % Cache设置
global cache
% cache = score_init_cache(BN_NodesNum,cache_dim);
cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
% [MI,norm_MI] = get_MI_all(data,ns);   % 获得互信息值和归一化后的互信息值
[MI,norm_MI] = get_MI(data,ns);
% [pop,l_map_MI] = MISS_initialization(SuperStructure,N2,norm_MI);  
[pop,l_map_MI] = MIGA_initialization(SuperStructure,N2,norm_MI); 
fprintf('初始超结构的双向边的数量为: %d\n', size(l_map_MI,1));

pop = MIGA_del_loop_MI(pop,MI,MP);                                         % MI去环，添加了对于父集的限制

saved_file=fopen(saved_filename,'w');

%% 初始化保存结构体
% 预分配 pop_history 和 score_history
pop_size = N2*M;
% pop_history = cell(pop_size, 1);  % 用 cell 数组来保存历史个体，大小为 4 万个元素
% 初始化散列表作为 pop_history
pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');

score_history = zeros(pop_size, 1);  % 用数组来保存历史评分，大小为 4 万个元素
number_edges = zeros(pop_size, 1);  % 用数组来保存历史评分，大小为 4 万个元素
% 统计重复计算的次数
repeated_count = 0;
% 存储的有效种群的长度
length_history = 0;
% 评分

[score,pop_history, score_history,number_edges,repeated_count1,length_history] = Dagzip_repeat_score2(data, N2, ns,...
                                                    pop, pop_history, score_history,number_edges,length_history, scoring_fn);

repeated_count = repeated_count + repeated_count1;
% [score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
[g_best,g_best_score] = get_best(score,pop);    % Get-Elite-Individual 初始化种群最优解

%% Main Loop
alpha2 = avg_ss1/BN_NodesNum;
count_twomutn = 0;
l_map_MI2 = l_map_MI;
for i=1:M
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    
    % 保存当前代的种群和评分
    [norm_score, ~] = score_normalize(score,g_best_score,false);
    if ~isempty(find(norm_score,1)) % all individuals are not the same
        [pop_1,~] = selection_tournament(N,N2,pop,score,tour);        % 选择：锦标赛选择
        conf = get_confidence(pop_1(1:N));
        pop_1 = MIGA_crossover(N,pop_1,l_map_MI2,conf,i,M);            % 交叉：产生新的后代 N→2N
%         pop_1 = Random_crossover(N,pop,l_map_MI);
    else
        pop_1 = pop;
    end
    
    pop = bitflip_mutation(N2,l_map_MI,pop_1);                              % 变异：单点变异
    [~, all_repeats] = Find_repeated_arrays(pop);
    rnum = size(all_repeats,2);
    if rnum == 0
        rnum = 1;
    end
%     alpha1 = avg_ss1/(log(BN_NodesNum) / log(rnum));
    alpha1 = avg_ss1*rnum/BN_NodesNum;
%     alpha1 = avg_ss1/ ((N-rnum)/N*BN_NodesNum);
    if alpha1 > alpha2
        if alpha1 > avg_ss1
            alpha2 = avg_ss1;
        else
            alpha2 = alpha1;
        end
    end
%     if alpha1 > alpha2
%         alpha2 = avg_ss1;
%     end
    [l_map_MI2] = AdaptiveCI(BN_NodesNum,CI_values,norm_MI,alpha2);
    % 找出 l_map_MI2 中有但 l_map_MI 中没有的行
    diff_map = setdiff(l_map_MI2, l_map_MI, 'rows');
    if ~isempty(diff_map)
        count_twomutn = count_twomutn +1;
%         pop = RepeatedZip_mutation2(diff_map,pop,all_repeats);
        pop = RepeatedZip_mutation4(diff_map,pop,all_repeats);
%         pop = RepeatedZip_mutation5(diff_map,pop,all_repeats);
%         l_map_MI = l_map_MI2;
    end
    
%     pop = RepeatedZip_mutation2(N2,l_map_MI,pop_1,repeated_count1,i/M);
%     pop = Points_mutation4_MI(N,l_map_MI,pop);
      
    % 循环变异去重
%     while_num = ceil((M - i)/4);
%     while_num = 10;
%     for w=1:while_num
%         [repeat_indices, all_repeats] = Find_repeated_arrays(pop);
%         if size(all_repeats,2) < ceil(N2/BN_NodesNum)
%             break;
%         end
%         pop = RepeatedZip_mutation2(N2,l_map_MI,pop_1,repeated_count1,i/M,all_repeats);
%     end
    pop = MIGA_del_loop_MI(pop,MI,MP);                                     % 去环：MI 
    
    % [score,pop_history, score_history,repeated_count1,length_history,cache] = Dag_repeat_score(data, N2, ns,...
    %                                                     pop, pop_history, score_history,length_history, scoring_fn, cache);
    [score,pop_history, score_history,number_edges,repeated_count1,length_history, flag_cache] = Dagzip_repeat_score2(data, N2, ns,...
                                                        pop, pop_history, score_history,number_edges,length_history, scoring_fn);
    repeated_count = repeated_count + repeated_count1;

%     [score,cache] = score_dags(data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);

    % 更新最优解
    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);   % Get&Place-Elite-Individual


    conv = update_conv(conv,g_best,g_best_score,bnet.dag,i);               % 更新收敛行为的结构体 conv
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件

    iterations = i;
end
if flag_cache 
    fprintf('预分配的内存不足~');
end
fprintf('最终阈值为:%f     ', alpha2);
fprintf('最终超结构的双向边的数量为: %d\n', size(l_map_MI2,1));
fprintf('二次变异的次数为: %d     ', count_twomutn);
fprintf('避免重复计算的次数为: %d\n', repeated_count);
dag = {g_best};
fclose(saved_file);
end
