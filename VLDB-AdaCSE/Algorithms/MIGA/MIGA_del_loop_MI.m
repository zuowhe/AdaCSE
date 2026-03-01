function [pop] = MIGA_del_loop_MI(pop,MI,MP)
% 根据MI删除种群中每个个体的环路

N = size(pop,2);            % 种群个体数
n = size(pop{1},1);         % 网络大小

for i = 1:N
    [loop,is_dag] = get_loop(pop{i});
    while ~is_dag
        [e0,e1] = find(loop);               % 边的合集：e0 → e1 边起点序列，边终点序列
        loop_size = size(e0,1);             % 环路有几条边
        edge_MI = zeros(loop_size,1);       % 初始化边的序列
        for j = 1:loop_size
            edge_MI(j) = MI(e0(j),e1(j));                   % 得到每条边对应的 MI 值
        end
        [~,index] = sort(edge_MI);                    % 得到升序的 MI 值序列及编号
        % e0(index(i)) 表示在序列中的第i条边的起点
        % 删除 MI 最小的边，边的序列存在e0，e1中
        ii = e0(index(1));     jj = e1(index(1));           % 直接删除 MI 值最小的边，坐标存在第 index(1) 位
        pop{i}(ii,jj) = false;
        % 再次检查有没有环
        [loop,is_dag] = get_loop(pop{i});               
    end
    %% 最简单的父节点数量限制策略
    pop{i} = naive_limit_parents(MP,pop{i});
end
end
