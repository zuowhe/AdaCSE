function results = run_real_te_downstream_ranking(method_dag_file, intervention_nodes, intervention_state)
%RUN_REAL_TE_DOWNSTREAM_RANKING Rank downstream affected nodes on TE data.
%
% Defaults:
%   intervention_nodes = {'X1', 'X22'}
%   intervention_state = 3

if nargin < 1 || isempty(method_dag_file), method_dag_file = ''; end
if nargin < 2 || isempty(intervention_nodes), intervention_nodes = {'X1', 'X22'}; end
if nargin < 3 || isempty(intervention_state), intervention_state = 3; end

experiment_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(experiment_dir));
addpath(genpath(project_root));
addpath(fullfile(project_root, 'bnt-master', 'graph'), '-begin');

prepared = load(fullfile(experiment_dir, 'Data', 'te_real_discrete.mat'));
node_names = prepared.node_names;
node_sizes = prepared.node_sizes;
true_dag = logical(prepared.true_dag);

data = load_te_trial_data(method_dag_file, prepared);
method_dags = load_method_dags(method_dag_file, true_dag);
reference_bnet = fit_discrete_bnet(true_dag, node_sizes, data);

results = struct([]);
detail_rows = struct([]);
summary_rows = struct([]);
detail_count = 0;
summary_count = 0;

for q = 1:numel(intervention_nodes)
    intervention_name = intervention_nodes{q};
    intervention_id = resolve_node_id(intervention_name, node_names);
    fprintf('\nIntervention: do(%s = %s)\n', intervention_name, state_name(intervention_state));

    reference_effects = compute_downstream_effects(reference_bnet, intervention_id, intervention_state, node_names);
    reference_order = rank_effects(reference_effects, intervention_id);
    reference_rank = make_rank_vector(reference_order, numel(node_names));

    results(q).intervention = intervention_name; %#ok<AGROW>
    results(q).reference = reference_effects; %#ok<AGROW>
    results(q).methods = struct([]); %#ok<AGROW>

    for m = 1:numel(method_dags)
        method_name = method_dags(m).name;
        dag = logical(method_dags(m).dag);
        fitted_bnet = fit_discrete_bnet(dag, node_sizes, data);
        method_effects = compute_downstream_effects(fitted_bnet, intervention_id, intervention_state, node_names);
        method_order = rank_effects(method_effects, intervention_id);
        method_rank = make_rank_vector(method_order, numel(node_names));
        metrics = ranking_metrics(method_effects, reference_effects, intervention_id);
        descendants = graph_descendants(dag, intervention_id);

        results(q).methods(m).name = method_name; %#ok<AGROW>
        results(q).methods(m).effects = method_effects; %#ok<AGROW>
        results(q).methods(m).metrics = metrics; %#ok<AGROW>

        fprintf('  %-14s Spearman=%6.3f Kendall=%6.3f nDCG@5=%6.3f  Top: %s\n', ...
            method_name, metrics.spearman, metrics.kendall, metrics.ndcg_at_5, ...
            format_top_nodes(method_order, method_effects, node_names, 5));

        summary_count = summary_count + 1;
        summary_rows(summary_count).Intervention = intervention_name; %#ok<AGROW>
        summary_rows(summary_count).Method = method_name; %#ok<AGROW>
        summary_rows(summary_count).Spearman = metrics.spearman; %#ok<AGROW>
        summary_rows(summary_count).Kendall = metrics.kendall; %#ok<AGROW>
        summary_rows(summary_count).NDCG_at_5 = metrics.ndcg_at_5; %#ok<AGROW>
        summary_rows(summary_count).Top5 = format_top_nodes(method_order, method_effects, node_names, 5); %#ok<AGROW>

        for r = 1:numel(method_order)
            node_id = method_order(r);
            detail_count = detail_count + 1;
            detail_rows(detail_count).Intervention = intervention_name; %#ok<AGROW>
            detail_rows(detail_count).Method = method_name; %#ok<AGROW>
            detail_rows(detail_count).Rank = r; %#ok<AGROW>
            detail_rows(detail_count).Node = node_names{node_id}; %#ok<AGROW>
            detail_rows(detail_count).NodeId = node_id; %#ok<AGROW>
            detail_rows(detail_count).EffectTVD = method_effects(node_id).tvd; %#ok<AGROW>
            detail_rows(detail_count).EffectMeanShift = method_effects(node_id).mean_shift; %#ok<AGROW>
            detail_rows(detail_count).ReferenceRank = reference_rank(node_id); %#ok<AGROW>
            detail_rows(detail_count).ReferenceEffectTVD = reference_effects(node_id).tvd; %#ok<AGROW>
            detail_rows(detail_count).MethodRank = method_rank(node_id); %#ok<AGROW>
            detail_rows(detail_count).IsDescendantInMethod = descendants(node_id); %#ok<AGROW>
            detail_rows(detail_count).Spearman = metrics.spearman; %#ok<AGROW>
            detail_rows(detail_count).Kendall = metrics.kendall; %#ok<AGROW>
            detail_rows(detail_count).NDCG_at_5 = metrics.ndcg_at_5; %#ok<AGROW>
        end
    end
end

output_dir = fullfile(project_root, '[result]', datestr(now, 'yyyymmdd'), 'TE_Real_Downstream_Ranking');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end
stamp = datestr(now, 'yyyymmdd_HHMMSS');
detail_file = fullfile(output_dir, ['real_te_downstream_ranking_' stamp '.csv']);
summary_file = fullfile(output_dir, ['real_te_downstream_summary_' stamp '.csv']);
writetable(struct2table(detail_rows), detail_file);
writetable(struct2table(summary_rows), summary_file);

for q = 1:numel(results)
    results(q).detail_file = detail_file;
    results(q).summary_file = summary_file;
end

fprintf('\nSaved detail ranking: %s\n', detail_file);
fprintf('Saved summary:        %s\n', summary_file);
end

function data = load_te_trial_data(method_dag_file, prepared)
if nargin >= 1 && ~isempty(method_dag_file) && exist(method_dag_file, 'file')
    loaded_dag_file = load(method_dag_file, 'data');
    if isfield(loaded_dag_file, 'data')
        data = double(loaded_dag_file.data);
        return;
    end
end
data = double(prepared.discrete_data);
end

function method_dags = load_method_dags(method_dag_file, true_dag)
if nargin < 1 || isempty(method_dag_file)
    method_dags = struct('name', 'GroundTruth', 'dag', logical(true_dag));
    return;
end
loaded = load(method_dag_file);
if isfield(loaded, 'method_dags')
    method_dags = loaded.method_dags;
elseif isfield(loaded, 'dags') && isfield(loaded, 'method_names')
    dags = loaded.dags;
    method_names = loaded.method_names;
    for i = 1:numel(dags)
        method_dags(i).name = method_names{i}; %#ok<AGROW>
        method_dags(i).dag = dags{i}; %#ok<AGROW>
    end
elseif isfield(loaded, 'dag')
    method_dags = struct('name', 'LearnedDAG', 'dag', loaded.dag);
else
    error('Unsupported method DAG file. Expected method_dags, dags+method_names, or dag.');
end
end

function node_id = resolve_node_id(name, node_names)
node_id = find(strcmpi(node_names, name), 1);
if isempty(node_id)
    error('Unknown TE node: %s', name);
end
end

function bnet = fit_discrete_bnet(dag, node_sizes, data)
n = numel(node_sizes);
bnet = mk_bnet(logical(dag), node_sizes, 'discrete', 1:n);
for i = 1:n
    bnet.CPD{i} = tabular_CPD(bnet, i, 'prior_type', 'dirichlet', 'dirichlet_weight', 1);
end
bnet = learn_params(bnet, data);
end

function effects = compute_downstream_effects(bnet, intervention_id, intervention_state, node_names)
baseline = infer_marginals(bnet);
intervened_bnet = apply_do_intervention(bnet, intervention_id, intervention_state);
intervened = infer_marginals(intervened_bnet);
for i = 1:numel(node_names)
    effects(i).node = node_names{i}; %#ok<AGROW>
    effects(i).node_id = i; %#ok<AGROW>
    effects(i).tvd = total_variation_distance(baseline{i}, intervened{i}); %#ok<AGROW>
    effects(i).mean_shift = abs(expected_state(intervened{i}) - expected_state(baseline{i})); %#ok<AGROW>
end
effects(intervention_id).tvd = NaN;
effects(intervention_id).mean_shift = NaN;
end

function marginals = infer_marginals(bnet)
n = numel(bnet.node_sizes);
engine = jtree_inf_engine(bnet);
engine = enter_evidence(engine, cell(1, n));
marginals = cell(1, n);
for i = 1:n
    marginal = marginal_nodes(engine, i);
    probs = marginal.T(:)';
    probs = probs ./ sum(probs);
    marginals{i} = probs;
end
end

function bnet_do = apply_do_intervention(bnet, intervention_id, intervention_state)
bnet_do = bnet;
bnet_do.dag(:, intervention_id) = 0;
bnet_do.parents{intervention_id} = [];
bnet_do.CPD{intervention_id} = root_CPD(bnet_do, intervention_id, intervention_state);
end

function order = rank_effects(effects, intervention_id)
scores = [effects.tvd];
scores(intervention_id) = -Inf;
[~, order] = sort(scores, 'descend');
order = order(isfinite(scores(order)));
end

function rank_vector = make_rank_vector(order, node_count)
rank_vector = nan(1, node_count);
for i = 1:numel(order)
    rank_vector(order(i)) = i;
end
end

function metrics = ranking_metrics(method_effects, reference_effects, intervention_id)
method_scores = [method_effects.tvd];
reference_scores = [reference_effects.tvd];
mask = true(size(method_scores));
mask(intervention_id) = false;
method_scores = method_scores(mask);
reference_scores = reference_scores(mask);
metrics.spearman = corr(method_scores(:), reference_scores(:), 'Type', 'Spearman', 'Rows', 'complete');
metrics.kendall = corr(method_scores(:), reference_scores(:), 'Type', 'Kendall', 'Rows', 'complete');
metrics.ndcg_at_5 = ndcg_at_k(method_scores, reference_scores, 5);
end

function value = ndcg_at_k(scores, reference_scores, k)
[~, order] = sort(scores, 'descend');
[~, ideal_order] = sort(reference_scores, 'descend');
k = min(k, numel(scores));
gains = reference_scores(order(1:k));
ideal_gains = reference_scores(ideal_order(1:k));
discount = log2((1:k) + 1);
dcg = sum(gains(:)' ./ discount);
idcg = sum(ideal_gains(:)' ./ discount);
if idcg <= 0
    value = 0;
else
    value = dcg / idcg;
end
end

function descendants = graph_descendants(dag, node_id)
n = size(dag, 1);
visited = false(1, n);
queue = node_id;
while ~isempty(queue)
    current = queue(1);
    queue(1) = [];
    children = find(dag(current, :));
    for c = children
        if ~visited(c)
            visited(c) = true;
            queue(end + 1) = c; %#ok<AGROW>
        end
    end
end
descendants = visited;
end

function text = format_top_nodes(order, effects, node_names, k)
k = min(k, numel(order));
parts = cell(1, k);
for i = 1:k
    node_id = order(i);
    parts{i} = sprintf('%s(%.4f)', node_names{node_id}, effects(node_id).tvd);
end
text = strjoin(parts, ', ');
end

function cp = total_variation_distance(p, q)
cp = 0.5 * sum(abs(p(:) - q(:)));
end

function e = expected_state(p)
states = 1:numel(p);
e = sum(states(:) .* p(:));
end

function cpd = root_CPD(bnet, node_id, intervention_state)
probs = zeros(1, bnet.node_sizes(node_id));
probs(intervention_state) = 1;
cpd = tabular_CPD(bnet, node_id, probs);
end

function label = state_name(state_id)
names = {'LOW', 'AVG', 'HIGH'};
label = names{state_id};
end
