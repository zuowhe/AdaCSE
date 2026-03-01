function [] = Remove_repeated(pop, N2)
    pop_zip = cell(1, 200);
    pop_edge_num = zeros(1, N2);
    
    % 第一步：压缩存储和计算每个pop{j}中1的数量
    for j = 1:N2
        [row, col] = find(pop{j} == 1);  % 找到1的位置
        num_ones = numel(row);  % 1的个数

        pop_zip(j) = {row, col};  % 注意这里改为使用元胞存储行和列信息
        pop_edge_num(j) = num_ones;
    end
    
    repeat_index = {};  % 存储重复项的索引
    
    % 第二步：查找重复项
    for j = 1:N2
        one_repeat = [];  % 初始化为数组，用于存储当前j对应的重复项的k值
        for k = 1:N2
            if j ~= k && pop_edge_num(j) == pop_edge_num(k) && isequal(pop_zip{j}, pop_zip{k})
                one_repeat = [one_repeat, k];  % 将找到的重复项k加入数组
            end
        end
        if ~isempty(one_repeat)  % 如果存在重复项，则将其添加到repeat_index
            repeat_index{end+1} = [j, one_repeat];  % 记录j以及与之重复的所有k
        end
    end
    
    % 此处可以对repeat_index进行进一步处理或输出
end