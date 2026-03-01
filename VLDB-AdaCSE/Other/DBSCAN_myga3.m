function [selected_data] = DBSCAN_myga2(data)
    % 假设 data 是原始数据 (10000 x 8)
    data = data'; % 确保数据是 10000 x 8 的矩阵
    
    % 检查并处理缺失值
    data(any(isnan(data), 2), :) = []; % 删除包含 NaN 的行
    
    % 标准化数据
    mu = mean(data);
    sigma = std(data);
    data_z = (data - mu) ./ (sigma + eps); % 使用 eps 防止除零
    
    % 根据数据维度动态设置邻域半径
    dim = size(data_z, 2);  % 获取数据的维度（列数）
%     
    % 使用 k-NN 来计算每个点的距离
%     k = 10*dim -1; % 可以调整 k 的值来控制邻域半径的灵敏度
%     dist = pdist2(data_z, data_z); % 计算数据点之间的距离
%     sorted_dist = sort(dist, 2); % 对每个点按距离排序
    % 计算每个点到其 k 个最近邻的距离
%     epsilon_values = sorted_dist(:, k+1); % 获取第 k+1 个距离作为每个点的 epsilon
    
    %选择 epsilon 的平均值或某个统计量作为全局的邻域半径
%     e = mean(epsilon_values);
%     fprintf('每个点的第k个近邻的平均距离为: %d   ',e);
%     epsilon = e/2 + dim*0.08; % 使用平均距离作为 epsilon 值
     epsilon = 3;
    minPts = 3;  % 设置每个簇的最小点数
    
    % 使用 dbscan 函数
    [idx, ~] = dbscan(data_z, epsilon, minPts);
    
    % 统计每个聚类的样本数量
    unique_clusters = unique(idx); % 获取唯一的聚类编号
    [n1,~] = size(unique_clusters);
    fprintf('数据的聚类簇数: %d   ',n1);
    
    num_samples = 1000; % 设置总样本数
    selected_data = []; % 用于存储选出的数据
    % 对于每个聚类，按比例选择样本
    total_selected = 0; % 记录已经选择的样本数量
    selected_data = []; % 用于存储选出的数据
    
    % 首先选择所有噪声点
    noise_points = data(idx == -1, :);
    [n2,~] = size(noise_points);
    fprintf('异常点数量: %d   ',n2);
    
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
                
                % 如果还没有达到总样本数，继续选择
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
    
    selected_data = selected_data';
    % 输出选中的数据的尺寸
    [~,n3] = size(selected_data);
    fprintf('选取的数据数量: %d\n',n3);
end
