%% 选择算法来执行实验
function Execute_algo2(Algorithm,DsS,N,M,MP,tour,Bnets,scoring_fn,trial)
    for j = 1:size(DsS,2)
        BN_Name = DsS{j}{1,1};         % 获取BN名称
        Ds_set = DsS{j}{1,2};          % 获取该BN生成训练集的不同规模
        bnet = Bnets{j}{1,2};          % 获取当前BN的全部信息
        sf = scoring_fn;               % 获取评分指标

        for i = 1:size(Ds_set,2)
            Ds = Ds_set(i);       % DS为当前训练集的大小
%             这个位置定义两个cell，后续分别存储每次循环的[onedata_avg_result, onedata_std_result]，然后将这两个cell写入csv文件，文件命名中包含Algorithm
            switch Algorithm
                case   'MIGA_AdaptCI',  Algo_adaptMIGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'hybrid_SLA_AdaptCI',   Algo_hybrid_SLA_AdaptCI(Ds,BN_Name,N,M,MP,bnet,trial,sf); 
                    
                    
%                 case 'std_score',    get_std_score(Ds,BN_Name,bnet,trial,sf);                                   % 标准网络得分
            end
            
            
        end
    end
end
