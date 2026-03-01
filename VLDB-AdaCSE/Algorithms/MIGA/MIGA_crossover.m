function [pop] = MIGA_crossover(N,pop,l_map_MI,conf,iter,Maxiter)
% For each individual: randomly choose its mate in the population, then generate the offspring
% 对每个个体：在种群中随机选择伴侣，然后产生后代
% 置信度选择：统计每一条边在种群中出现的次数，以此作为依据决定这条有争议的边被保留的概率

    l_cnt = size(l_map_MI,1);
    conf_per0 = 0.5;
    conf_per1 = 0.5;
    conf_per = conf_per0 - (conf_per0-conf_per1) * (iter/Maxiter);
    sum_per = 0.5;


    % 支持度参考值
    [~,~,conf_list] = find(conf);           % 所有边的支持度

    eps = 0.0000001;        % small positive number
    conf_max = max(conf_list);
    conf_range = conf_max - 0;
    norm_conf = conf/(eps+conf_range); % normalized score


    for p1=1:N
        p2 = p1;
        while p1==p2
            % 选择交叉对象
            p2 = randi(N);
        end
        pop{N+p1} = pop{p1};        % 后代编号 N+i

        for l=1:l_cnt
            n1 = l_map_MI(l,1);    n2 = l_map_MI(l,2);    l_MI = l_map_MI(l,3);
            % 上三角
            if pop{p1}(n1,n2) ~= pop{p2}(n1,n2)         % n1→n2
                p_cross = (1-conf_per) * l_MI + conf_per * norm_conf(n1,n2);
                p_cross = p_cross * sum_per + 0.5*(1-sum_per);
                if p_cross > rand
                    pop{N+p1}(n1,n2) = 1;
                else
                    pop{N+p1}(n1,n2) = 0;
                end
            end
            % 下三角
            if pop{p1}(n2,n1) ~= pop{p2}(n2,n1)         % n2→n1
                p_cross = (1-conf_per) * l_MI + conf_per * norm_conf(n2,n1);
                p_cross = p_cross * sum_per + 0.5*(1-sum_per);
                if p_cross > rand
                    pop{N+p1}(n2,n1) = 1;
                else
                    pop{N+p1}(n2,n1) = 0;
                end
            end
            % 防止出现冲突的边
            if pop{N+p1}(n1,n2) == 1 && pop{N+p1}(n2,n1) ==1
                R3 = randi(2);
                if R3 == 1
                    pop{N+p1}(n1,n2) = 0;
                else
                    pop{N+p1}(n2,n1) = 0;
                end
            end
        end
    end
end