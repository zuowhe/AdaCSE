function [pop] = uniform_crossover(N,pop,l_map)
% For each individual: randomly choose its mate in the population, then generate the offspring 
% by randomly picking the edge state for each locus from one of the parent individuals.
l_cnt = size(l_map,1);
for p1=1:N
    p2 = p1;
    while p1==p2
        p2 = randi(N);
    end                             % 选择交叉对象
    pop{N+p1} = pop{p1};                  % 后代编号 N+i
    for l=1:l_cnt
        n1 = l_map(l,1);    n2 = l_map(l,2);
        if round(rand)
            pop{N+p1}(n1,n2) = pop{p1}(n1,n2);    pop{N+p1}(n2,n1) = pop{p1}(n2,n1);
        else
            pop{N+p1}(n1,n2) = pop{p2}(n1,n2);    pop{N+p1}(n2,n1) = pop{p2}(n2,n1);
        end
    end
end
end