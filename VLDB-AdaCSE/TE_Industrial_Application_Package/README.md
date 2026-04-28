# TE Industrial Application Package

This package consolidates the code, input data, prepared data, and outputs for
the Tennessee-Eastman (TE) industrial application benchmark used in the paper.

## Folder Layout

- `Code/`
  - MATLAB scripts used to prepare TE data, run the multi-method comparison,
    recompute IGES-RCI-style exact-direction metrics, and perform exploratory
    downstream-ranking analysis.
- `Data/raw/`
  - Official TE raw files from CIPCaD-Bench.
- `Data/prepared/`
  - Prepared discrete TE data used by the MATLAB experiments.
- `Results/TE_Real_Application_Batch/`
  - Main structure-learning outputs, learned DAGs, and exact-direction
    recomputed metrics.
- `Results/TE_Real_Downstream_Ranking/`
  - Downstream-ranking exploration outputs kept for completeness.

## Quick Start

From the `VLDB-AdaCSE` directory:

```matlab
cd('VLDB-AdaCSE');
addpath(genpath(pwd));
```

Run the TE structure-learning comparison:

```matlab
[all_results, summary_file] = run_real_te_comparison_experiment(10, 100, 200, 7, ...
    {'AdaCSE','PSX','EKGA-std','AESL-GA','hybrid-SLA','MIGA','MAGA'});
```

Recompute TE metrics under the IGES-RCI exact-direction protocol:

```matlab
recompute_te_metrics_tkde(fullfile(pwd, 'TE_Industrial_Application_Package', ...
    'Results', 'TE_Real_Application_Batch'));
```

Run TE downstream-ranking analysis on the saved learned DAGs:

```matlab
[all_rows, summary_file] = run_real_te_application_batch_analysis( ...
    fullfile(pwd, 'TE_Industrial_Application_Package', 'Results', ...
    'TE_Real_Application_Batch'), {'X1','X22'}, 3);
```

## Reproducibility Notes

- The TE dataset is treated here as an industrial process benchmark from
  CIPCaD-Bench rather than a directly sampled benchmark-network dataset.
- The paper emphasizes the structure-learning outputs in
  `Results/TE_Real_Application_Batch/`.
- The downstream-ranking results are preserved in the artifact package for
  completeness, even though they are not part of the final paper narrative.
- Additional experiment and results notes are provided in:
  - `EXPERIMENTS.md`
  - `RESULTS.md`
