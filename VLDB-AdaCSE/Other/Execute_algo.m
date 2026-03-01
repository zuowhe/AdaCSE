%% 选择算法来执行实验
function Execute_algo(Algorithm,DsS,N,M,MP,tour,Bnets,scoring_fn,trial)
    for j = 1:size(DsS,2)
        BN_Name = DsS{j}{1,1};         % 获取BN名称
        Ds_set = DsS{j}{1,2};          % 获取该BN生成训练集的不同规模
        bnet = Bnets{j}{1,2};          % 获取当前BN的全部信息
        sf = scoring_fn;               % 获取评分指标

        for i = 1:size(Ds_set,2)
            Ds = Ds_set(i);       % DS为当前训练集的大小
%             这个位置定义两个cell，后续分别存储每次循环的[onedata_avg_result, onedata_std_result]，然后将这两个cell写入csv文件，文件命名中包含Algorithm
            switch Algorithm
                case 'MIGA',         Algo_MIGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % MIGA(与理论一致)
                case 'MIGA_NoBIC',         Algo_MIGA_NoBIC(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                       
                case 'PA_MIGA',         Algo_PA_MIGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                        % MIGA(多次实验的并行版本)
                case 'MIGA_origin',  Algo_ga_confcross_v1(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                % MIGA（颜师兄的实际版本）
                case 'EKGA-BN',      Algo_EKGA(Ds,BN_Name,N,M,MP,bnet,trial,sf);                                % EKGA-BN（实际EKGN-BN）
                case 'EKGA_std',     Algo_EKGA_std(Ds,BN_Name,N,M,MP,bnet,trial,sf);                            % 理论EKGN-BN
                case 'AESL-GA',      Algo_aesl_ga(Ds,BN_Name,N,M,MP,bnet,trial,sf);                             % AESL-GA,已改评估
                case 'PSX',          Algo_psx(Ds,BN_Name,N,M,MP,bnet,trial,sf);                         % PSX,已改评估
                case 'hybrid-SLA',   Algo_hybrid_SLA(Ds,BN_Name,N,M,MP,bnet,trial,sf);                % hybrid-SLA,已改评估
                case 'MMHC',         Algo_MMHC(Ds,BN_Name,N,M,bnet,trial);                           % MMHC,已改评估
                case 'Inter-IAMB',   Algo_interIAMB(Ds,BN_Name,N,M,bnet,trial);                      % Iner-IAMB,已改评估
                case 'GOBNILP',      Algo_gobnilp(Ds,BN_Name,N,M,bnet,trial,sf);                        % GOBNILP
                case 'SaiyanH',      Algo_saiyanh(Ds,BN_Name,N,M,bnet,trial,sf);                        % SaiyanH
                case 'std_GA',       Algo_std_GA(Ds,BN_Name,N,M,MP,bnet,trial,sf);                      % std_GA
                case 'MYGA',         Algo_MYGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % 多段式
                case 'MYGA2',         Algo_MIGA2(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % MIGA(与理论一致)
                case 'MIGA_ReBIC',         Algo_MIGA_ReBIC(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case 'MIGA_NoRecover',     Algo_MIGA_NoRecover(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                     
                case 'MIGA_NewBIC',     Algo_MIGA_NewBIC(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case 'MIGA_OnlyBIC',    Algo_MIGA_OnlyBIC(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case 'MMGA_origin',   Algo_MMGA_origin(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case    'std_score',  Algo_std_score();
                % 下面为对比实验
                case   'MYGA_Random_X',   Algo_MIGA2_origin(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'MYGA_Once_mutation',   Algo_Once_mutation(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'MYGA_OnceMuta_AdaptCI',   Algo_OnceMuta_AdaptCI(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'MYGA_RandomX_AdaptCI',   Algo_OnceMuta_AdaptCI(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case 'Adapt_MIGA',    Algo_adaptMIGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                    
                case 'MAGA',         Algo_MAGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % MAGA
                case 'CI-MAGA',         Algo_CIMAGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % CI测试+MAGA    
                 case 'CI-MAGA-oldbic',         Algo_CIMAGA_oldbic(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                           % CI测试+MAGA   
                    
                
                    
%                 case 'std_score',    get_std_score(Ds,BN_Name,bnet,trial,sf);                                   % 标准网络得分
            end
            
            
        end
    end
end
