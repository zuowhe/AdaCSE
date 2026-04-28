function [all_rows, summary_file] = recompute_te_metrics_tkde(result_dir)
%RECOMPUTE_TE_METRICS_TKDE Re-evaluate saved TE DAGs with exact-direction metrics.
%
% This function does not touch the original 0.5-penalty evaluation. It
% recomputes metrics from saved DAGs using exact directed matches:
%   Recall    = TP / (TP + FN)
%   Precision = TP / (TP + FP)
%   F1        = 2 * Recall * Precision / (Recall + Precision)
%   SHD_FPFN  = FP + FN
%
% Because some papers describe reversed edges as one structural error, we
% also export:
%   SHD_Rev1 = FP + FN - ReversedEdges

if nargin < 1 || isempty(result_dir)
    project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    result_dir = fullfile(project_root, '[result]', '20260423', 'TE_Real_Application_Batch');
end

dag_dir = fullfile(result_dir, 'learned_dags');
dag_files = dir(fullfile(dag_dir, 'real_te_method_dags_trial*.mat'));
if isempty(dag_files)
    error('No TE learned DAG files found in %s.', dag_dir);
end

all_rows = struct([]);
row_count = 0;

for f = 1:numel(dag_files)
    loaded = load(fullfile(dag_dir, dag_files(f).name));
    if ~isfield(loaded, 'true_dag')
        error('true_dag not found in %s.', dag_files(f).name);
    end
    true_dag = logical(loaded.true_dag);

    for m = 1:numel(loaded.method_dags)
        row_count = row_count + 1;
        dag = normalize_dag_output(loaded.method_dags(m).dag, size(true_dag, 1));
        metrics = eval_dag_tkde(dag, true_dag);

        all_rows(row_count).DataSize = loaded.data_size; %#ok<AGROW>
        all_rows(row_count).NodeCount = size(true_dag, 1); %#ok<AGROW>
        all_rows(row_count).Trial = loaded.trial_id; %#ok<AGROW>
        all_rows(row_count).Method = loaded.method_dags(m).name; %#ok<AGROW>
        all_rows(row_count).F1_TKDE = metrics.f1; %#ok<AGROW>
        all_rows(row_count).Sensitivity_TKDE = metrics.recall; %#ok<AGROW>
        all_rows(row_count).Precision_TKDE = metrics.precision; %#ok<AGROW>
        all_rows(row_count).Specificity_TKDE = metrics.specificity; %#ok<AGROW>
        all_rows(row_count).SHD_FPFN = metrics.shd_fpfn; %#ok<AGROW>
        all_rows(row_count).SHD_Rev1 = metrics.shd_rev1; %#ok<AGROW>
        all_rows(row_count).TP = metrics.tp; %#ok<AGROW>
        all_rows(row_count).FP = metrics.fp; %#ok<AGROW>
        all_rows(row_count).FN = metrics.fn; %#ok<AGROW>
        all_rows(row_count).TN = metrics.tn; %#ok<AGROW>
        all_rows(row_count).ReversedEdges = metrics.reversed; %#ok<AGROW>
        all_rows(row_count).Score = loaded.method_dags(m).score; %#ok<AGROW>
        all_rows(row_count).Iterations = loaded.method_dags(m).iterations; %#ok<AGROW>
        all_rows(row_count).EdgeCount = nnz(dag); %#ok<AGROW>
    end
end

all_table = struct2table(all_rows, 'AsArray', true);
all_file = fullfile(result_dir, 'real_te_structure_metrics_tkde_all_trials.csv');
writetable(all_table, all_file);

summary_table = summarize_rows(all_table);
summary_file = fullfile(result_dir, 'real_te_structure_metrics_tkde_mean_std.csv');
writetable(summary_table, summary_file);

fprintf('Saved TKDE-style structure metrics: %s\n', all_file);
fprintf('Saved TKDE-style mean/std summary:  %s\n', summary_file);
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

function metrics = eval_dag_tkde(dag, true_dag)
n = size(true_dag, 1);
tp = 0;
fp = 0;
fn = 0;
tn = 0;
reversed = 0;

for i = 1:n
    for j = i+1:n
        true_code = edge_code(true_dag(i, j), true_dag(j, i));
        pred_code = edge_code(dag(i, j), dag(j, i));

        if true_code == 0
            if pred_code == 0
                tn = tn + 1;
            else
                fp = fp + 1;
            end
        else
            if pred_code == 0
                fn = fn + 1;
            elseif pred_code == true_code
                tp = tp + 1;
            else
                reversed = reversed + 1;
                fp = fp + 1;
                fn = fn + 1;
            end
        end
    end
end

if tp + fn == 0
    recall = 1;
else
    recall = tp / (tp + fn);
end

if tp + fp == 0
    precision = 1;
else
    precision = tp / (tp + fp);
end

if tn + fp == 0
    specificity = 1;
else
    specificity = tn / (tn + fp);
end

if recall + precision == 0
    f1 = 0;
else
    f1 = 2 * recall * precision / (recall + precision);
end

metrics = struct();
metrics.tp = tp;
metrics.fp = fp;
metrics.fn = fn;
metrics.tn = tn;
metrics.reversed = reversed;
metrics.recall = recall;
metrics.precision = precision;
metrics.specificity = specificity;
metrics.f1 = f1;
metrics.shd_fpfn = fp + fn;
metrics.shd_rev1 = fp + fn - reversed;
end

function code = edge_code(ij, ji)
if ij && ~ji
    code = 1;
elseif ~ij && ji
    code = -1;
else
    code = 0;
end
end

function summary_table = summarize_rows(all_table)
methods = unique(cellstr(string(all_table.Method)), 'stable');
rows = struct([]);
count = 0;

for m = 1:numel(methods)
    mask = strcmp(cellstr(string(all_table.Method)), methods{m});
    count = count + 1;
    rows(count).Method = methods{m}; %#ok<AGROW>
    rows(count).F1_TKDE_Mean = mean(all_table.F1_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).F1_TKDE_Std = std(all_table.F1_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Sensitivity_TKDE_Mean = mean(all_table.Sensitivity_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Sensitivity_TKDE_Std = std(all_table.Sensitivity_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Precision_TKDE_Mean = mean(all_table.Precision_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Precision_TKDE_Std = std(all_table.Precision_TKDE(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHD_FPFN_Mean = mean(all_table.SHD_FPFN(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHD_FPFN_Std = std(all_table.SHD_FPFN(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHD_Rev1_Mean = mean(all_table.SHD_Rev1(mask), 'omitnan'); %#ok<AGROW>
    rows(count).SHD_Rev1_Std = std(all_table.SHD_Rev1(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ReversedEdgesMean = mean(all_table.ReversedEdges(mask), 'omitnan'); %#ok<AGROW>
    rows(count).ReversedEdgesStd = std(all_table.ReversedEdges(mask), 'omitnan'); %#ok<AGROW>
    rows(count).Trials = sum(mask); %#ok<AGROW>
end

summary_table = struct2table(rows, 'AsArray', true);
end
