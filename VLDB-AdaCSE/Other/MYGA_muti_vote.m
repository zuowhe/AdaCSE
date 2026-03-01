function [dag,g_best_score,conv,iterations] = MYGA_muti_vote(SuperStructure,data,data_all,N,M,MP,scoring_fn,bnet,tour,saved_filename)
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

% max_realtime = get_max_realtime(BN_NodesNum);   % 获取预设的最大运行时间
% inStart = tic;                                                              % tic 运行时间设置
N2 = bitsll(N,1);           % 选择前的种群规模，bitsll对输入参数 N 进行二位数上逻辑左移一位操作。

cache_dim = 4*max(64,BN_NodesNum)*max(64,BN_NodesNum);                                      % Cache设置
cache = score_init_cache(BN_NodesNum,cache_dim);
 % 获得互信息值和归一化后的互信息值
% [MI,norm_MI] = get_MI(data_all,ns);
[MI,norm_MI] = get_MI_all(data_all,ns);

saved_file=fopen(saved_filename,'w');

%% GA Process
%记录每种群最优20个体
all_top20_pop =[]; 
for i=1:3
    train_data = data{i};
    %% 初始化
    [pop,l_map_MI] = MISS_initialization(SuperStructure,N2,norm_MI);                      
    % 利用互信息去环：_naive最简单的贪心删边
    pop = MIGA_del_loop_MI(pop,MI,MP);                                         % MI去环，添加了对于父集的限制
    [score,cache] = score_dags(train_data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
    [g_best,g_best_score] = get_best(score,pop);    % Get-Elite-Individual 初始化种群最优解
    %% 调用后续GA步骤
    % 初始化变量
    max_no_improvement = 200;  % 最大不变次数
    no_improvement_count = 0;  % 当前不变次数计数器
    last_best_score = g_best_score;    % 上一次的最佳评分

    for j = 1:M
        % 规范化评分
        [norm_score, ~] = score_normalize(score, g_best_score, false);
        if ~isempty(find(norm_score, 1)) % all individuals are not the same
            [pop_1, ~] = selection_tournament(N, N2, pop, score, tour);        % 选择：锦标赛选择
            conf = get_confidence(pop_1(1:N));
            pop_1 = MIGA_crossover(N, pop_1, l_map_MI, conf, j, M);            % 交叉：产生新的后代 N→2N
%             pop_1 = crossover_confidence(N, pop_1, l_map_MI, conf, j, M);            % 交叉：产生新的后代 N→2N
        else
            pop_1 = pop;
        end

        pop = bitflip_mutation(N2, l_map_MI, pop_1);                              % 变异：单点变异
        pop = MIGA_del_loop_MI(pop, MI, MP);                                     % 去环：MI 

        [score, cache] = score_dags(train_data, ns, pop, 'scoring_fn', scoring_fn, 'cache', cache);

        [g_best, g_best_score, pop, score] = update_elite(g_best, g_best_score, pop, score);   % Get&Place-Elite-Individual
        conv = update_conv(conv, g_best, g_best_score, bnet.dag, j);               % 更新收敛行为的结构体 conv

        fprintf(saved_file, '%d\n', g_best_score);                                % 将每一次迭代的最佳个体评分写入文件

        % 检查评分是否发生变化
        if g_best_score == last_best_score
            no_improvement_count = no_improvement_count + 1;  % 不变次数加1
        else
            no_improvement_count = 0;  % 如果评分发生变化，重置计数器
        end

        % 如果连续 n 次评分不变，停止迭代
        if no_improvement_count >= max_no_improvement
            fprintf('连续 %d 次评分没有变化，停止迭代。最终迭代次数为%d次。\n', max_no_improvement, j);
            iterations = j;
%             [g_best_score, conv] = finalize_output(g_best, train_data, bnet, scoring_fn, M, conv, iterations);
            break;
        end
        iterations = j;
        last_best_score = g_best_score;
%     fprintf('当代最优个体评分为：%f\n', last_best_score);
    end
    [score, cache] = score_dags(data_all, ns, pop, 'scoring_fn', scoring_fn, 'cache', cache);
    [g_best, g_best_score, pop, score] = update_elite(g_best, g_best_score, pop, score);   % Get&Place-Elite-Individual
    conv = update_conv(conv, g_best, g_best_score, bnet.dag, j);               % 更新收敛行为的结构体 conv
    [g_best,g_best_score] = get_best(score,pop); 
    dag1 = {g_best};
    [F1,~,~,~,~,~,~,~,~,~]= eval_dags_adjust(dag1,bnet.dag,1);
    fprintf('第%d个种群的最优个体评分为：%f\n', i,F1);
    %% 获取最终演化种群
    % 获取评分最高的20个个体
    [~, sorted_indices] = sort(score, 'descend');  % 排序并获取索引
    top_20_indices = sorted_indices(1:20);  % 选取前20个索引
        
    % 根据这些索引筛选出相应的个体
    all_top20_pop = [all_top20_pop,pop(top_20_indices)];
end
% Step 1: 在循环结束后，收集完所有前20个最优个体并存储在 all_top20_pop 中
% all_top20_pop 是一个 cell 数组，其中每个元素是一个二进制矩阵，表示一个个体
% 每个矩阵的大小应一致，即 BN_NodesNum x BN_NodesNum

% Step 2: 初始化最终的个体矩阵（dag），初始值全为0
final_individual = zeros(BN_NodesNum, BN_NodesNum);

% Step 3: 对每个位置进行投票，确定最终的矩阵值
num_top_individuals = length(all_top20_pop);  % 获取前20个最优个体的数量
for row = 1:BN_NodesNum
    for col = 1:BN_NodesNum
        % 获取该位置在所有前20个个体中的投票情况
        votes = zeros(1, num_top_individuals);  % 初始化投票计数器
        for k = 1:num_top_individuals
            votes(k) = all_top20_pop{k}(row, col);  % 记录该位置的投票结果（0 或 1）
        end
        % 进行多数投票：如果超过一半的个体该位置为1，则该位置最终为1，否则为0
        if sum(votes) > num_top_individuals / 2
            final_individual(row, col) = 1;
        else
            final_individual(row, col) = 0;
        end
    end
end

% Step 4: 将最终的个体作为输出的 DAG 返回
dag = {final_individual};



% dag = {g_best};
fclose(saved_file);

end



