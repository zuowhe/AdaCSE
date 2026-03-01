function [dag,g_best_score,conv,iterations] = MYGA_muti_initialization(SuperStructure,data,data_all,N,M,MP,scoring_fn,bnet,tour,saved_filename)
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
for i=1:10
    train_data = data{i};
    %% 检查是否超时
%     if toc(inStart) > max_realtime                                          % toc 运行时间设置
%         iterations = i;
%         [g_best_score, conv] = finalize_output(g_best, train_data, bnet, scoring_fn, M, conv, iterations);
%         break;
%     end
    %% 初始化
    [pop,l_map_MI] = MIGA_initialization(SuperStructure,N2,norm_MI);                      
    % 利用互信息去环：_naive最简单的贪心删边
    pop = MIGA_del_loop_MI(pop,MI,MP);                                         % MI去环，添加了对于父集的限制
    [score,cache] = score_dags(train_data,ns,pop,'scoring_fn',scoring_fn,'cache',cache);
    [g_best,g_best_score] = get_best(score,pop);    % Get-Elite-Individual 初始化种群最优解
    %% 调用后续GA步骤
    % 初始化变量
    max_no_improvement = 6;  % 最大不变次数
    no_improvement_count = 0;  % 当前不变次数计数器
    last_best_score = g_best_score;    % 上一次的最佳评分

    for j = 1:M
        % 规范化评分
        [norm_score, ~] = score_normalize(score, g_best_score, false);
        if ~isempty(find(norm_score, 1)) % all individuals are not the same
            [pop_1, ~] = selection_tournament(N, N2, pop, score, tour);        % 选择：锦标赛选择
            conf = get_confidence(pop_1(1:N));
%             pop_1 = MIGA_crossover(N, pop_1, l_map_MI, conf, j, M);            % 交叉：产生新的后代 N→2N
            pop_1 = crossover_confidence(N, pop_1, l_map_MI, conf, j, M);            % 交叉：产生新的后代 N→2N
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
%     all_top20_pop = [all_top20_pop,{g_best}];
    %     top_20_pop = pop(top_20_indices, :);
end


%% 尝试一下计算每个dag的总MI来筛选最优
% bestdag_index = 1;
% dag_best_MI = 0;
% [~, top2] = size(all_top20_pop);
% dag_candidate_allmi = zeros(1, top2);
% for i=1:top2
%     dag_candidate = all_top20_pop{1, i};
%     for j=1:BN_NodesNum
%         for k=1:BN_NodesNum
%             if  dag_candidate(j,k) == 1
%                 dag_candidate_allmi(i) = dag_candidate_allmi(i) + MI(j,k);
%             end
%         end
%     end
%     if dag_best_MI < dag_candidate_allmi(i)
%         dag_best_MI = dag_candidate_allmi(i);
%         bestdag_index = i;
%     end
% end
% g_best = all_top20_pop{1,bestdag_index};
% fprintf('十个最优个体的MI为\n');
% disp(dag_candidate_allmi);
% fprintf('第%d个种群的个体总MI最高\n', bestdag_index);

% 对组合种群评分
% [score,cache] = score_dags(data_all,ns,all_top20_pop,'scoring_fn',scoring_fn,'cache',cache);
% fprintf('十个最优个体的评分为\n');
% disp(score);

% %% 最终演化
for i=1:200
        % 对组合种群评分
        [score,cache] = score_dags(data_all,ns,all_top20_pop,'scoring_fn',scoring_fn,'cache',cache);
        all_top20_pop = MIGA_del_loop_MI(all_top20_pop, MI, MP);                                     % 去环：MI 
%         fprintf('十个最优个体的评分为\n');
%         disp(score);
        [g_best,g_best_score] = get_best(score,all_top20_pop);    % Get-Elite-Individual 初始化种群最优解
        [norm_score, ~] = score_normalize(score, g_best_score, false);
        if ~isempty(find(norm_score, 1)) % all individuals are not the same
            [pop_1, ~] = selection_tournament(N, N2, all_top20_pop, score, tour);        % 选择：锦标赛选择
            conf = get_confidence(pop_1(1:N));
            pop_1 = MIGA_crossover(N, pop_1, l_map_MI, conf, j, M);            % 交叉：产生新的后代 N→2N
        else
            pop_1 = all_top20_pop;
        end

        all_top20_pop = bitflip_mutation(N2, l_map_MI, pop_1);                              % 变异：单点变异
        all_top20_pop = MIGA_del_loop_MI(all_top20_pop, MI, MP);                                     % 去环：MI 

        [score, cache] = score_dags(data_all, ns, all_top20_pop, 'scoring_fn', scoring_fn, 'cache', cache);

        [g_best, g_best_score, all_top20_pop, score] = update_elite(g_best, g_best_score, all_top20_pop, score);   % Get&Place-Elite-Individual
        conv = update_conv(conv, g_best, g_best_score, bnet.dag, j);               % 更新收敛行为的结构体 conv

        fprintf(saved_file, '%d\n', g_best_score);                                % 将每一次迭代的最佳个体评分写入文件
end


%% Main Loop


dag = {g_best};
fclose(saved_file);

end



