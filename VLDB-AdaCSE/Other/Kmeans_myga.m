function [selected_data, execution_time] = Kmeans_myga(data)
    % 记录函数开始时间
    tic;
    % 假设 data 是原始数据 (8 x 10000)，已转置为 (10000 x 8)
    data = data'; % 转置为 10000 x 8 的矩阵

    % 标准化数据，并保存均值和标准差
    mu = mean(data);
    sigma = std(data);
    data_z = (data - mu) ./ (sigma + eps); % 标准化 % eps 是一个非常小的数，避免除零

    % 设置 k 值
    k = 1000; % 设定为 10

    % 执行 k-means 聚类
    [idx, C] = kmeans(data_z, k, 'Replicates', 5);

    % 计算每个类的样本数量
    class_counts = histcounts(idx, 1:k+1); % 统计每个类的样本数量

    % 确定总共需要选出的列数
    total_samples = 1000;

    % 按比例选择每个类的样本数量
    samples_per_class = round((class_counts / sum(class_counts)) * total_samples);

    % 初始化选出的列索引
    selected_indices = [];

    % 从每个类中随机选择样本
    for i = 1:k
        % 找到当前类的所有列索引
        class_indices = find(idx == i);

        % 从中随机选择样本
        if ~isempty(class_indices)
            selected = randsample(class_indices, samples_per_class(i), false);
            selected_indices = [selected_indices; selected(:)]; % 添加选出的列索引
        end
    end

    % 按照选出的列索引从原始数据中提取对应的列
    selected_data = data(selected_indices, :); % 按行提取样本
    selected_data = selected_data'; 
    % 还原到原始值
    % selected_data_original = selected_data .* sigma' + mu'; % 还原

    % 输出选出的数据的尺寸
    disp('选出的数据尺寸:');
    disp(size(selected_data));
        
    % 记录函数结束时间并输出总运行时间
    execution_time = toc; % 获取运行时间并返回
    fprintf('DBSCAN函数运行时间: %.4f秒\n', execution_time); % 输出运行时间
end
