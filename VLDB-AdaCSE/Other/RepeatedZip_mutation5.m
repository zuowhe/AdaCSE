function [p] = RepeatedZip_mutation5(l_map,p,all_repeats)
%     node_size = size(p{1},1);
    l_cnt = size(l_map,1);
%     repeated_rate = ceil(N2/sqrt(node_size)*iter_rate);
    nrep = size(all_repeats,2);
    m = 1/l_cnt;
%     m = nrep/l_cnt*(1-iter_rate);
    for L=1:l_cnt
        j = l_map(L,1);     k = l_map(L,2);
        for I=1:nrep
            i = all_repeats(I);
            if m >= rand
                l_val_up = p{i}(j,k); l_val_low = p{i}(k,j);
                if l_val_up
                    if rand > l_map(L,3)
                        p{i}(j,k)=false; p{i}(k,j)=true;
                    else
                        p{i}(j,k)=false; p{i}(k,j)=false;
                    end
                else
                    if l_val_low
                        if rand > l_map(L,3)
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        else
                            p{i}(j,k)=false; p{i}(k,j)=false;
                        end
                    else
                        if rand < l_map(L,3)
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        else
                            p{i}(j,k)=false; p{i}(k,j)=false;
                        end
                    end
                end
            end
        end
    end
end