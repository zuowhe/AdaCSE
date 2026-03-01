function [All_dag,eoer,every_best] = PAtrial(tour,scoring_fn,MP,M,N,tol,bnet,trial,TrainData)
% ====== 创建并行计算环境
if isempty(gcp('nocreate'))
    parpool(4);  % 创建一个包含4个工作进程的并行池
end

% ====== eoer - End of Execution Results 运行结果
eoer = cell(trial,1);  
All_dag = cell(trial,1);
every_best = cell(trial,1);
parfor T = 1:trial

    eoer{T} = -1*ones(1,9);
    % tic 函数用于启动一个计时器，用来测量代码执行的时间。tStart 保存了计时开始时的时间点。
    tStart = tic;                                                           
    
    % CB phase: CI test 生成 Super-structure 超结构 
    SuperStructure = get_CI_test(TrainData{T},bnet,tol);
    
    % 主算法调用
    [All_dag{T},eoer{T}(1,4),~,eoer{T}(1,6),every_best{T}] = ...
        PAMIGA_ga_process(SuperStructure,TrainData{T},N,M,MP,scoring_fn,bnet,tour);
    eoer{T}(1,5) = toc(tStart);   

end
end