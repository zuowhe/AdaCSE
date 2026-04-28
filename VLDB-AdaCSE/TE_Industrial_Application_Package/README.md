# TE Industrial Application Package

This folder consolidates the TE-related experiment assets used in the project.

## Layout

- `Code/`
  - TE experiment scripts
- `Data/raw/`
  - official TE raw files from CIPCaD-Bench
- `Data/prepared/`
  - prepared discrete TE data used by the MATLAB experiments
- `Results/TE_Real_Application_Batch/`
  - structure-learning outputs, learned DAGs, and TKDE-style recomputed metrics
- `Results/TE_Real_Downstream_Ranking/`
  - downstream-ranking exploration outputs

## Main commands

Run the TE structure-learning comparison:

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
[all_results, summary_file] = run_real_te_comparison_experiment(10, 100, 200, 7, ...
    {'AdaCSE','PSX','EKGA-std','AESL-GA','hybrid-SLA','MIGA','MAGA'});
```

Recompute TE metrics under the IGES-RCI exact-direction protocol:

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
recompute_te_metrics_tkde('E:\GPT projects\BNSL_CSCGA_会议\[result]\20260423\TE_Real_Application_Batch');
```

Run TE downstream-ranking analysis on saved learned DAGs:

```matlab
cd('E:\GPT projects\BNSL_CSCGA_会议');
addpath(genpath(pwd));
[all_rows, summary_file] = run_real_te_application_batch_analysis( ...
    'E:\GPT projects\BNSL_CSCGA_会议\[result]\20260423\TE_Real_Application_Batch', ...
    {'X1','X22'}, 3);
```

## Notes

- The TE dataset here is treated as an industrial process benchmark rather than a directly sampled benchmark-network dataset.
- The downstream-ranking results are preserved for completeness, even though they are not currently emphasized in the paper.
