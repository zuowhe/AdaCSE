function [dag,g_best_score,conv,iterations] =  MIGA_ReBIC_process(SuperStructure,data,N,M,MP,scoring_fn,bnet,tour,saved_filename)
% MIGA / MI初始化 / 锦标赛选择 / MI 去环 / 支持度MI交叉
% stop_gate = 50;                 % 判断终止条件
%% Init
BN_NodesNum = size(bnet.dag,1);         % #网络规模，即网络节点的数量
ns = bnet.node_sizes;           % node sizes
conv = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));
iterations = 0;                 % 计数：在指定时间内完成的迭代次数
% 如果输入的超结构没有边，则执行if操作，提前中止算法运行
% find(SuperStructure,1)查找 SuperStructure 中的第一个非零元素的索引。
% 如果找到了非零元素，find 函数将返回该元素的索引；如果没有找到，将返回空数组 []。
% isempty(find(SuperStructure, 1)) 检查 find 函数的结果是否为空
if isempty(find(SuperStructure,1))          
    [g_best_score,conv] = finalize_output(SuperStructure,data,bnet,scoring_fn,M,conv,1);
    dag = {SuperStructure};
    return
end

max_realtime = get_max_realtime(BN_NodesNum);   % 获取预设的最大运行时间
inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群规模，bitsll对输入参数 N 进行二位数上逻辑左移一位操作。

cache_dim = 4*max(64,BN_NodesNum)*max(64,BN_NodesNum);                                      % Cache设置
% global cache
cache = score_init_cache(BN_NodesNum,cache_dim);
 % 获得互信息值和归一化后的互信息值
[MI,norm_MI] = get_MI(data,ns);
 % 初始化
[pop,l_map_MI] = MIGA_initialization(SuperStructure,N2,norm_MI);  

% 利用互信息去环：_naive最简单的贪心删边
pop = MIGA_del_loop_MI(pop,MI,MP);                                         % MI去环，添加了对于父集的限制


saved_file=fopen(saved_filename,'w');
%% 初始化保存结构体
% 预分配 pop_history 和 score_history
pop_size = N2*M;
% 初始化散列表作为 pop_history
% pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');
pop_history = cell(pop_size, 1);  % 用 cell 数组来保存历史个体，大小为 4 万个元素
score_history = zeros(pop_size, 1);  % 用数组来保存历史评分，大小为 4 万个元素
number_edges = zeros(pop_size, 1);  % 用数组来保存历史评分，大小为 4 万个元素
% 统计重复计算的次数
repeated_count = 0;
% 存储的有效种群的长度
length_history = 0;
% 评分
flag_cache = 0;
[score,pop_history, score_history,number_edges,repeated_count1,length_history,flag_cache,cache] = Dagzip_repeat_score2(data, N2, ns,...
                                                    pop, pop_history, score_history,number_edges,length_history, scoring_fn,flag_cache,cache);

repeated_count = repeated_count + repeated_count1;
[g_best,g_best_score] = get_best(score,pop);    % Get-Elite-Individual 初始化种群最优解



%% Main Loop
for i=1:M
    if toc(inStart) > max_realtime                                          % toc 运行时间设置
        iterations = i;
        [g_best_score,conv] = finalize_output(g_best,data,bnet,scoring_fn,M,conv,iterations);
        break;
    end
    
    [norm_score, ~] = score_normalize(score,g_best_score,false);
    if ~isempty(find(norm_score,1)) % all individuals are not the same
        [pop_1,~] = selection_tournament(N,N2,pop,score,tour);        % 选择：锦标赛选择
        conf = get_confidence(pop_1(1:N));
        pop_1 = MIGA_crossover(N,pop_1,l_map_MI,conf,i,M);            % 交叉：产生新的后代 N→2N
%         pop_1 = crossover_confidence(N,pop_1,l_map_MI,conf,i,M);            % 交叉：产生新的后代 N→2N

    else
        pop_1 = pop;
    end
    
    pop = bitflip_mutation(N2,l_map_MI,pop_1);                              % 变异：单点变异
    pop = MIGA_del_loop_MI(pop,MI,MP);                                     % 去环：MI 

    [score,pop_history, score_history,number_edges,repeated_count1,length_history,flag_cache,cache] = Dagzip_repeat_score2(data, N2, ns,...
                                                    pop, pop_history, score_history,number_edges,length_history, scoring_fn,flag_cache,cache);
    repeated_count = repeated_count + repeated_count1;


    [g_best,g_best_score,pop,score] = update_elite(g_best,g_best_score,pop,score);   % Get&Place-Elite-Individual
    conv = update_conv(conv,g_best,g_best_score,bnet.dag,i);               % 更新收敛行为的结构体 conv
    
    fprintf(saved_file,'%d\n',g_best_score);                                % 将每一次迭代的最佳个体评分写入文件

    iterations = i;

end

fprintf('避免重复计算的次数为: %d\n', repeated_count);
dag = {g_best};
fclose(saved_file);

end



