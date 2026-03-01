function [score, cache] = score_family_NewRecover(j, ps, node_type, ns, discrete, data, args, cache)
% SCORE_FAMILY Compute the score of a node and its parents using BIC.
% This version uses per-node caching for parent set scores to avoid global traversal.

if nargin < 9 || isempty(cache)
    n_nodes = size(data, 1); % infer number of nodes from data
    cache = cell(1, n_nodes);
    for k = 1:n_nodes
        cache{k} = struct('masks', [], 'scores', []);
    end
else
    n_nodes = length(cache);
end

% Convert data if needed
misv = -9999;
ccc = iscell(data);
if ccc
    data = bnt_to_mat(data, misv);
end

% Check cache first
ps = unique(ps);
[found, score] = check_cache(cache{j}, ps);
if found
    return;
end

% Build subgraph with only current node and its parents
[n, ncases] = size(data);
dag = zeros(n);
if ~isempty(ps)
    dag(ps, j) = 1;
    ps = sort(ps);
end

% Create Bayesian network structure
bnet = mk_bnet(dag, ns, 'discrete', discrete);
fname = sprintf('%s_CPD', node_type);
if isempty(args)
    bnet.CPD{j} = feval(fname, bnet, j);
else
    bnet.CPD{j} = feval(fname, bnet, j, args{:});
end

% Learn parameters and compute BIC score
fam = [ps j];
[tmp, available_case] = find(data(fam,:) == misv);
available_case = setdiff(1:ncases, available_case);

bnet.CPD{j} = learn_params(bnet.CPD{j}, fam, data(:, available_case), ns, bnet.cnodes);
L = log_prob_node(bnet.CPD{j}, data(j, available_case), data(ps, available_case));
S = struct(bnet.CPD{j}); % Get number of parameters
score = L - 0.5 * S.nparams * log(length(available_case));

% Update cache
cache{j} = add_to_cache(cache{j}, ps, score, n_nodes);

end
function [found, score] = check_cache(cj, ps)
% CHECK_CACHE 查找当前父集是否已存在缓存中
N = size(cj.masks, 2);
mask = false(1, N);
mask(ps) = true;

found = false;
score = 0;

for i = 1:size(cj.masks, 1)
    if isequal(cj.masks(i,:), mask)
        found = true;
        score = cj.scores(i);
        return;
    end
end

end
function cj_new = add_to_cache(cj, ps, score, n_nodes)
% ADD_TO_CACHE 将新的父集及其得分加入缓存
N = n_nodes;
mask = false(1, N);
mask(ps) = true;

cj.masks(end+1, :) = mask;
cj.scores(end+1) = score;

cj_new = cj;
end