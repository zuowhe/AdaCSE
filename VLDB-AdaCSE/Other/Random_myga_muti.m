function [split_data, execution_time] = Random_myga_muti(data)
    % 记录函数开始时间
    tic;
    
    % 假设 data 是原始数据 (8 x 10000)，并已经转置为 (10000 x 8)
    data = data'; % 确保数据是 10000 x 8 的矩阵
    
    % 将数据平均分成10份
    num_parts = 10;
    shuffled_indices = randperm(size(data, 1)); % 随机打乱行索引
    part_size = size(data, 1) / num_parts; % 每一份的数据行数
    
    split_data = cell(num_parts, 1); % 用一个cell数组来存储分割后的数据
    
    for i = 1:num_parts
        % 提取每一份数据，并转置回 (8 x 1000)
        indices_for_this_part = shuffled_indices((i-1)*part_size + 1 : i*part_size);
        split_data{i} = data(indices_for_this_part, :)'; % 先选取再转置
    end

    % 输出每一份的数据尺寸
    disp('每一份数据的尺寸:');
    disp(size(split_data{1}));

    % 记录函数结束时间并输出总运行时间
    execution_time = toc; % 获取运行时间并返回
    fprintf('随机选择函数运行时间: %.4f秒\n', execution_time); % 输出运行时间
end