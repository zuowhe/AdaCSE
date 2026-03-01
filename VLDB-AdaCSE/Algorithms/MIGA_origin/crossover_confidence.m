function [pop] = crossover_confidence(N,pop,l_map_MI,conf,iter,Maxiter)
% For each individual: randomly choose its mate in the population, then generate the offspring
% 对每个个体：在种群中随机选择伴侣，然后产生后代
% 置信度选择：统计每一条边在种群中出现的次数，以此作为依据决定这条有争议的边被保留的概率
l_cnt = size(l_map_MI,1);

% 0.5 - 0.5 基准
% 0.75-0.25 收敛变差
% 0.25-0.75 结果变好或差，收敛没变或前期变好后期变差
% 0.25--    结果变好，收敛略慢
% 0.75--    结果变差，收敛变慢
% 0.35-0.65 结果微好，收敛微差
% 0.25-0.5  结果变差，收敛后期变差
% 0.5 - 0.3 结果略差，收敛没变
conf_per0 = 0.5;
conf_per1 = 0.5;
conf_per = conf_per0 - (conf_per0-conf_per1) * (iter/Maxiter);
% sum_per = 1;

% p_cross 整体所占比例的调整
% 0.5   收敛变好
sum_per = 0.5;

% 在 Aisa 里效果很好，因为Asia的边占比比较大
% conf = conf / N;

% 支持度参考值
[~,~,conf_list] = find(conf);           % 所有边的支持度
% list_size = size(conf_list,1);          % 边的个数（同 2*l_cnt）
% conf_sum = sum(conf_list,'all');        % 和
% conf_mid = median(conf_list,'all');     % 中位数
% conf_avg = conf_sum / list_size;        % 平均数
% conf = conf / (2 * conf_avg);
% conf = conf / (1 * conf_avg);

eps = 0.0000001;        % small positive number
conf_min = min(conf_list);
conf_max = max(conf_list);
conf_range = conf_max - conf_min;
norm_conf = (conf-conf_min)/(eps+conf_range); % normalized score


for p1=1:N
    p2 = p1;
    while p1==p2
        % 选择交叉对象
        p2 = randi(N);
    end
    pop{N+p1} = pop{p1};        % 后代编号 N+i
    
    for l=1:l_cnt
        n1 = l_map_MI(l,1);    n2 = l_map_MI(l,2);    l_MI = l_map_MI(l,3);
        if pop{p1}(n1,n2) ~= pop{p2}(n1,n2)         % n1→n2
            p_cross = (1-conf_per) * l_MI + conf_per * norm_conf(n1,n2);
            p_cross = p_cross * sum_per + 0.5*(1-sum_per);
            if p_cross > rand
                pop{N+p1}(n1,n2) = 1;
            else
                pop{N+p1}(n1,n2) = 0;
            end
        end
    end
    
    for l=1:l_cnt
        n1 = l_map_MI(l,2);    n2 = l_map_MI(l,1);    l_MI = l_map_MI(l,3);
        if pop{N+p1}(n2,n1) == 0
            if pop{p1}(n1,n2) == pop{p2}(n1,n2)
                pop{N+p1}(n1,n2) = pop{p1}(n1,n2);
            else                                    % n1→n2
                p_cross = (1-conf_per) * l_MI + conf_per * norm_conf(n1,n2);
                p_cross = p_cross * sum_per + 0.5*(1-sum_per);
                if p_cross > rand
                    pop{N+p1}(n1,n2) = 1;
                else
                    pop{N+p1}(n1,n2) = 0;
                end
            end
        else
            pop{N+p1}(n1,n2) = 0;
        end
    end
    
    
    
    
%     % 原始交叉
%     for l=1:l_cnt
%         n1 = l_map_MI(l,1);    n2 = l_map_MI(l,2);
%         if round(rand)
%             pop{N+p1}(n1,n2) = pop{p1}(n1,n2);    pop{N+p1}(n2,n1) = pop{p1}(n2,n1);
%         else
%             pop{N+p1}(n1,n2) = pop{p2}(n1,n2);    pop{N+p1}(n2,n1) = pop{p2}(n2,n1);
%         end
%     end
    

    
%     % 在 Aisa 里效果很好，也许因为Asia的边占比比较大，也许是收敛很快
%     for l=1:l_cnt
%         e1 = l_map_MI(l,1);    e2 = l_map_MI(l,2);
%         p_cross = conf(e1,e2);
%         if (pop{p1}(e1,e2) ~= pop{p2}(e1,e2)) && (p_cross > rand)
%             pop{N+p1}(e1,e2) = 1;
%         end
%         p_cross = conf(e1,e2);
% 
%         p_cross = 0.3;
%         if score(p1) < score(p2)
%             p_cross = 0.7;
%         end
%         
%         if rand > p_cross
%             pop{N+p1}(e1,e2) = pop{p1}(e1,e2);    pop{N+p1}(e2,e1) = pop{p1}(e2,e1);
%         else
%             pop{N+p1}(e1,e2) = pop{p2}(e1,e2);    pop{N+p1}(e2,e1) = pop{p2}(e2,e1);
%         end
%     end
%     
%     % ↑处理上三角   ↓处理下三角
%     for l=1:l_cnt
%         e1 = l_map_MI(l,2);    e2 = l_map_MI(l,1);
%         if pop{N+p1}(e2,e1) == 0
%             p_cross = conf(e1,e2);
%             if (pop{p1}(e1,e2) ~= pop{p2}(e1,e2)) && (p_cross > rand)
%                 pop{N+p1}(e1,e2) = 1;
%             end
%         else
%             pop{N+p1}(e1,e2) = 0;
%         end
%     end


    
end
end