function [score,pop_history, score_history,repeated_count1,length_history,cache] = Dag_repeat_score(data, N2, ns, pop, pop_history, score_history, length_history,scoring_fn, cache)
    score = zeros(1, N2);  
    repeated_count1 = 0;
    for j = 1:N2
        repeated = false;

        for k = 1:length_history
            if isequal(pop{j}, pop_history{k}) 
                score(j) = score_history(k); 
                repeated = true;
                repeated_count1 = repeated_count1 + 1;
                break;
            end
        end
        if ~repeated
            [individual_score, cache] = score_dags(data, ns, pop(j), 'scoring_fn', scoring_fn, 'cache', cache);
            score(j) = individual_score;

            length_history = length_history + 1;
            pop_history{length_history} = pop{j};
            score_history(length_history) = individual_score;
        end
    end
end

