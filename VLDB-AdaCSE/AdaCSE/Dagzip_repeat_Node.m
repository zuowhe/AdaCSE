function [score, pop_history, score_history, number_edges, repeated_count1, length_history, flag_cache, cache, total_onec_overwrite, repeated_indices] = ...
    Dagzip_repeat_Node(data, N2, ns, pop, pop_history, score_history, number_edges, length_history, scoring_fn, flag_cache, cache, max_cache_size)

score = zeros(1, N2);
repeated_count1 = 0;
total_onec_overwrite = 0;
repeated_indices = [];  

if isempty(pop_history) || ~isa(pop_history, 'containers.Map')
    pop_history = containers.Map('KeyType', 'char', 'ValueType', 'any');
end

for j = 1:N2
    current_matrix = pop{j};
    [row, col] = find(current_matrix == 1);
    key = generate_unique_key([row, col]);

    if isKey(pop_history, key)
        score(j) = pop_history(key);
        repeated_count1 = repeated_count1 + 1;
        repeated_indices = [repeated_indices, j];  
    else

        dags = {current_matrix};
        [individual_score, cache, overwrite_count] = score_dags_NewRecover(...
            data, ns, dags, ...
            'scoring_fn', scoring_fn, ...
            'cache', cache, ...
            'max_cache_size', max_cache_size);

        score(j) = individual_score(1);
        total_onec_overwrite = total_onec_overwrite + overwrite_count;

        pop_history(key) = score(j);
        length_history = length_history + 1;
        number_edges(length_history) = length(row);
        score_history(length_history) = score(j);
    end
end

end


function key = generate_unique_key(edges)
if isempty(edges)
    key = 'empty';
    return;
end
sorted_edges = sortrows(edges);
key_parts = cell(size(sorted_edges, 1), 1);
for i = 1:size(sorted_edges, 1)
    key_parts{i} = sprintf('%d_%d', sorted_edges(i,1), sorted_edges(i,2));
end
key = strjoin(key_parts, '_');
end