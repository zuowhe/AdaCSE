function Algo_hybrid_SLA_AdaptCI(Ds,BN_Name,N,M,MP,bnet,trial,scoring_fn)
%% hybrid_SLA
AlgoName = 'hybrid_SLA_AdaptCI';         % 记录运行算法的名称，便于后续结果的存储

%% ====================  Init 初始化  ========================
% ====== 命令行窗口提示
fprintf('Running... %s_%s%s - N=%s M=%s [%s]\n',...
    AlgoName,BN_Name,num2str(Ds),num2str(N),num2str(M),datestr(now));     
fprintf('Iter   F1 Score   Sensitivity   Specificity   Precision   HD    Bayes Score      Exe Time  #Generations TP  TP2  FN  FP  TN   score_chushi \n');
% ====== tol - CI test threshold for CB phase CI测试的阈值
tol = 0.01;
% ====== eoer - End of Execution Results 运行结果
eoer = cell(trial,1);               
% ====== conv - Convergence Behavior structure 定义收敛行为结构体
conv(1:trial) = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M)); 

NetSizeStr = sprintf('%s%s',BN_Name,num2str(Ds));     % 将网络名和数据规模整合成一个字符串
% ====== 读取本地mat数据集文件
data = load(NetSizeStr);
TrainData = data.(NetSizeStr);
% ↓↓==== BN网络中DAG不全为0 1值时使用logical()代码
% ↓↓==== logical(A) 将 A 转换为一个逻辑值数组。A 中的任意非零元素都将转换为逻辑值 1 (true)，零则转换为逻辑值 0 (false)。
% bnet.dag = logical(bnet.dag);   

format shortG     % 控制数值的显示方式。

% ====== 创建结果保存目录
NowDate = [datestr(now,10),datestr(now,5),datestr(now,7)];     % 获取当前日期
result_dir = ['[result]/',NowDate];    % 将路径字符串 [result]/ 与变量 NowDate 进行拼接，作为后续存储实验结果的文件夹路径
if ~exist(result_dir,'dir')       % 检查 result_dir 指定的目录是否存在，~ 符号是 MATLAB 中的逻辑取反运算符。
    mkdir(result_dir);            % 如果不存在 (~exist(...))，则使用 mkdir(result_dir) 创建该目录。
end
% 拼接存储单组实验结果的CSV文件的名称====[result]/NowDate/网络名称和训练集大小_种群规模_最大迭代_算法名称
saves_filename_result = sprintf('[result]/%s/%s%s_%s_%s_%s.csv',...   
    NowDate,BN_Name,num2str(Ds),num2str(N),num2str(M),AlgoName);

% ====== 创建收敛行为保存目录
convergence_dir = ['[result]/',NowDate,'/Convergence_Behavior'];
if ~exist(convergence_dir,'dir')
    mkdir(convergence_dir);
end

%% GA
for T = 1:trial
    % 拼接存储单次收敛过程的CSV文件的名称
    saves_result_file = sprintf('[result]/%s/Convergence_Behavior/%s%s_%s_%s_%s-%s.csv',...
        NowDate,BN_Name,num2str(Ds),num2str(N),num2str(M),AlgoName,num2str(T,'%02d'));
    eoer{T} = -1*ones(1,9);
    % tic 函数用于启动一个计时器，用来测量代码执行的时间。tStart 保存了计时开始时的时间点。
    tStart = tic;                                                           
    
    % CB phase: CI test 生成 Super-structure 超结构 
    p_value = he_get_CI_test(TrainData{T},bnet,tol);
%     SuperStructure = get_CI_test(TrainData{T},bnet,tol);
    
    % 主算法调用
    [dag,eoer{T}(1,4),conv(T),eoer{T}(1,6)] = ...
        hybrid_SAL_AdaptCI(TrainData{T},N,M,MP,scoring_fn,bnet,saves_result_file,p_value);
    
   % 整理结果
    eoer{T}(1,5) = toc(tStart);                                             % toc
    [eoer{T}(1,1),eoer{T}(1,2),eoer{T}(1,3),eoer{T}(1,8),eoer{T}(1,7),TP,TP2,FN,FP,TN]= eval_dags_adjust(dag,bnet.dag,1);
    
    fprintf('%4d  %9.5f    %9.5f    %9.5f  %9.5f  %3.1f   %11.3f  %11.3f      %4d       %4d%4d%4d%4d%4d   %11.3f\n',...
        T,eoer{T}(1),eoer{T}(2),eoer{T}(3),eoer{T}(8),eoer{T}(7),eoer{T}(4),eoer{T}(5),eoer{T}(6),TP,TP2,FN,FP,TN,eoer{T}(1,9));
        %10 01\TP完全正确的边数\TP2对一半的边数\%FN完全错误的边数\
        %00\FP完全错误的边数\%TN完全正确的边数
    
    saved_file = fopen(saves_filename_result,'a+');         % a+:文件若不存在，自动创建
    fprintf(saved_file,'%4d,%9.5f,%9.5f,%9.5f,%9.5f,%3.1f,%11.3f,%11.3f,%4d     %4d %4d %4d %4d %4d    %11.3f\n',...
        T,eoer{T}(1),eoer{T}(2),eoer{T}(3),eoer{T}(8),eoer{T}(7),eoer{T}(4),eoer{T}(5),eoer{T}(6),TP,TP2,FN,FP,TN,eoer{T}(1,9));
end

%% End of Execution Results

[eoer_avg, eoer_std] = avg_std(eoer,trial);
print_avg_std(eoer_avg,eoer_std);
fprintf(saved_file,'Avg,%9.5f,%9.5f,%9.5f,%9.5f,%5.3f,%11.3f,%11.3f,%7.3f,%11.3f\n',...
        eoer_avg(1),eoer_avg(2),eoer_avg(3),eoer_avg(8),eoer_avg(7),eoer_avg(4),eoer_avg(5),eoer_avg(6),eoer_avg(9));
fprintf(saved_file,'Std,%9.5f,%9.5f,%9.5f,%9.5f,%5.3f,%11.3f,%11.3f,%7.3f,%11.3f\n',...
        eoer_std(1),eoer_std(2),eoer_std(3),eoer_std(8),eoer_std(7),eoer_std(4),eoer_std(5),eoer_std(6),eoer_std(9)); 
fclose(saved_file);

end

