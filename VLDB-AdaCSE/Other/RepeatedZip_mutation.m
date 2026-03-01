function [p] = RepeatedZip_mutation(N2,l_map,p,repeated_count1,iter_rate)
% Bit-flip mutation. In case of mutation, given starting allele randomly pick one of the others.
% 单点变异
node_size = size(p{1},1);
l_cnt = size(l_map,1);
repeated_rate = ceil(N2/sqrt(node_size)*iter_rate);
if repeated_count1 > repeated_rate
    m = (1+repeated_count1/N2)/l_cnt;            % mutation rate
else
    m = 1/l_cnt;
end
for L=1:l_cnt
    j = l_map(L,1);     k = l_map(L,2);
    for i=1:N2
        if m >= rand
            l_val_up = p{i}(j,k); l_val_low = p{i}(k,j); 
            l_val = l_val_up + l_val_low;              
            switch l_val
                case 0
                    random_number = randi([1, 2]);
                    switch random_number
                        case 1
                            p{i}(j,k)=false; p{i}(k,j)=true;
                        case 2
                            p{i}(j,k)=true; p{i}(k,j)=false;
                    end
                case 1
                    random_number = randi([1, 3]);
                    switch random_number
                        case 1
                            p{i}(j,k)=false; p{i}(k,j)=true;
                        case 2
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        case 3
                            p{i}(j,k)=false; p{i}(k,j)=false;
                    end
                case 2
                    p{i}(j,k)=false; p{i}(k,j)=false;
            end
        end
    end
end
end