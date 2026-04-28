function [all_results, summary_file] = run_real_te_comparison_experiment(trial_count, population_size, max_generations, max_parents, methods, raw_input_file, dag_input_file, state_count)
%RUN_REAL_TE_COMPARISON_EXPERIMENT Run multiple evolutionary methods on TE data.
%
% The same prepared TE dataset is reused across trials. Different trial IDs
% correspond to repeated stochastic runs on the same discretized data.

if nargin < 1 || isempty(trial_count), trial_count = 10; end
if nargin < 2 || isempty(population_size), population_size = 100; end
if nargin < 3 || isempty(max_generations), max_generations = 200; end
if nargin < 4 || isempty(max_parents), max_parents = 7; end
if nargin < 5 || isempty(methods)
    methods = {'AdaCSE', 'PSX', 'EKGA-std', 'AESL-GA', 'hybrid-SLA', 'MIGA', 'MAGA'};
end
if nargin < 6, raw_input_file = ''; end
if nargin < 7, dag_input_file = ''; end
if nargin < 8 || isempty(state_count), state_count = 3; end

experiment_dir = fileparts(mfilename('fullpath'));
project_root = fileparts(fileparts(experiment_dir));
addpath(genpath(project_root));

prepare_real_te_data(raw_input_file, dag_input_file, state_count);
loaded = load(fullfile(experiment_dir, 'Data', 'te_real_discrete.mat'));
data = double(loaded.discrete_data);
node_names = loaded.node_names;
node_sizes = loaded.node_sizes;
true_dag = logical(loaded.true_dag);
data_size = size(data, 2);
bnet = mk_bnet(false(numel(node_names)), node_sizes);

output_root = fullfile(project_root, '[result]', datestr(now, 'yyyymmdd'), 'TE_Real_Application_Batch');
dag_output_dir = fullfile(output_root, 'learned_dags');
if ~exist(dag_output_dir, 'dir'), mkdir(dag_output_dir); end

all_results = struct([]);
row_count = 0;

fprintf('Real TE comparison experiment: Nobs=%d, nodes=%d, trials=%d, N=%d, M=%d, MP=%d.\n', ...
    data_size, numel(node_names), trial_count, population_size, max_generations, max_parents);
fprintf('Methods: %s\n', strjoin(methods, ', '));

for trial_id = 1:trial_count
    fprintf('\n=== Real TE Trial %02d/%02d ===\n', trial_id, trial_count);
    method_dags = run_methods_for_trial(methods, data, bnet, true_dag, population_size, max_generations, max_parents, dag_output_dir, trial_id);
    dag_file = fullfile(dag_output_dir, sprintf('real_te_method_dags_trial%02d.mat', trial_id));
    save(dag_file, 'method_dags', 'data', 'data_size', 'trial_id', 'population_size', ...
        'max_generations', 'max_parents', 'methods', 'node_names', 'node_sizes', 'true_dag');

    for m = 1:numel(method_dags)
        row_count = row_count + 1;
        all_results(row_count).DataSize = data_size;
        all_results(row_count).NodeCount = numel(node_names);
        all_results(row_count).Trial = trial_id;
        all_results(row_count).Method = method_dags(m).name;
        all_results(row_count).F1 = method_dags(m).f1;
        all_results(row_count).Sensitivity = method_dags(m).sensitivity;
        all_results(row_count).Specificity = method_dags(m).specificity;
        all_results(row_count).Precision = method_dags(m).precision;
        all_results(row_count).SHD = method_dags(m).shd;
        all_results(row_count).ReversedEdges = method_dags(m).reversed_edges;
        all_results(row_count).Score = method_dags(m).score;
        all_results(row_count).Iterations = method_dags(m).iterations;
        all_results(row_count).EdgeCount = method_dags(m).edge_count;
    end
end

structure_file = fullfile(output_root, 'real_te_structure_metrics_all_trials.csv');
summary_file = fullfile(output_root, 'real_te_structure_metrics_mean_std.csv');
writetable(struct2table(all_results), structure_file);
write_mean_std_summary(all_results, summary_file);

fprintf('\nSaved structure metrics: %s\n', structure_file);
fprintf('Saved mean/std summary:  %s\n', summary_file);
end

function method_dags = run_methods_for_trial(methods, data, bnet, true_dag, N, M, MP, output_dir, trial_id)
method_dags = result_template();
method_dags = method_dags([]);
scoring_fn = 'bic';
tour = 2;
for i = 1:numel(methods)
    method = methods{i};
    method_dir = fullfile(output_dir, sprintf('RealTE_trial%02d', trial_id));
    if ~exist(method_dir, 'dir'), mkdir(method_dir); end
    switch upper(strrep(method, '-', '_'))
        case 'ADACSE'
            result = run_adacse(data, bnet, true_dag, N, M, MP, tour, scoring_fn, method_dir);
        case 'PSX'
            result = run_psx(data, bnet, true_dag, N, M, MP, scoring_fn, method_dir);
        case 'EKGA_BN'
            result = run_ekga(data, bnet, true_dag, N, M, MP, scoring_fn, method_dir, 'EKGA-BN');
        case 'EKGA_STD'
            result = run_ekga(data, bnet, true_dag, N, M, MP, scoring_fn, method_dir, 'EKGA-std');
        case 'AESL_GA'
            result = run_aesl(data, bnet, true_dag, N, M, MP, scoring_fn, method_dir);
        case 'HYBRID_SLA'
            result = run_hybrid_sla(data, bnet, true_dag, N, M, MP, scoring_fn, method_dir);
        case 'MIGA'
            result = run_miga(data, bnet, true_dag, N, M, MP, tour, scoring_fn, method_dir);
        case {'MAGA', 'MAGABN'}
            result = run_maga(data, bnet, true_dag, N, M, MP, tour, scoring_fn, method_dir);
        otherwise
            error('Unsupported TE method: %s', method);
    end
    method_dags(end + 1) = result; %#ok<AGROW>
end
end

function result = run_adacse(data, bnet, true_dag, N, M, MP, tour, scoring_fn, output_dir)
fprintf('Running AdaCSE...\n');
p_value = compute_pairwise_ci_pvalues(data, bnet, 0.01);
saved_filename = fullfile(output_dir, 'AdaCSE_convergence.csv');
[dag_cell, score, ~, iterations] = AdaCSE_evolution(data, N, M, MP, scoring_fn, bnet, tour, saved_filename, p_value, AdaCSE_options('AdaCSE'));
result = make_method_result('AdaCSE', dag_cell, score, iterations, true_dag);
end

function result = run_psx(data, bnet, true_dag, N, M, MP, scoring_fn, output_dir)
fprintf('Running PSX...\n');
superstructure = get_CI_test(data, bnet, 0.01);
saved_filename = fullfile(output_dir, 'PSX_convergence.csv');
[dag_cell, score, ~, iterations] = ga_psx(superstructure, data, N, M, MP, scoring_fn, bnet, saved_filename);
result = make_method_result('PSX', dag_cell, score, iterations, true_dag);
end

function result = run_ekga(data, bnet, true_dag, N, M, MP, scoring_fn, output_dir, variant)
fprintf('Running %s...\n', variant);
superstructure = get_CI_test(data, bnet, 0.01);
elite_gate = 0.5;
diversity = struct('m0', 1/5, 'M0', 3/5, 'm1', 1/10, 'M1', 1/2);
tour = 4;
tour_limit = N * 2 / 5;
saved_filename = fullfile(output_dir, [strrep(variant, '-', '_') '_convergence.csv']);
switch variant
    case 'EKGA-BN'
        [dag_cell, score, ~, iterations] = ekga_bn(superstructure, data, N, M, MP, elite_gate, diversity, scoring_fn, bnet, tour, tour_limit, saved_filename);
    case 'EKGA-std'
        [dag_cell, score, ~, iterations] = ekga_bn2(superstructure, data, N, M, MP, elite_gate, diversity, scoring_fn, bnet, tour, tour_limit, saved_filename);
    otherwise
        error('Unsupported EKGA variant: %s', variant);
end
result = make_method_result(variant, dag_cell, score, iterations, true_dag);
end

function result = run_aesl(data, bnet, true_dag, N, M, MP, scoring_fn, output_dir)
fprintf('Running AESL-GA...\n');
superstructure = get_CI_test(data, bnet, 0.01);
alpha = 0.9;
diversity = struct('m0', 1/5, 'M0', 3/5, 'm1', 1/10, 'M1', 1/2);
saved_filename = fullfile(output_dir, 'AESL_GA_convergence.csv');
[dag_cell, score, ~, iterations] = aesl_ga(superstructure, data, N, M, MP, alpha, diversity, scoring_fn, bnet, saved_filename);
result = make_method_result('AESL-GA', dag_cell, score, iterations, true_dag);
end

function result = run_hybrid_sla(data, bnet, true_dag, N, M, MP, scoring_fn, output_dir)
fprintf('Running hybrid-SLA...\n');
superstructure = get_CI_test(data, bnet, 0.01);
saved_filename = fullfile(output_dir, 'hybrid_SLA_convergence.csv');
[dag_cell, score, ~, iterations] = hybrid_sla_ga(superstructure, data, N, M, MP, scoring_fn, bnet, saved_filename);
result = make_method_result('hybrid-SLA', dag_cell, score, iterations, true_dag);
end

function result = run_miga(data, bnet, true_dag, N, M, MP, tour, scoring_fn, output_dir)
fprintf('Running MIGA...\n');
superstructure = get_CI_test(data, bnet, 0.01);
saved_filename = fullfile(output_dir, 'MIGA_convergence.csv');
[dag_cell, score, ~, iterations] = MIGA_ga_process(superstructure, data, N, M, MP, scoring_fn, bnet, tour, saved_filename);
result = make_method_result('MIGA', dag_cell, score, iterations, true_dag);
end

function result = run_maga(data, bnet, true_dag, N, M, MP, tour, scoring_fn, output_dir)
fprintf('Running MAGA...\n');
superstructure = get_CI_test(data, bnet, 0.01);
saved_filename = fullfile(output_dir, 'MAGA_convergence.csv');
[dag_cell, score, ~, iterations] = MAGA_OnlyBIC_process(superstructure, data, N, M, MP, scoring_fn, bnet, tour, saved_filename);
result = make_method_result('MAGA', dag_cell, score, iterations, true_dag);
end

function result = make_method_result(name, dag_cell, score, iterations, true_dag)
dag = normalize_dag_output(dag_cell, size(true_dag, 1));
[f1, sensitivity, specificity, precision, shd, tp, reversed_edges, fn, fp, tn] = eval_dags_adjust({dag}, true_dag, 1);
result = result_template();
result.name = name;
result.dag = logical(dag);
result.score = score;
result.iterations = iterations;
result.edge_count = nnz(dag);
result.f1 = f1;
result.sensitivity = sensitivity;
result.specificity = specificity;
result.precision = precision;
result.shd = shd;
result.tp = tp;
result.reversed_edges = reversed_edges;
result.fn = fn;
result.fp = fp;
result.tn = tn;
fprintf('%-12s F1=%.4f SHD=%.1f Precision=%.4f Recall=%.4f Reversed=%d Score=%.3f Iter=%d Edges=%d\n', ...
    name, f1, shd, precision, sensitivity, reversed_edges, score, iterations, result.edge_count);
end

function result = result_template()
result = struct('name', '', 'dag', [], 'score', NaN, 'iterations', NaN, 'edge_count', NaN, ...
    'f1', NaN, 'sensitivity', NaN, 'specificity', NaN, 'precision', NaN, ...
    'shd', NaN, 'tp', NaN, 'reversed_edges', NaN, 'fn', NaN, 'fp', NaN, 'tn', NaN);
end

function dag = normalize_dag_output(dag_cell, node_count)
if iscell(dag_cell)
    dag = dag_cell{1};
else
    dag = dag_cell;
end
if isvector(dag) && numel(dag) == node_count * node_count
    dag = reshape(dag', node_count, node_count)';
end
dag = logical(dag);
end

function write_mean_std_summary(all_results, summary_file)
table_data = struct2table(all_results);
method_column = cellstr(string(table_data.Method));
methods = unique(method_column, 'stable');
rows = struct([]);
count = 0;
for m = 1:numel(methods)
    mask = strcmp(method_column, methods{m});
    count = count + 1;
    rows(count).Method = methods{m}; %#ok<AGROW>
    rows(count).F1Mean = mean(table_data.F1(mask), 'omitnan'); %#ok<AGROW>
    rows(count).F1Std = std(table_data.F1(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SensitivityMean = mean(table_data.Sensitivity(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SensitivityStd = std(table_data.Sensitivity(mask), 'omitnan'); %#ok<AGROW>
    rows(count).PrecisionMean = mean(table_data.Precision(mask), 'omitnan'); %#ok<AGROW>
    rows(count).PrecisionStd = std(table_data.Precision(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHDMean = mean(table_data.SHD(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHDStd = std(table_data.SHD(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ReversedEdgesMean = mean(table_data.ReversedEdges(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ReversedEdgesStd = std(table_data.ReversedEdges(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ScoreMean = mean(table_data.Score(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ScoreStd = std(table_data.Score(mask), 'omitnan'); %#ok<AGROW>
    rows(count).EdgeCountMean = mean(table_data.EdgeCount(mask), 'omitnan'); %#ok<AGROW>
    rows(count).EdgeCountStd = std(table_data.EdgeCount(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Trials = sum(mask); %#ok<AGROW>
end
writetable(struct2table(rows), summary_file);
end
