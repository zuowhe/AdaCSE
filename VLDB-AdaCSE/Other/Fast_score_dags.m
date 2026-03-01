function [score, cache] = Fast_score_dags(data, ns, dags, varargin)
% SCORE_DAGS Compute the BIC score of one or more DAGs using a dynamically expanding cache.
%
% This version supports only 'bic' as scoring function and uses an auto-expanding
% cache (no overwrite). It calls score_family for each node in each DAG.

[n, ~] = size(data);

% Set default parameters
type = cell(1, n);
params = cell(1, n);
for i = 1:n
    type{i} = 'tabular';
    params{i} = {};
end

% scoring_fn = 'bic'; % Only BIC is supported now
discrete = 1:n;
cache = [];

% Parse optional arguments
args = varargin;
nargs = length(args);
for i = 1:2:nargs
    switch args{i}
        case 'type',       type = args{i+1};
        case 'discrete',   discrete = args{i+1};
        case 'params',     if isempty(args{i+1}), params = cell(1,n); else params = args{i+1}; end
        case 'cache',      cache = args{i+1};
    end
end

NG = length(dags);
score = zeros(1, NG);



% Loop over all DAGs
for g = 1:NG
    if isempty(dags{g})
        score(g) = -Inf;
        continue;
    end
    
    % Loop over all nodes
    for j = 1:n
        ps = parents(dags{g}, j); % Get parent set of node j in DAG g
%         [scor, cache] = score_family_norecover(j, ps, type{j}, scoring_fn, ns, discrete, data, params{j}, cache);
        [scor, cache] = Fast_score_family(j, ps, type{j}, ns, discrete, data, params{j}, cache);
        score(g) = score(g) + scor;
    end
end

end