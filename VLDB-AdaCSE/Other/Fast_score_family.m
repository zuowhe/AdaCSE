function [score, cache] = score_family(j, ps, node_type, ns, discrete, data, args, cache)
% SCORE_FAMILY_BIC_ONLY Compute the BIC score of a node and its parents given completely observed data
% score = score_family(j, ps, node_type, ns, discrete, data, args, cache)
%
% Optimized for BIC scoring only.
% Removed support for 'bicmod' and 'bayesian' to improve performance.

c = ~isempty(cache);
ps = unique(ps);

% Check cache
if c
    [found, score] = score_find_in_cache(cache, j, ps);
    if found
        return;
    end
end

misv = -9999; % Missing value marker
ccc = iscell(data);
if ccc
    data = bnt_to_mat(data, misv);
end

[n, ncases] = size(data);
fam = [ps, j];
dag = zeros(n);
if ~isempty(ps)
    dag(sort(ps), j) = 1;
end

% Build BN structure
bnet = mk_bnet(dag, ns, 'discrete', discrete);
fname = sprintf('%s_CPD', node_type);
if isempty(args)
    bnet.CPD{j} = feval(fname, bnet, j);
else
    bnet.CPD{j} = feval(fname, bnet, j, args{:});
end

% Determine available cases
if ccc
    [~, unavailable] = find(data(fam, :) == misv);
    available_case = setdiff(1:ncases, unavailable);
else
    available_case = 1:ncases;
end

% Learn parameters and compute log probability
bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
logprob = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
params = struct(bnet.CPD{j});  % Get parameter count

% BIC score
score = logprob - 0.5 * params.nparams * log(length(available_case));

% Update cache
if c
    cache = score_add_to_cache(cache, j, ps, score);
end

end
function [found, score] = score_find_in_cache(cache, j, ps)
N = size(cache,2) - 3;
L = size(cache,1) - 1;

if N < 1
    found = false;
    score = 0;
    return;
end

parents = zeros(1, N);
parents(ps) = 1;

tmp = find(cache(2:L+1, N+3) == 1);  % Only look for BIC entries (fn=1)
tmp = tmp + 1;
tmp2 = find(cache(tmp, N+1) == j);
candidats = tmp(tmp2);

i = 1;
while i <= N && ~isempty(candidats)
    tmp = find(cache(candidats, i) == parents(i));
    candidats = candidats(tmp);
    i = i + 1;
end

found = ~isempty(candidats);
if found
    score = cache(candidats(1), N+2);
else
    score = 0;
end
end
function cache = score_add_to_cache(cache, j, ps, score)
N = size(cache,2) - 3;
L = size(cache,1) - 1;

cache_full = cache(1,2);
place = 0;

if ismember(j, ps) || j > N || j <= 0
    return;
end

% Find place
if ~cache_full
    place = cache(1,1);
else
    [~, place] = max(rand(1, L)); place = place + 1;
end

% Clear old entry and write new one
cache(place,:) = 0;
cache(place, ps) = 1;
cache(place, N+1) = j;
cache(place, N+2) = score;
cache(place, N+3) = 1;  % BIC = 1

% Update cache header
cache(1,1) = place + 1;
if place > L || cache(1,2) ~= 0
    cache(1,2) = 1;
end

end