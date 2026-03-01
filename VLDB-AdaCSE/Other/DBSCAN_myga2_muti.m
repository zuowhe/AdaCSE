function [selected_data, execution_time] = DBSCAN_myga2_muti(data)
    % 记录函数开始时间
    tic;
    
    % 假设 data 是原始数据 (10000 x 8)
    data = data'; % 确保数据是 10000 x 8 的矩阵
    
    % 检查并处理缺失值
    data(any(isnan(data), 2), :) = []; % 删除包含 NaN 的行
    
    % 标准化数据
    mu = mean(data);
    sigma = std(data);
    data_z = (data - mu) ./ (sigma + eps); % 使用 eps 防止除零

    epsilon = 4.7;
    minPts = 3;  % 设置每个簇的最小点数
    
    num_samples = 1000; % 每个数据集的样本数
    fprintf('数据集选取的数据数量: %d\n',num_samples);
    num_datasets = 10;  % 数据集的数量
    all_selected_data = cell(num_datasets, 1); % 创建一个cell数组来存储每个数据集的选中数据
    
    % 使用 dbscan 函数
    [idx, ~] = dbscan(data_z, epsilon, minPts);

    % 统计每个聚类的样本数量
    unique_clusters = unique(idx); % 获取唯一的聚类编号
    [n1,~] = size(unique_clusters);
    fprintf('数据集聚类簇数: %d   ', n1);
    noise_points = data(idx == -1, :);
     
    % 首先选择所有噪声点
    [n2,~] = size(noise_points);
    fprintf('数据集的异常点数量: %d   ', n2);

    for dataset_idx = 1:num_datasets
        selected_data = []; % 用于存储选出的数据
        total_selected = 0; % 记录已经选择的样本数量
        
        if ~isempty(noise_points)
            selected_data = [selected_data; noise_points];
            total_selected = size(noise_points, 1);
        end
        
        % 如果噪声点的数量已经达到了1000个，直接返回
        if total_selected >= num_samples
            selected_data = selected_data(1:num_samples, :); % 确保最终数量为1000
        else
            % 计算还需要选择多少样本
            remaining_to_select = num_samples - total_selected;

            % 获取非噪声点的数据
            non_noise_data = data(idx ~= -1, :);

            % 对于每个聚类，按比例选择样本
            for i = 1:length(unique_clusters)
                cluster_id = unique_clusters(i);
                
                % 忽略噪声点
                if cluster_id ~= -1
                    % 获取当前聚类的所有点
                    cluster_points = non_noise_data(idx(idx ~= -1) == cluster_id, :);
                    cluster_size = size(cluster_points, 1); % 当前聚类的样本数量
                    
                    % 计算需要选择的样本数
                    proportion = cluster_size / length(non_noise_data); % 计算当前聚类的比例
                    num_to_select = round(proportion * remaining_to_select); % 计算要选择的样本数
                    
                    if total_selected + num_to_select <= num_samples
                        % 随机选择样本
                        selected_indices = randperm(cluster_size, min(num_to_select, cluster_size));
                        selected_data = [selected_data; cluster_points(selected_indices, :)]; % 添加到选中的数据集中
                        total_selected = total_selected + num_to_select;
                    else
                        % 如果加上当前簇的选择会超过1000，则只选择剩余需要的数量
                        num_to_select = remaining_to_select;
                        selected_indices = randperm(cluster_size, min(num_to_select, cluster_size));
                        selected_data = [selected_data; cluster_points(selected_indices, :)]; % 添加到选中的数据集中
                        total_selected = num_samples; % 达到目标数量
                        break; % 退出循环
                    end
                end
            end
        end

        % 确保最终的样本数量正好为1000
        if total_selected > num_samples
            % 如果超出了1000，则随机删除多余的样本
            extra_samples = total_selected - num_samples;
            indices_to_remove = randperm(total_selected, extra_samples);
            selected_data(indices_to_remove, :) = [];
            total_selected = num_samples;
        elseif total_selected < num_samples
            % 如果少于1000，则需要额外选择样本
            while total_selected < num_samples
                for i = 1:length(unique_clusters)
                    cluster_id = unique_clusters(i);
                    if cluster_id ~= -1
                        cluster_points = non_noise_data(idx(idx ~= -1) == cluster_id, :);
                        cluster_size = size(cluster_points, 1);
                        
                        if total_selected < num_samples
                            remaining_to_select = num_samples - total_selected;
                            num_to_select = min(remaining_to_select, cluster_size);
                            
                            selected_indices = randperm(cluster_size, num_to_select);
                            selected_data = [selected_data; cluster_points(selected_indices, :)];
                            total_selected = total_selected + num_to_select;
                        else
                            break;
                        end
                    end
                end
            end
        end

%         % 输出选中的数据的尺寸
%         [n3,~] = size(selected_data);
%         fprintf('数据集 %d 选取的数据数量: %d\n', dataset_idx, n3);
        
        % 将选中的数据存储到 cell 数组中
        all_selected_data{dataset_idx} = selected_data';
    end

    % 记录函数结束时间并输出总运行时间
    execution_time = toc; % 获取运行时间并返回
    fprintf('DBSCAN函数运行时间: %.4f秒\n', execution_time); % 输出运行时间

    % 输出每个数据集的选中数据
    selected_data = all_selected_data; % 返回每个数据集的选中数据
end
