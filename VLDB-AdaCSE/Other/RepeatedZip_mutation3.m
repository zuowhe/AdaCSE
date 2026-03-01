function [p] = RepeatedZip_mutation3(N2,l_map,p,repeated_count1,iter_rate,all_repeats)
%     node_size = size(p{1},1);
    l_cnt = size(l_map,1);
%     repeated_rate = ceil(N2/sqrt(node_size)*iter_rate);
    nrep = size(all_repeats,2);
    m = nrep/l_cnt;
%     m = nrep/l_cnt*(1-iter_rate);
    for L=1:l_cnt
        j = l_map(L,1);     k = l_map(L,2);
        for I=1:nrep            
            i = all_repeats(I);
            l_val = get_allele(p{i}(j,k),p{i}(k,j));     
            if m >= rand
                l_val_new = mod(l_val + round(rand),3)+1;   % randomly pick one of remaining alleles
                switch l_val_new
                    case 1
                        p{i}(j,k)=false; p{i}(k,j)=false;
                    case 2
                        p{i}(j,k)=false; p{i}(k,j)=true;
                    case 3
                        p{i}(j,k)=true; p{i}(k,j)=false;
                end
            end
        end
    end
end