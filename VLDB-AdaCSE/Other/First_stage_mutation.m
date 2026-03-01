function [p,m1] = First_stage_mutation(N,l_map,p,Dif_BIC,M,i)
% Dif_BIC为当代种群最优个体和历史最优个体BIC评分的差值
% M为总的迭代次数，i为当前的迭代次数
% l_map里面是节点间MI的值
% N是种群大小
% p是当前种群
l_cnt = size(l_map,1);
% beta = (i+M)/2*M;
beta = (M-i)/M;
m1 = calculateMutationRateLog(l_cnt, Dif_BIC, beta);
for l=1:l_cnt
    j = l_map(l,1);     k = l_map(l,2);
    for i=1:N
        l_val = get_allele(p{i}(j,k),p{i}(k,j));        %获取边缘分布
        if m1 >= rand
            switch l_val
                case 1
                    if rand>0.5
                        p{i}(j,k)=false; p{i}(k,j)=true;
                    else
                        p{i}(j,k)=true; p{i}(k,j)=false;
                    end
                case 2  
                    if l_map(l,3)>rand
                        p{i}(j,k)=true; p{i}(k,j)=false;
                    else
                        p{i}(j,k)=false; p{i}(k,j)=false;
                    end
                case 3  
                    if l_map(l,3)>rand
                        p{i}(j,k)=false; p{i}(k,j)=true;  
                    else
                        p{i}(j,k)=false; p{i}(k,j)=false;  
                    end
            end
        end
    end
end
end
function mutation_rate = calculateMutationRateLog(n, Dif_BIC, beta)
    % n: 超结构的边数
    % beta: 影响变异率调整幅度的常数
%% 变异方式1，范围0-2
%     计算变异率，使用对数变换
    gamma = 1 / (1 + exp(Dif_BIC));
    if isinf(gamma) || isnan(gamma)
        % disp('Warning: exp(-BIC) resulted in NaN or Inf');
        gamma = 0;  % 使用一个合理的默认值来避免数值不稳定
    end
    mutation_rate = (1 / n) * (gamma+beta);
    
%% 变异方式2，范围0-2  
%     if Dif_BIC < 0
%         gamma = 1/(1+ exp(Dif_BIC));
%     else
%         gamma = 0;
%     end
%     mutation_rate = (1 / n) * (2*gamma);
end