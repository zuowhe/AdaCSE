function [es,e_score] = form_elite_set(alpha,N,p,norm_score)
% Constitute elite set with all individuals having a normalized score >= alpha.
i = 0;
es = cell(1,0);
e_score = [];
if alpha == 1
    alpha = 0.98;
end
for j=1:N
    if norm_score(j) >= alpha
        i = i+1;
        es{i} = p{j};
        e_score(i) = norm_score(j);
    end
end
end