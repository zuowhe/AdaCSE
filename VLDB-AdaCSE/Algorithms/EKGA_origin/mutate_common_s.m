function [pop] = mutate_common_s(N,pop,es_common_s,l_map)
% 参考精英集的共同部分 es_common_s
% 对个体中不符合这一部分的边进行变异
common_lcnt = size(es_common_s,1);
l_cnt = size(l_map,1);
for i = 1:N
    edge_cnt = sum(sum(pop{i}));
    p_mu = 1/(edge_cnt - common_lcnt + 0.000000001);    % 变异概率
    for l = 1:l_cnt
        % 第 l 条边 j-k
        j = l_map(l,1);
        k = l_map(l,2);
        if ~in_lmap(es_common_s,[j k]) && (pop{i}(j,k)==1 || pop{i}(k,j)==1)
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