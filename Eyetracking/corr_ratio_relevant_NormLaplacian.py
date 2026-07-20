# %%
"""
Correlation plots: selected predictors × SchemaMemoryIndex
SchemaMemoryIndex = 1 - NormLaplacianEigenDist  (higher = better schema memory)
Coloured by condition (sleep/wake), with per-condition and overall Pearson r.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

BASE  = "/Volumes/T7/01_SchemAcS/05_Analysis/Performance_Logs/SelectiveLog/Py_Analysis_s6/"
COND_PALETTE = {"sleep": "#3c5488", "wake": "#e54c35"}
PREDICTORS = ["ratio_relevant_irrel", "gaze_entropy_norm"]
Y_COL = "SchemaMemoryIndex"

# ── 1. Load & collapse (same logic as OLS script) ─────────────────────────────
df = pd.read_csv(BASE + "avg_feature_graph_metrics.csv")

agg_cols = {col: (col, "first") if col in ("condition", "Gender") else (col, "mean")
            for col in ["condition", "Gender"] + PREDICTORS + ["NormLaplacianEigenDist"]}

df_sub = (df[df["extend"] == "0_1"]
            .groupby("participant_id", as_index=False)
            .agg(**agg_cols))

df_sub["condition"] = pd.Categorical(df_sub["condition"], categories=["sleep", "wake"])

# Schema memory index: higher = better memory
df_sub[Y_COL] = 1 - df_sub["NormLaplacianEigenDist"]

# ── 2. Helper ─────────────────────────────────────────────────────────────────
def pearson_str(x, y):
    r, p = stats.pearsonr(x, y)
    p_str = f"p = {p:.3f}" if p >= 0.001 else "p < 0.001"
    return r, p, f"r = {r:.3f}, {p_str}"

# ── 3. One plot per predictor ─────────────────────────────────────────────────
for x_col in PREDICTORS:
    data = df_sub.dropna(subset=[x_col, Y_COL])

    r_all, p_all, label_all = pearson_str(data[x_col], data[Y_COL])

    corr_by_cond = {cond: pearson_str(sub[x_col], sub[Y_COL])
                    for cond, sub in data.groupby("condition")}

    fig, ax = plt.subplots(figsize=(7, 5.5))

    # Overall regression line (grey dashed)
    m, b = np.polyfit(data[x_col], data[Y_COL], 1)
    x_range = np.linspace(data[x_col].min(), data[x_col].max(), 200)
    ax.plot(x_range, m * x_range + b, color="grey", linewidth=1.5,
            linestyle="--", zorder=1, label=f"Overall  {label_all}")

    # Per-condition scatter + regression line
    for cond, color in COND_PALETTE.items():
        sub = data[data["condition"] == cond]
        r, p, label = corr_by_cond[cond]
        sns.regplot(data=sub, x=x_col, y=Y_COL, ax=ax,
                    color=color, ci=95, label=f"{cond.capitalize()}  {label}",
                    scatter_kws={"s": 60, "alpha": 0.80, "edgecolors": "white",
                                 "linewidths": 0.5, "zorder": 3},
                    line_kws={"linewidth": 2.0, "zorder": 2})

    ax.set_xlabel(x_col, fontsize=11)
    ax.set_ylabel(Y_COL, fontsize=11)
    ax.set_title(f"Correlation: {x_col} × {Y_COL}", fontsize=12)
    ax.legend(fontsize=9, title="Condition", title_fontsize=9)

    sns.despine()
    plt.tight_layout()

    out = BASE + f"plots/corr_{x_col}_{Y_COL}.pdf"
    plt.savefig(out, format="pdf")
    plt.show()
    print(f"Saved: {out}")
    print(f"  Overall:  {label_all}  (N={len(data)})")
    for cond, (r, p, lbl) in corr_by_cond.items():
        n = data[data["condition"] == cond].shape[0]
        print(f"  {cond.capitalize()}: {lbl}  (N={n})")

# ── 4. Predictor–predictor correlation ───────────────────────────────────────
x_col, y_col = PREDICTORS  # ratio_relevant_irrel, gaze_entropy_norm
data = df_sub.dropna(subset=[x_col, y_col])

r_all, p_all, label_all = pearson_str(data[x_col], data[y_col])
corr_by_cond = {cond: pearson_str(sub[x_col], sub[y_col])
                for cond, sub in data.groupby("condition")}

fig, ax = plt.subplots(figsize=(7, 5.5))

m, b = np.polyfit(data[x_col], data[y_col], 1)
x_range = np.linspace(data[x_col].min(), data[x_col].max(), 200)
ax.plot(x_range, m * x_range + b, color="grey", linewidth=1.5,
        linestyle="--", zorder=1, label=f"Overall  {label_all}")

for cond, color in COND_PALETTE.items():
    sub = data[data["condition"] == cond]
    r, p, label = corr_by_cond[cond]
    sns.regplot(data=sub, x=x_col, y=y_col, ax=ax,
                color=color, ci=95, label=f"{cond.capitalize()}  {label}",
                scatter_kws={"s": 60, "alpha": 0.80, "edgecolors": "white",
                             "linewidths": 0.5, "zorder": 3},
                line_kws={"linewidth": 2.0, "zorder": 2})

ax.set_xlabel(x_col, fontsize=11)
ax.set_ylabel(y_col, fontsize=11)
ax.set_title(f"Predictor correlation: {x_col} × {y_col}", fontsize=12)
ax.legend(fontsize=9, title="Condition", title_fontsize=9)

sns.despine()
plt.tight_layout()

out = BASE + f"plots/corr_{x_col}_{y_col}.pdf"
plt.savefig(out, format="pdf")
plt.show()
print(f"Saved: {out}")
print(f"  Overall:  {label_all}  (N={len(data)})")
for cond, (r, p, lbl) in corr_by_cond.items():
    n = data[data["condition"] == cond].shape[0]
    print(f"  {cond.capitalize()}: {lbl}  (N={n})")

# %%
