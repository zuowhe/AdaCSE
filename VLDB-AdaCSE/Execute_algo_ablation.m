function Execute_algo_ablation(Algorithm,DsS,N,M,MP,tour,Bnets,scoring_fn,trial)
    for j = 1:size(DsS,2)
        BN_Name = DsS{j}{1,1};         
        Ds_set = DsS{j}{1,2};          
        bnet = Bnets{j}{1,2};         
        sf = scoring_fn;               

        for i = 1:size(Ds_set,2)
            Ds = Ds_set(i);       
            switch Algorithm
                case   'SR-Fix',          Algo_SR_Fix(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf);                          
                case   'SR-Adapt',   Algo_SR_Adapt(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'SM-Fix',   Algo_SM_Fix(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'SM-Adapt',   Algo_SM_Adapt(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
                case   'DR-Adapt',   Algo_DR_Adapt(Ds,BN_Name,N,M,MP,tour,bnet,trial,sf); 
            end
            
            
        end
    end
end
