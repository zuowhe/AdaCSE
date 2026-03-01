function [loop,is_dag] = get_loop(p)
% 将输入的 个体p 中 入度为0 / 出度为0 的点删掉
% 得到的 loop 即为 个体p 中 的环路，或者为空
% 返回的 is_dag 为logical值， 反应传入的 个体p 是否为 dag 


n = size(p,1);
loop = p;
change = true;

while change
    change = false;             % 个体没有发生改变的话跳出循环
    for i = 1:n
        if ~any(loop(i,:)) && any(loop(:,i))        %   点 i 的出度为 0, 入度不为 0
            loop(:,i) = 0;                          % 将点 i 从网络中去除
            change = true;
        end
        if ~any(loop(:,i)) && any(loop(i,:))        %   点 i 的入度为 0, 出度不为 0
            loop(i,:) = 0;                          % 将点 i 从网络中去除
            change = true;
        end
    end
end

if any(loop,'all')
    is_dag = false;
else
    is_dag = true;
end

end

