function [pop] = Random_crossover(N,pop,l_map_MI)
    l_cnt = size(l_map_MI,1);

    for p1=1:N
        p2 = p1;
        while p1==p2
            % 选择交叉对象
            p2 = randi(N);
        end
        pop{N+p1} = pop{p1};        % 后代编号 N+i

        for l=1:l_cnt
            n1 = l_map_MI(l,1);    n2 = l_map_MI(l,2);
            % 上三角
            if pop{p1}(n1,n2) ~= pop{p2}(n1,n2)         % n1→n2
                if 0.5 > rand
                    pop{N+p1}(n1,n2) = 1;
                else
                    pop{N+p1}(n1,n2) = 0;
                end
            end
            % 下三角
            if pop{p1}(n2,n1) ~= pop{p2}(n2,n1)         % n2→n1
                if 0.5 > rand
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