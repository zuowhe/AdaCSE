function [repeat_indices, all_repeats] = Find_repeated_arrays(pop)
    N = length(pop);  
    repeat_indices = {};  
    all_repeats = [];  

    for j = 1:N
        if isnan(pop{j}) 
            continue;
        end
        
      
        same_indices = j;  
        for k = j+1:N
            if isequal(pop{j}, pop{k})
                same_indices = [same_indices, k];  
                pop{k} = NaN; 
            end
        end

        if length(same_indices) > 1
            repeat_indices{end+1} = same_indices; 
            all_repeats = [all_repeats, same_indices(2:end)]; 
        end
    end
end