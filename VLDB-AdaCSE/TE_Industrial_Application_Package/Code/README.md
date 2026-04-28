# Tennessee-Eastman Real Data Experiment

This folder provides a multi-method comparison pipeline for the Tennessee-Eastman
(TE) industrial process dataset.

## Expected inputs

Place the TE observation file and the reference DAG file into:

- `Application_Analysis/TE_Real_Data_Experiment/raw/`

Default file names:

- `te_raw.mat`
- `te_raw.csv`
- `te_raw.tsv`
- `te_raw.txt`
- `te_true_dag.mat`
- `te_true_dag.csv`
- `te_true_dag.tsv`
- `te_true_dag.txt`

The loader also directly supports the official CIPCaD-Bench TE file names:

- `datasetTE.csv`
- `TEGroundTruth.txt`

## Supported formats

Observation file:

- matrix data in `MAT`, `CSV`, `TSV`, or `TXT`
- either `variables x samples` or `samples x variables`
- if column names are available, they are preserved

Reference DAG file:

- square adjacency matrix
- or edge list with two columns: source / target
- if node names are available, the script reorders data to match the DAG

## Preparation

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
prepare_real_te_data;
```

This produces:

```text
Application_Analysis/TE_Real_Data_Experiment/Data/te_real_discrete.mat
```

## Main command

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
[all_results, summary_file] = run_real_te_comparison_experiment(10, 100, 200, 7, ...
    {'AdaCSE','PSX','EKGA-std','AESL-GA','hybrid-SLA','MIGA','MAGA'});
```

## Outputs

The script writes:

- per-trial structure metrics
- mean/std summary across trials
- learned DAG files for each trial

Output folder:

```text
[result]/<date>/TE_Real_Application_Batch/
```

## Downstream ranking analysis

To add a Sachs-style intervention ranking analysis on the saved TE DAGs:

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
results = run_real_te_downstream_ranking( ...
    'E:\GPT projects\BNSL_CSCGA_会议\[result]\20260423\TE_Real_Application_Batch\learned_dags\real_te_method_dags_trial01.mat', ...
    {'X1','X22'}, 3);
```

Default intervention nodes:

- `X1`: an upstream source node with broad downstream coverage
- `X22`: a midstream branching node with richer local propagation

To summarize all saved trials without rerunning structure learning:

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
[all_rows, summary_file] = run_real_te_application_batch_analysis( ...
    'E:\GPT projects\BNSL_CSCGA_会议\[result]\20260423\TE_Real_Application_Batch', ...
    {'X1','X22'}, 3);
```
