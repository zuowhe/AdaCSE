function [score, cache] = he_score_family5(j, ps, node_type, scoring_fn, ns, discrete, data, args, cache)
% SCORE_FAMILY Compute the score of a node and its parents using BIC.

if nargin < 9 || isempty(cache)
    c = 0;
else
    c = 1;
end

ps = unique(ps);

if c == 1
    [found, score] = score_find_in_cache(cache, j, ps, scoring_fn);
else
    found = 0;
end

if ~found
    misv = -9999;
    ccc = iscell(data);
    if ccc
        data = bnt_to_mat(data, misv);
    end

    [n, ncases] = size(data);
    dag = zeros(n);
    if ~isempty(ps)
        dag(sort(ps), j) = 1;
    end

    bnet = mk_bnet(dag, ns, 'discrete', discrete);
    fname = sprintf('%s_CPD', node_type);
    bnet.CPD{j} = feval(fname, bnet, j, args{:});

    fam = [ps, j];
    available_case = 1:ncases;
    if ccc
        [~, tmp] = find(data(fam, :) == misv);
        available_case = setdiff(available_case, tmp);
    end

    bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
    L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
    S = struct(bnet.CPD{j}); % 获取参数数量
    score = L - 0.5 * S.nparams * log(length(available_case));

    if c == 1
        cache = score_add_to_cache(cache, j, ps, score, scoring_fn);
    end
end
function [cache, place] = score_add_to_cache(cache,j,ps,score,scoring_fn)
N=size(cache,2)-3;
L=size(cache,1)-1;
cache_full=cache(1,2);

place=0;

if ismember(j,ps) || j>N || j<=0
    return;
end

fn = (scoring_fn == 'bic'); % 1 for bic

if ~cache_full
    place = cache(1,1);
else
    [~, place] = max(rand(1,L)); 
    place = place + 1;
end

cache(place,:) = 0;
cache(place,ps) = 1;
cache(place,N+1) = j;
cache(place,N+2) = score;
cache(place,N+3) = fn;

cache(1,1) = place + 1;
if place > L || cache(1,2) ~= 0
    cache(1,2) = 1;
end
function [bool, score] = score_find_in_cache(cache,j,ps,scoring_fn)
L = size(cache,1)-1;
N = size(cache,2)-3;

if N < 1
    bool = false;
    score = 0;
    return
end

parents = zeros(1,N);
parents(ps) = 1;

fn = (scoring_fn == 'bic');
tmp = find(cache(2:L+1, N+3) == fn);
candidats = tmp + 1;
tmp2 = find(cache(candidats, N+1) == j);
candidats = candidats(tmp2);

i = 1;
while i <= N && ~isempty(candidats)
    tmp = find(cache(candidats,i) == parents(i));
    candidats = candidats(tmp);
    i = i + 1;
end

bool = ~isempty(candidats);
if bool
    score = cache(candidats(1), N+2);
else
    score = 0;
end