# TE Results

This file explains which TE outputs correspond to the paper's claims.

## Main Paper Results

The final TE structure-learning results used in the paper are:

- `Results/TE_Real_Application_Batch/real_te_structure_metrics_all_trials.csv`
- `Results/TE_Real_Application_Batch/real_te_structure_metrics_mean_std.csv`

These files support the reported TE comparison table for:

- F1
- Recall / sensitivity under the paper's benchmark evaluator
- Precision
- SHD

## Exact-Direction Comparison

The following files support the direct comparison with IGES-RCI under the
exact-direction protocol:

- `Results/TE_Real_Application_Batch/real_te_structure_metrics_tkde_all_trials.csv`
- `Results/TE_Real_Application_Batch/real_te_structure_metrics_tkde_mean_std.csv`

In this stricter protocol, reversed edges are counted as one structural error
instead of receiving half credit.

## Learned Structures

The learned TE DAGs for each method and trial are stored under:

- `Results/TE_Real_Application_Batch/learned_dags/`

These files can be reused to:

- recompute metrics,
- inspect learned structures,
- reproduce post-hoc analyses without rerunning the full experiment.

## Exploratory Outputs

The downstream-ranking outputs are kept under:

- `Results/TE_Real_Downstream_Ranking/`

These files are preserved for transparency and completeness, but are not part
of the final paper's main experimental evidence.
