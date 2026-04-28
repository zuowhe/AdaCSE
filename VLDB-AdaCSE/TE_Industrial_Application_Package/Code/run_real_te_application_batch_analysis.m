function [all_rows, summary_file] = run_real_te_application_batch_analysis(result_dir, intervention_nodes, intervention_state)
%RUN_REAL_TE_APPLICATION_BATCH_ANALYSIS Batch downstream ranking on saved TE DAGs.
%
% Defaults:
%   result_dir = [result]/20260423/TE_Real_Application_Batch
%   intervention_nodes = {'X1', 'X22'}
%   intervention_state = 3

if nargin < 1 || isempty(result_dir)
    project_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    result_dir = fullfile(project_root, '[result]', '20260423', 'TE_Real_Application_Batch');
end
if nargin < 2 || isempty(intervention_nodes), intervention_nodes = {'X1', 'X22'}; end
if nargin < 3 || isempty(intervention_state), intervention_state = 3; end

dag_dir = fullfile(result_dir, 'learned_dags');
dag_files = dir(fullfile(dag_dir, 'real_te_method_dags_trial*.mat'));
if isempty(dag_files)
    error('No TE learned DAG files found in %s.', dag_dir);
end

all_rows = struct([]);
row_count = 0;

for f = 1:numel(dag_files)
    dag_file = fullfile(dag_dir, dag_files(f).name);
    loaded = load(dag_file, 'trial_id', 'data_size');
    ranking_results = run_real_te_downstream_ranking(dag_file, intervention_nodes, intervention_state);
    for q = 1:numel(ranking_results)
        for m = 1:numel(ranking_results(q).methods)
            metrics = ranking_results(q).methods(m).metrics;
            row_count = row_count + 1;
            all_rows(row_count).DataSize = loaded.data_size; %#ok<AGROW>
            all_rows(row_count).Trial = loaded.trial_id; %#ok<AGROW>
            all_rows(row_count).Intervention = ranking_results(q).intervention; %#ok<AGROW>
            all_rows(row_count).Method = ranking_results(q).methods(m).name; %#ok<AGROW>
            all_rows(row_count).Spearman = metrics.spearman; %#ok<AGROW>
            all_rows(row_count).Kendall = metrics.kendall; %#ok<AGROW>
            all_rows(row_count).NDCG_at_5 = metrics.ndcg_at_5; %#ok<AGROW>
            all_rows(row_count).RankingSummaryFile = ranking_results(q).summary_file; %#ok<AGROW>
            all_rows(row_count).RankingDetailFile = ranking_results(q).detail_file; %#ok<AGROW>
        end
    end
end

all_table = struct2table(all_rows, 'AsArray', true);
detail_file = fullfile(result_dir, 'real_te_downstream_metrics_all_trials.csv');
writetable(all_table, detail_file);

summary_table = summarize_rows(all_table);
summary_file = fullfile(result_dir, 'real_te_downstream_metrics_mean_std.csv');
writetable(summary_table, summary_file);

fprintf('\nSaved downstream metrics: %s\n', detail_file);
fprintf('Saved mean/std summary:  %s\n', summary_file);
end

function summary_table = summarize_rows(all_table)
interventions = unique(cellstr(string(all_table.Intervention)), 'stable');
methods = unique(cellstr(string(all_table.Method)), 'stable');
rows = struct([]);
count = 0;

for q = 1:numel(interventions)
    for m = 1:numel(methods)
        mask = strcmp(cellstr(string(all_table.Intervention)), interventions{q}) & ...
               strcmp(cellstr(string(all_table.Method)), methods{m});
        if ~any(mask), continue; end
        count = count + 1;
        rows(count).Intervention = interventions{q}; %#ok<AGROW>
        rows(count).Method = methods{m}; %#ok<AGROW>
        rows(count).SpearmanMean = mean(all_table.Spearman(mask), 'omitnan'); %#ok<AGROW>
        rows(count).SpearmanStd = std(all_table.Spearman(mask), 'omitnan'); %#ok<AGROW>
        rows(count).KendallMean = mean(all_table.Kendall(mask), 'omitnan'); %#ok<AGROW>
        rows(count).KendallStd = std(all_table.Kendall(mask), 'omitnan'); %#ok<AGROW>
        rows(count).NDCG_at_5_Mean = mean(all_table.NDCG_at_5(mask), 'omitnan'); %#ok<AGROW>
        rows(count).NDCG_at_5_Std = std(all_table.NDCG_at_5(mask), 'omitnan'); %#ok<AGROW>
        rows(count).Trials = sum(mask); %#ok<AGROW>
    end
end

summary_table = struct2table(rows, 'AsArray', true);
end
