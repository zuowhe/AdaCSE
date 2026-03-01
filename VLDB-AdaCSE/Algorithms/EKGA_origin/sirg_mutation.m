function [pop] = sirg_mutation(N,l_map,pop,score,pwm)
% Compute a distinct mutation rate for each site of every individual dag 
% and possibly perform mutation on that specific site.
% 每个位点：利用不同的突变率进行突变操作
% pwm: 位置权重矩阵
l_cnt = size(l_map,1);
a = 0.01;    % small positive value

for i=1:N
    for l=1:l_cnt
        j = l_map(l,1);
        k = l_map(l,2);
        
        % 获取网络的边缘分布
        l_val = get_allele(pop{i}(j,k), pop{i}(k,j));
        
        % 变异概率 p
        p = ( a + (1-a)*(1-score(i)) )*( a + (1-a)*(1-pwm(l,l_val)) );
        
        if p >= rand
            % 随机选取等位基因（变异）
            l_val_new = mod(l_val+round(rand),3) +1; 
            switch l_val_new
                case 1
                    pop{i}(j,k)=false; pop{i}(k,j)=false;
                case 2
                    pop{i}(j,k)=false; pop{i}(k,j)=true;
                case 3
                    pop{i}(j,k)=true;  pop{i}(k,j)=false;
            end
        end
    end
end



end