%% =====================================算法及BNSL算法库导入
dbstop if error
addpath(genpath(pwd));          % 搜索子目录的子程序
% addpath(genpath('\bnt-master\')); % 导入路径BN学习的函数库

%% ======================================数据集生成
% 生成保存数据集的文件夹
Datasets_dir = '[Datasets]/';
if ~exist(Datasets_dir,'dir')
	mkdir(Datasets_dir);
end
% 后续使用一个多维的cell元组，用来记录实验涉及网络的名称，以及生成数据集的大小
% Dss{网络名称1，包含多个数据集大小的数组1；网络名称2，包含多个数据规模的数组2；}
DsS = cell(0, 0);            



% % % ===========网络名称==生成的数据集大小     
data_size = [500,1000,3000];
% data_size = [10000];
% % %============= Small ==================== 
% DsS{end+1} = {'Asia', data_size};
% DsS{end+1} = {'Sachs', data_size}; 

% % % %============= Medium =================== 
% DsS{end+1} = {'INS', data_size}; 
% DsS{end+1} = {'Water', data_size}; 
% DsS{end+1} = {'Alarm', data_size}; 

% % % ============= Large ==================== 
% DsS{end+1} = {'Hailfinder', data_size}; 
% DsS{end+1} = {'HEPAR', data_size}; 
DsS{end+1} = {'Win95pts', data_size}; 
% % % ============= Very Large ===============
% DsS{end+1} = {'AND', data_size}; 
% DsS{end+1} = {'Pathfinder', data_size}; 
% % % =======在多个算法上容易报错的几个网络======
% DsS{end+1} = {'Cancer', data_size}; 
% DsS{end+1} = {'Earthquake', data_size}; 
% DsS{end+1} = {'Survey', data_size}; 
% DsS{end+1} = {'Barley', data_size}; 
% DsS{end+1} = {'Mildew', data_size}; 

Train_Num = 10;                          % 训练次数
FlagNewdata = false;                    % FlagNewdata 使用true或false用于控制是否生成数据集
Bnets = Generate_dataset(DsS, Train_Num, FlagNewdata);  % 调用函数生成数据集，返回值Bnets为网络结构体集

%% ====================================================== 算法调用
% 算法的主要参数
N    = 100;                     % population size        种群大小
MP   = 7;                       % max parents/in-degree  最大父集 max 7
tour = 2;                       % tournament size        锦标赛规模
M = 200;
scoring_fn = 'bic';             % scoring function for S&S phase  评分函数


% 调用的算法名称
Algos = cell(0, 0); 
% Algos{end+1} = 'EKGA_AdaptCI';
Algos{end+1} = 'hybrid_SLA_AdaptCI';

   

% Edge_statistics(DsS,Bnets,Train_Num);
% % 调用算法函数
[~, AlogNums] = size(Algos);
for a = 1:AlogNums
    Execute_algo2(Algos{1,a},DsS,N,M,MP,tour,Bnets,scoring_fn,Train_Num);    
end










