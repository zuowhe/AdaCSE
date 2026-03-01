    function [pop] = mutate_common_s_0(N,pop,es_common_s,l_map)
% 参考精英集的共同部分 es_common_s
% 对个体中不符合这一部分的边进行变异
common_lcnt = size(es_common_s,1);
l_cnt = size(l_map,1);
for i = 1:N
    edge_cnt = sum(sum(pop{i}));%对个体矩阵求和，求出这个个体有多少条边
    p_mu = 1/(edge_cnt - common_lcnt + 0.000000001);    % 变异概率：1/（个体的边数-精英结构的边数+0.000000001）
    for l = 1:l_cnt%骨架边
        % 第 l 条边 j-k
        j = l_map(l,1);
        k = l_map(l,2);
        if ~in_lmap(es_common_s,[j k]) %如果个体的骨架不在精英结构（考虑方向的有边极限）里
            % 当前个体中存在的边在共同结构中没有出现
            if p_mu >= rand
                l_val = get_allele(pop{i}(j,k),pop{i}(k,j));
                l_val_2 = mod(l_val + round(rand),3)+1;
                switch l_val_2
                    case 1
                        pop{i}(j,k)=false;  pop{i}(k,j)=false;
                    case 2
                        pop{i}(j,k)=false;  pop{i}(k,j)=true;
                    case 3
                        pop{i}(j,k)=true;   pop{i}(k,j)=false;
                end
            end
            % 变异部分完成
        end
    end
end
end



function [have_element] = in_lmap(lmap,pos)
% 确定 lmap 中是否存在边 pos : [j k]
have_element = false;
l_cnt = size(lmap,1);
for l=1:l_cnt
    if pos(1)==lmap(l,1) && pos(2)==lmap(l,2)
        have_element = true;
    end
end
end