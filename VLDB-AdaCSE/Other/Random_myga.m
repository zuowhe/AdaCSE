function [selected_data, execution_time] = Random_myga(data)
    % 记录函数开始时间
    tic;
    % 假设 data 是原始数据 (8 x 10000)，并已经转置为 (10000 x 8)
    data = data'; % 确保数据是 10000 x 8 的矩阵
% 
%     % 设置需要随机选择的样本数量
%     num_samples = 1000;
% 
%     % 获取数据的行数
%     num_rows = size(data, 1);
%     
%     % 生成一个正态分布的随机数列，均值为0，标准差为1
%     normal_dist = randn(num_rows, 1);
%     
%     % 按照正态分布的值排序，并选择前1000个最小/最大的索引（确保不重复）
%     [~, sorted_indices] = sort(normal_dist);
%     
%     % 选择前1000个索引
%     selected_indices = sorted_indices(1:num_samples);

    % 根据选出的索引提取数据
    selected_data = data(1:1000, :);
    selected_data = selected_data';
    
    % 输出选出的数据的尺寸
    disp('选出的数据尺寸:');
    disp(size(selected_data));
    
    % 记录函数结束时间并输出总运行时间
    execution_time = toc; % 获取运行时间并返回
    fprintf('随机函数运行时间: %.4f秒\n', execution_time); % 输出运行时间
end
