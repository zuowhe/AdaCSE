function [pop, now_repeats_indices] = handle_repeated_individuals(pop, pop_history, g_best, iter, max_iter, enable_logging)
% HANDLE_REPEATED_INDIVIDUALS
%   检测并处理双重重复个体：既在当代重复，又在历史中出现
%   采用高效策略：先找当代重复个体，再仅对这些个体查询历史缓存
%
% 输入：
%   pop: 当前种群 (cell array of DAG matrices)
%   pop_history: containers.Map, 历史 DAG 评分缓存
%   g_best: 全局最优 DAG (N x N)
%   iter: 当前迭代次数
%   max_iter: 最大迭代次数
%   enable_logging: 是否打印日志
%
% 输出：
%   pop: 更新后的种群（部分个体被替换为 g_best）
%   repeats_info: 结构体，包含重复统计信息
%       .total_current        - 当代内重复个体数
%       .common_count         - 历史+当代双重重复数
%       .replaced_count       - 实际被替换的数量
%       .indices              - 被替换的索引
%       .non_repeated_indices - 非重复个体的索引（全新个体）
% 默认开启日志
if nargin < 6, enable_logging = true; end

repeats_info = struct();

%% 1. 检测当代重复个体
[~, now_repeats_indices] = Find_repeated_arrays(pop);
now_repeats_indices = now_repeats_indices(:)';  % 确保为行向量
repeats_info.total_current = length(now_repeats_indices);

%% 2. 只对当代重复个体检查是否在历史中出现
common_repeated_indices = [];

% 若无当代重复，或历史为空，则跳过
if isempty(now_repeats_indices) || isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    common_repeated_indices = [];
else
    for idx = now_repeats_indices
        key = get_dag_key(pop{idx});  % 仅对重复个体生成 key
        if isKey(pop_history, key)
            common_repeated_indices(end + 1) = idx;
        end
    end
end

repeats_info.common_count = length(common_repeated_indices);

%% 3. 自适应替换双重重复个体
repeats_info.replaced_count = 0;
repeats_info.indices = [];

if ~isempty(common_repeated_indices)
    % 自适应替换比例：从 0 到 50%
    replace_ratio = 0.5 * (iter - 1) / (max_iter - 1);
    num_to_replace = max(1, round(length(common_repeated_indices) * replace_ratio));

    % 随机选择要替换的个体
    selected_idx = common_repeated_indices(randperm(length(common_repeated_indices), num_to_replace));

    % 执行替换
    for k = 1:length(selected_idx)
        pop(selected_idx(k)) = {g_best};
    end

    repeats_info.replaced_count = length(selected_idx);
    repeats_info.indices = selected_idx;
end

%% 4. 条件性日志输出
if enable_logging
    log_iterations = [10, 50, 100, 190];
    if ismember(iter, log_iterations)
        fprintf('第 %d 次迭代，当代重复个体数: %d; ', iter, repeats_info.total_current);
    end
end

end