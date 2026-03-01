dbstop if error
addpath(genpath(pwd)); 

Datasets_dir = '[Datasets]/';
if ~exist(Datasets_dir,'dir')
    mkdir(Datasets_dir);
end

DsS = cell(0, 0); 
data_size = [500,1000,3000];

DsS{end+1} = {'Asia', data_size};
DsS{end+1} = {'INS', data_size}; 
DsS{end+1} = {'Water', data_size}; 
DsS{end+1} = {'Alarm', data_size}; 
DsS{end+1} = {'Hailfinder', data_size}; 
DsS{end+1} = {'HEPAR', data_size};  
DsS{end+1} = {'Win95pts', data_size}; 
DsS{end+1} = {'Pathfinder', data_size};   
DsS{end+1} = {'AND', data_size}; 

Train_Num = 10; 
FlagNewdata = false; 
Bnets = Generate_dataset(DsS, Train_Num, FlagNewdata); 

N    = 100; 
MP   = 7; 
tour = 2; 
M = 200;
scoring_fn = 'bic'; 

Algos = cell(0, 0); 
Algos{end+1} = 'SR-Fix';
Algos{end+1} = 'SR-Adapt';
Algos{end+1} = 'SM-Fix';
Algos{end+1} = 'SM-Adapt';
Algos{end+1} = 'DR-Adapt';

[~, AlogNums] = size(Algos);

for a = 1:AlogNums
    Execute_algo_ablation(Algos{1,a}, DsS, N, M, MP, tour, Bnets, scoring_fn, Train_Num);    
end