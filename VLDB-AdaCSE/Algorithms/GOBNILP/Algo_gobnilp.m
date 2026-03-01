function Algo_gobnilp(Ds,dataset,net,N,M,bnet,trial,scoring_fn,gen_new_data)
%% CausalExplorer MMHC
% eoer - End Of Execution Results 运行结果
% conv - Convergence Behavior structure 收敛行为结构

algo = ['GOBNILP'];

%% Init 初始化
fprintf('Running... %s_%s%s - N=%s M=%s [%s]\n',...
    algo,net,num2str(Ds),num2str(N),num2str(M),datestr(now));
fprintf('Iter   F1 Score  Sensitivity  Specificity   HD   Bayes Score     Exe Time  #Generations\n');

% options.threshold = 0.05;
% options.epc = 10;
% options.maxK = 10;
% options.use_card_lim = 0;
% options.max_card = 0;

% tol = 0.01;                         % CI test threshold for CB phase
eoer = cell(trial,1);               % End of Execution Results 计算结果
conv(1:trial) = struct('f1',zeros(1,M),'se',zeros(1,M),'sp',zeros(1,M),'sc',zeros(1,M));

str = sprintf('%s%s',dataset,num2str(Ds));
% data = acquire_data(str,Ds,trial,gen_new_data,bnet);    % 由数据集产生训练集
bnet.dag = logical(bnet.dag);   % double2boolean DAG conversion

format shortG

% 创建结果保存目录
date = [datestr(now,10),datestr(now,5),datestr(now,7)];
result_dir = ['[result]/',date];    
if ~exist(result_dir,'dir')
    mkdir(result_dir);
end
saves_filename_result = sprintf('[result]/%s/%s%s_%s_%s_%s.csv',...
    date,net,num2str(Ds),num2str(N),num2str(M),algo);
% saved_file = fopen(saves_filename_result,'a+');         % a+:文件若不存在，自动创建

target_file_path = sprintf('[result]/00_GOBNILP/%s/%s',dataset,str);

% 创建收敛行为保存目录 D:\WorkSpace\Ykf_bnet_study\[result]\00_GOBNILP\Alarm\Alarm1000
% convergence_dir = ['[result]/',date,'/Convergence_Behavior'];
% if ~exist(convergence_dir,'dir')
%     mkdir(convergence_dir);
% end

%% MMHC
for T = 1:trial

%     saves_result_file = sprintf('[result]/%s/Convergence_Behavior/%s%s_%s_%s_%s-%s.csv',...
%         date,net,num2str(Ds),num2str(N),num2str(M),algo,num2str(T,'%02d'));
    eoer{T} = -1*ones(1,8);
%     tStart = tic;                                                           % tic
    
    terget_file = sprintf('%s/%d.csv',target_file_path,T);

    dag = csvread(terget_file);

%     [eoer{T}(1,4)] = score_dags(trian_data,bnet.node_sizes,{dag},'scoring_fn',scoring_fn,'cache',cache);
    
    % 整理结果
%     eoer{T}(1,5) = toc(tStart);                                             % toc

    eoer{T}(1,7) = get_HD(dag,bnet.dag);        % HD
    [eoer{T}(1,1),eoer{T}(1,2),eoer{T}(1,3)] = eval_dags({dag},bnet.dag,1);
    
%     [eoer{T}(1,1),eoer{T}(1,2),eoer{T}(1,3),eoer{T}(1,8),eoer{T}(1,7)] = eval_dags_adjust({dag},bnet.dag,1);
    
    fprintf('%4d  %9.5f    %9.5f    %9.5f  %3.1f   %11.3f  %11.3f      %4d\n',...
        T,eoer{T}(1),eoer{T}(2),eoer{T}(3),eoer{T}(7),eoer{T}(4),eoer{T}(5),eoer{T}(6));
    
    saved_file = fopen(saves_filename_result,'a+');         % a+:文件若不存在，自动创建
    if saved_file<0
        errordlg('File creation failed','Error');
    end
    fprintf(saved_file,'%4d,%9.5f,%9.5f,%9.5f,%9.5f,%3.1f,%11.3f,%11.3f,%4d\n',...
        T,eoer{T}(1),eoer{T}(2),eoer{T}(3),eoer{T}(8),eoer{T}(7),eoer{T}(4),eoer{T}(5),eoer{T}(6));

    
end

%% End of Execution Results
[eoer_avg, eoer_std] = avg_std(eoer,trial);
print_avg_std(eoer_avg,eoer_std);
fprintf(saved_file,'Avg,%9.5f,%9.5f,%9.5f,%9.5f,%5.3f,%11.3f,%11.3f,%7.3f\n',...
        eoer_avg(1),eoer_avg(2),eoer_avg(3),eoer_avg(8),eoer_avg(7),eoer_avg(4),eoer_avg(5),eoer_avg(6));
fprintf(saved_file,'Std,%9.5f,%9.5f,%9.5f,%9.5f,%5.3f,%11.3f,%11.3f,%7.3f\n',...
        eoer_std(1),eoer_std(2),eoer_std(3),eoer_avg(8),eoer_std(7),eoer_std(4),eoer_std(5),eoer_std(6));
fclose(saved_file);

end
