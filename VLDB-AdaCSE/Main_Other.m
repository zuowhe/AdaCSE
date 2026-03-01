dbstop if error
addpath(genpath(pwd));         

%% ==================================
Datasets_dir = '[Datasets]/';
if ~exist(Datasets_dir,'dir')
	mkdir(Datasets_dir);
end

DsS = cell(0, 0);            

data_size = [500,1000,3000];
% % %============= Small ==================== 
DsS{end+1} = {'Asia', data_size};

% % % %============= Medium =================== 
DsS{end+1} = {'INS', data_size}; 
DsS{end+1} = {'Water', data_size}; 
DsS{end+1} = {'Alarm', data_size}; 

% % % ============= Large ==================== 
DsS{end+1} = {'Hailfinder', data_size}; 
DsS{end+1} = {'HEPAR', data_size}; 
DsS{end+1} = {'Win95pts', data_size}; 
% % % ============= Very Large ===============
DsS{end+1} = {'AND', data_size}; 

Train_Num = 10;                       
FlagNewdata = false;               
Bnets = Generate_dataset(DsS, Train_Num, FlagNewdata);  

%% ====================================================== 

N    = 100;                     % population size        
MP   = 7;                       % max parents/in-degree  
tour = 2;                       % tournament size        
M = 200;
scoring_fn = 'bic';             % scoring function for S&S phase  



Algos = cell(0, 0); 
Algos{end+1} = 'MIGA'; 
Algos{end+1} = 'EKGA_std';  
Algos{end+1} = 'AESL-GA';
Algos{end+1} = 'PSX';
Algos{end+1} = 'hybrid-SLA';  
Algos{end+1} = 'MAGA'; 
Algos{end+1} = 'CI-MAGA'; 


[~, AlogNums] = size(Algos);
for a = 1:AlogNums
    Execute_algo3(Algos{1,a},DsS,N,M,MP,tour,Bnets,scoring_fn,Train_Num);    
end










