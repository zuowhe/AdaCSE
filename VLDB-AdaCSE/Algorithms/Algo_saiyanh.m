function Algo_saiyanh(Ds,BN_Name,N,M,bnet,trial,scoring_fn)
%% CausalExplorer MMHC
% eoer - End Of Execution Results 运行结果
% conv - Convergence Behavior structure 收敛行为结构

AlgoName = ['SaiyanH'];

%% Init 初始化
fprintf('Running... %s_%s%s - N=%s M=%s [%s]\n',...
    AlgoName,BN_Name,num2str(Ds),num2str(N),num2str(M),datestr(now));
fprintf('Iter   F1 Score  Sensitivity  Specificity   HD   Bayes Score     Exe Time  #Generations\n');
bns = size(bnet.dag,1);         % #nodes
cache_dim = 4*max(64,bns)*max(64,bns);                                      % Cache设置
cache = score_init_cache(bns,cache_dim);

NetSizeStr = sprintf('%s%s',BN_Name,num2str(Ds));     % 将网络名和数据规模整合成一个字符串
% ====== 读取本地mat数据集文件
data = load(NetSizeStr);
TrainData = data.(NetSizeStr);

format shortG

% ====== 创建结果保存目录
NowDate = [datestr(now,10),datestr(now,5),datestr(now,7)];     % 获取当前日期
result_dir = ['[result]/',NowDate];    % 将路径字符串 [result]/ 与变量 NowDate 进行拼接，作为后续存储实验结果的文件夹路径
if ~exist(result_dir,'dir')       % 检查 result_dir 指定的目录是否存在，~ 符号是 MATLAB 中的逻辑取反运算符。
    mkdir(result_dir);            % 如果不存在 (~exist(...))，则使用 mkdir(result_dir) 创建该目录。
end
% 拼接存储单组实验结果的CSV文件的名称====[result]/NowDate/网络名称和训练集大小_种群规模_最大迭代_算法名称
saves_filename_result = sprintf('[result]/%s/%s%s_%s_%s_%s.csv',...   
    NowDate,BN_Name,num2str(Ds),num2str(N),num2str(M),AlgoName);
target_file_path = sprintf('[result]/00_SaiyanH/%s',dataset);

%% MMHC
for T = 1:trial
    eoer{T} = -1*ones(1,9);
    
    terget_file = sprintf('%s/%s_%d.csv',target_file_path,NetSizeStr,T);

    dag = csvread(terget_file);

     [eoer{T}(1,4)] = score_dags(data{T},bnet.node_sizes,{dag},'scoring_fn',scoring_fn,'cache',cache);
    
    % 整理结果
%     eoer{T}(1,5) = toc(tStart);                                             % toc

    eoer{T}(1,7) = get_HD(dag,bnet.dag);        % HD
    [eoer{T}(1,1),eoer{T}(1,2),eoer{T}(1,3)] = eval_dags({dag},bnet.dag,1);
    
%     [eoer{T}(1,1),eoer{T}(1,2),eoer{T}(1,3),eoer{T}(1,8),eoer{T}(1,7)] = eval_dags_adjust({dag},bnet.dag,1);
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

