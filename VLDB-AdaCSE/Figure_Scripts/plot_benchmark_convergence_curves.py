from __future__ import annotations

import argparse
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


NETWORKS = ["Asia", "Insurance", "Water", "Alarm", "Hailfinder", "HeparII", "Win95pts", "Andes"]
DATASET_SIZES = [500, 1000, 3000]
ITERATIONS = 200
ALGORITHMS = ["MAGA", "hybrid_SLA", "EKGA", "AESL_GA", "PSX", "MIGA", "COFTGA"]
DISPLAY_NAMES = {
    "MAGA": "MAGABN",
    "hybrid_SLA": "hybrid-SLA",
    "EKGA": "EKGA",
    "AESL_GA": "AESL-GA",
    "PSX": "PSX",
    "MIGA": "MIGA",
    "COFTGA": "AdaCSE",
}
COLORS = {
    "MAGA": "#f08a5d",
    "hybrid_SLA": "#7ABBDB",
    "EKGA": "#84BA42",
    "AESL_GA": "#A5AEB7",
    "PSX": "#DBB428",
    "MIGA": "#DCA7EB",
    "COFTGA": "#E34A33",
}
MARKERS = {
    "MAGA": "p",
    "hybrid_SLA": "o",
    "EKGA": "s",
    "AESL_GA": "^",
    "PSX": "D",
    "MIGA": "v",
    "COFTGA": "*",
}


def parse_args() -> argparse.Namespace:
    script_dir = Path(__file__).resolve().parent
    default_input = script_dir.parent / "[result]" / "20260302" / "Convergence_Behavior"
    default_output = script_dir / "output"
    parser = argparse.ArgumentParser(description="Generate convergence figures from saved trial CSV files.")
    parser.add_argument("--input-dir", type=Path, default=default_input)
    parser.add_argument("--output-dir", type=Path, default=default_output)
    return parser.parse_args()


def parse_filename(filename: str) -> dict[str, object] | None:
    if not filename.endswith(".csv"):
        return None
    stem = filename[:-4]
    try:
        main_part, repeat_id = stem.rsplit("-", 1)
    except ValueError:
        return None
    if len(repeat_id) != 2 or not repeat_id.isdigit():
        return None

    parts = main_part.split("_")
    if len(parts) < 4:
        return None
    network_and_size = parts[0]
    population_size = int(parts[1])
    iterations = int(parts[2])
    algorithm = "_".join(parts[3:])

    digits = ""
    index = len(network_and_size) - 1
    while index >= 0 and network_and_size[index].isdigit():
        digits = network_and_size[index] + digits
        index -= 1
    if not digits:
        return None
    network = network_and_size[: index + 1]
    if network not in NETWORKS:
        return None
    return {
        "network": network,
        "dataset_size": int(digits),
        "population_size": population_size,
        "iterations": iterations,
        "algorithm": algorithm,
    }


def load_mean_curve(input_dir: Path, network: str, dataset_size: int, algorithm: str) -> np.ndarray | None:
    runs = []
    for csv_file in input_dir.glob("*.csv"):
        parsed = parse_filename(csv_file.name)
        if parsed is None:
            continue
        if (
            parsed["network"] == network
            and parsed["dataset_size"] == dataset_size
            and parsed["algorithm"] == algorithm
            and parsed["iterations"] == ITERATIONS
        ):
            frame = pd.read_csv(csv_file, header=None)
            if frame.empty:
                continue
            values = frame.iloc[:, 0].to_numpy()
            if len(values) < ITERATIONS:
                values = np.concatenate([values, np.full(ITERATIONS - len(values), values[-1])])
            else:
                values = values[:ITERATIONS]
            runs.append(values)
    if not runs:
        return None
    return np.mean(np.vstack(runs), axis=0)


def plot_single_figure(input_dir: Path, output_dir: Path, network: str, dataset_size: int) -> None:
    figure, axis = plt.subplots(figsize=(8, 6))
    plotted = False
    x_values = np.arange(ITERATIONS)

    for algorithm in ALGORITHMS:
        curve = load_mean_curve(input_dir, network, dataset_size, algorithm)
        if curve is None:
            continue
        plotted = True
        axis.plot(
            x_values,
            curve,
            label=DISPLAY_NAMES.get(algorithm, algorithm),
            color=COLORS.get(algorithm),
            linewidth=2.5,
            marker=MARKERS.get(algorithm, "o"),
            markevery=20,
            markersize=6,
            markerfacecolor=COLORS.get(algorithm),
        )

    if not plotted:
        plt.close(figure)
        return

    title = f"{network}{dataset_size}"
    axis.set_title(f"BIC Convergence - {title}", fontsize=20, pad=20)
    axis.set_xlabel("Iteration", fontsize=16)
    axis.set_ylabel("Mean BIC Score", fontsize=16)
    axis.legend(loc="lower right", fontsize=12, frameon=True)
    axis.grid(False)
    axis.set_xlim(0, ITERATIONS - 1)
    plt.margins(x=0)
    figure.tight_layout()
    figure.savefig(output_dir / f"{title}_convergence.pdf", dpi=300, bbox_inches="tight")
    plt.close(figure)


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    plt.rcParams.update({"font.size": 18})
    plt.rcParams["font.family"] = "serif"
    plt.rcParams["font.serif"] = ["Times New Roman"] + plt.rcParams["font.serif"]
    plt.rcParams["mathtext.fontset"] = "stix"
    plt.rcParams["axes.unicode_minus"] = False

    for network in NETWORKS:
        for dataset_size in DATASET_SIZES:
            plot_single_figure(args.input_dir, args.output_dir, network, dataset_size)


if __name__ == "__main__":
    main()
