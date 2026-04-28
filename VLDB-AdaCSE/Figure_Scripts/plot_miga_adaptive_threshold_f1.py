from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd


ALPHA_VALUES = [0.01, 0.02, 0.03, 0.05, 0.10, 0.20, 0.30, 0.50, 1.00]
ALPHA_COLUMNS = [
    "Alpha0p01",
    "Alpha0p02",
    "Alpha0p03",
    "Alpha0p05",
    "Alpha0p10",
    "Alpha0p20",
    "Alpha0p30",
    "Alpha0p50",
    "Alpha1p00",
]


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    data_path = script_dir / "data" / "miga_adaptive_threshold_f1.csv"
    output_dir = script_dir / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    table = pd.read_csv(data_path)

    for _, row in table.iterrows():
        figure, axis = plt.subplots(figsize=(8, 5))
        fixed_values = [row[column] for column in ALPHA_COLUMNS]
        adaptive_value = row["AdaptiveF1"]
        dataset_name = row["Dataset"]

        axis.plot(ALPHA_VALUES, fixed_values, marker="o", label="MIGA")
        axis.fill_between(ALPHA_VALUES, adaptive_value, fixed_values, color="skyblue", alpha=0.4)
        axis.axhline(y=adaptive_value, color="r", linestyle="--", label=f"AdaCSE = {adaptive_value:.4f}")
        axis.set_title(f"{dataset_name} - F1 Score vs. Significance Level")
        axis.set_xlabel("Significance Level")
        axis.set_ylabel("F1 Score")
        axis.set_xscale("log")
        axis.legend()
        axis.grid(True, which="both", linestyle="--", linewidth=0.5)
        figure.tight_layout()
        figure.savefig(output_dir / f"{dataset_name}_MIGA_F1.pdf", dpi=300, bbox_inches="tight")
        plt.close(figure)


if __name__ == "__main__":
    main()
