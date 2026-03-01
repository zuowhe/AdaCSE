function [p] = MMGA_mutation(N,l_map,p,i,M)
% Dif_BIC为当代种群最优个体和历史最优个体BIC评分的差值
% M为总的迭代次数，i为当前的迭代次数
% l_map里面是节点间MI的值
% N是种群大小
% p是当前种群
l_cnt = size(l_map,1);
m = 1/l_cnt;
c = i/M;
for l=1:l_cnt
    j = l_map(l,1);     k = l_map(l,2);
    for i=1:N
        l_val = get_allele(p{i}(j,k),p{i}(k,j));        %获取边缘分布
        if m >= rand
            switch l_val
                case 1
                    if l_map(l,3)>0.05
                        if rand>0.5
                            p{i}(j,k)=false; p{i}(k,j)=true;
                        else
                            p{i}(j,k)=true; p{i}(k,j)=false;
                        end
                    end
                case 2  
                    if l_map(l,3)<0.95
                        if rand<c
                            if l_map(l,3)>rand
                                p{i}(j,k)=true; p{i}(k,j)=false;
                            else
                                p{i}(j,k)=false; p{i}(k,j)=false;
                            end
                        else
                            if l_map(l,3)<rand
                                p{i}(j,k)=true; p{i}(k,j)=false;
                            else
                                p{i}(j,k)=false; p{i}(k,j)=false;
                            end
                        end
                    end
                case 3  
                    if l_map(l,3)<0.95
                        if rand<c
                            if l_map(l,3)>rand
                                p{i}(j,k)=false; p{i}(k,j)=true;  
                            else
                                p{i}(j,k)=false; p{i}(k,j)=false;  
                            end
                        else
                            if l_map(l,3)<rand
                                p{i}(j,k)=false; p{i}(k,j)=true;  
                            else
                                p{i}(j,k)=false; p{i}(k,j)=false;  
                            end
                        end
                    end
            end
        end
    end
end
end

