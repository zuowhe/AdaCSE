function Execute_algo3(Algorithm,DsS,N,M,MP,tour,Bnets,scoring_fn,trial)
    for j = 1:size(DsS,2)
        BN_Name = DsS{j}{1,1};      
        Ds_set = DsS{j}{1,2};          
        bnet = Bnets{j}{1,2};          
        sf = scoring_fn;              
        for i = 1:size(Ds_set,2)
            Ds = Ds_set(i);      
            switch Algorithm
                case 'MIGA',         Algo_MIGA_NoRecover(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                       
                case 'EKGA_std',     Algo_EKGA_std(Ds,BN_Name,N,M,MP,bnet,trial,sf);                          
                case 'AESL-GA',      Algo_aesl_ga(Ds,BN_Name,N,M,MP,bnet,trial,sf);                           
                case 'PSX',          Algo_psx(Ds,BN_Name,N,M,MP,bnet,trial,sf);                         
                case 'hybrid-SLA',   Algo_hybrid_SLA(Ds,BN_Name,N,M,MP,bnet,trial,sf);              
                case 'MAGA',         Algo_MAGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);              
                case 'CI-MAGA',         Algo_CIMAGA(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                   
            end
            
            
        end
    end
end
