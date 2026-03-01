function [pop] = del_loop_MI_naive(pop,MI,MP)
% 删除种群中每个个体的环路 using MI
% 

N = size(pop,2);            % 种群个体数
n = size(pop{1},1);         % 网络大小

for i = 1:N
%     pop{i}(logical(eye(n))) = false;                    % 指向自己的边直接删掉
    [loop,is_dag] = get_loop(pop{i});

    while ~is_dag
        [e0,e1] = find(loop);               % 边的合集：e0 → e1 边起点序列，边终点序列
        loop_size = size(e0,1);             % 环路有几条边
        edge_MI = zeros(loop_size,1);       % 初始化边的序列
        for j = 1:loop_size
            edge_MI(j) = MI(e0(j),e1(j));                   % 得到每条边对应的 MI 值
        end
        [edge_MI,index] = sort(edge_MI);                    % 得到升序的 MI 值序列及编号
        % e0(index(i)) 表示在序列中的第i条边的起点
        
        
        % 思路1：删除 MI 最小的边，边的序列存在e0，e1中
        % ==========================================
        ii = e0(index(1));     jj = e1(index(1));           % 直接删除 MI 值最小的边，坐标存在第 index(1) 位
        pop{i}(ii,jj) = false;
        
        % 思路2：检查 MI 最小的边的 MI 值，根据值来决定怎么做
        % ================================================
        % 思路3：根据 MI 值将环路中的边分组，小的一组随机删除，大的一组随机反转
        % =================================================================

        
        [loop,is_dag] = get_loop(pop{i});               % 再次检查有没有环
    end
    
    %% Constrain Max Fan-in to MP
    pop{i} = naive_limit_parents(MP,pop{i});
end

end
