function [p] = Points_mutation4_MI(N,l_map,p)
% Bit-flip mutation. In case of mutation, given starting allele randomly pick one of the others.
% 单点变异
l_cnt = size(l_map,1);
m = 1/l_cnt;            % mutation rate
    for L=1:l_cnt
        j = l_map(L,1);     k = l_map(L,2);
        for i=1:N
            if m >= rand
                l_val_up = p{i}(j,k); l_val_low = p{i}(k,j);
                if l_val_up
                    if rand < l_map(L,3)
                        p{i}(j,k)=false; p{i}(k,j)=true;
                    else
                        p{i}(j,k)=false; p{i}(k,j)=false;
                    end
                else
                    if l_val_low
                        if rand < l_map(L,3)
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        else
                            p{i}(j,k)=false; p{i}(k,j)=false;
                        end
                    else
                        if rand > 0.5
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        else
                            p{i}(j,k)=false; p{i}(k,j)=true;
                        end
                    end
                end
            end
        end
    end
end