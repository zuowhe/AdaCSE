function [pop, now_repeats_indices] = handle_repeated_individuals(pop, pop_history, g_best, iter, max_iter, enable_logging)
if nargin < 6, enable_logging = true; end

repeats_info = struct();

%% 1. Detect repeated individuals in the current generation
[~, now_repeats_indices] = Find_repeated_arrays(pop);
now_repeats_indices = now_repeats_indices(:)';  % Ensure it is a row vector
repeats_info.total_current = length(now_repeats_indices);

%% 2. Check if current repeated individuals appeared in the historical population
common_repeated_indices = [];

% Skip if no current repeats or the historical population is empty
if isempty(now_repeats_indices) || isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    common_repeated_indices = [];
else
    for idx = now_repeats_indices
        key = get_dag_key(pop{idx});  % Generate key only for repeated individuals
        if isKey(pop_history, key)
            common_repeated_indices(end + 1) = idx;
        end
    end
end

repeats_info.common_count = length(common_repeated_indices);

%% 3. Adaptively replace dual-repeated individuals
repeats_info.replaced_count = 0;
repeats_info.indices = [];

if ~isempty(common_repeated_indices)
    % Adaptive replacement ratio: increases linearly from 0 to 50%
    replace_ratio = 0.5 * (iter - 1) / (max_iter - 1);
    num_to_replace = max(1, round(length(common_repeated_indices) * replace_ratio));

    % Randomly select individuals to be replaced by the historical best
    selected_idx = common_repeated_indices(randperm(length(common_repeated_indices), num_to_replace));

    % Execute replacement
    for k = 1:length(selected_idx)
        pop(selected_idx(k)) = {g_best};
    end

    repeats_info.replaced_count = length(selected_idx);
    repeats_info.indices = selected_idx;
end

end