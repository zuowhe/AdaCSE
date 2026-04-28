from __future__ import annotations

from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


METHODS = ["SR-Fix", "SR-Adapt", "SM-Fix", "SM-Adapt", "DR-Adapt", "AdaCSE"]
DATASETS = ["Asia", "Insurance", "Water", "Alarm", "Hailfinder", "HeparII", "Win95pts", "AND"]
SAMPLE_SIZES = [500, 1000, 3000]
COLORS = ["#a2738c", "#6eb6ff", "#66c6ba", "#ffd460", "#3A5FCD", "#ea5455"]

def normalize_rows(values: np.ndarray, higher_is_better: bool) -> np.ndarray:
    normalized = np.zeros_like(values, dtype=float)
    for row_index in range(values.shape[0]):
        row = values[row_index]
        row_min = row.min()
        row_max = row.max()
        if row_max == row_min:
            normalized[row_index, :] = 1.0
        elif higher_is_better:
            normalized[row_index, :] = (row - row_min) / (row_max - row_min)
        else:
            normalized[row_index, :] = (row_max - row) / (row_max - row_min)
    return normalized


def load_metric_table(csv_path: Path, value_column: str) -> np.ndarray:
    table = pd.read_csv(csv_path)
    blocks = np.zeros((len(DATASETS), len(SAMPLE_SIZES), len(METHODS)))
    for dataset_index, dataset in enumerate(DATASETS):
        for sample_index, sample_size in enumerate(SAMPLE_SIZES):
            subset = table[(table["Dataset"] == dataset) & (table["SampleSize"] == sample_size)]
            subset = subset.set_index("Method").loc[METHODS]
            blocks[dataset_index, sample_index, :] = subset[value_column].to_numpy()
    return blocks


def plot_single_radar(output_path: Path, title: str, values: np.ndarray) -> None:
    figure, axis = plt.subplots(figsize=(8, 8), subplot_kw={"projection": "polar"})
    angles = np.linspace(0, 2 * np.pi, len(DATASETS), endpoint=False).tolist()
    angles += angles[:1]

    axis.set_theta_offset(np.pi / 2)
    axis.set_theta_direction(-1)
    axis.set_thetagrids(np.degrees(angles[:-1]), DATASETS)
    axis.set_ylim(-0.2, 1.0)
    axis.tick_params(axis="x", labelsize=16, labelcolor="black")
    axis.tick_params(axis="y", labelsize=16, labelcolor="black")

    for method_index, method in enumerate(METHODS):
        method_values = values[:, method_index].tolist()
        method_values += method_values[:1]
        is_adacse = method == "AdaCSE"
        axis.plot(
            angles,
            method_values,
            linewidth=2.5 if is_adacse else 1.8,
            marker="o" if is_adacse else "s",
            markersize=6 if is_adacse else 4,
            color=COLORS[method_index],
            label=method,
        )
        axis.fill(angles, method_values, color=COLORS[method_index], alpha=0.25 if is_adacse else 0.10)

    axis.legend(loc="upper center", bbox_to_anchor=(0.5, -0.05), ncol=3, prop={"size": 14})
    figure.tight_layout()
    figure.savefig(output_path, dpi=300, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    data_dir = script_dir / "data"
    output_dir = script_dir / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    plt.rcParams["font.family"] = "Times New Roman"

    f1_blocks = load_metric_table(data_dir / "benchmark_ablation_f1.csv", "F1")
    shd_blocks = load_metric_table(data_dir / "benchmark_ablation_shd.csv", "SHD")

    plot_plan = [
        ("F1_500_radar.pdf", normalize_rows(f1_blocks[:, 0, :], True)),
        ("F1_1000_radar.pdf", normalize_rows(f1_blocks[:, 1, :], True)),
        ("F1_3000_radar.pdf", normalize_rows(f1_blocks[:, 2, :], True)),
        ("SHD_500_radar.pdf", normalize_rows(shd_blocks[:, 0, :], False)),
        ("SHD_1000_radar.pdf", normalize_rows(shd_blocks[:, 1, :], False)),
        ("SHD_3000_radar.pdf", normalize_rows(shd_blocks[:, 2, :], False)),
    ]

    for filename, values in plot_plan:
        plot_single_radar(output_dir / filename, filename, values)


if __name__ == "__main__":
    main()
