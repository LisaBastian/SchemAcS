#%%
import pandas as pd
from fix_vars import SLEEP, WAKE, CONTROL
import numpy as np
import seaborn as sns 
import matplotlib.pyplot as plt
import numpy as np
import itertools
import warnings
warnings.filterwarnings('ignore')
import pingouin as pg

def select_participants(df: pd.DataFrame, name: str):
    df = df[df['session']
        .str.lower()
        .str.startswith(name, na=False)
    ]
    return df

def get_metadata(df: pd.DataFrame):
    # 1) Keep only structured part before XXX
    df["session_base"] = (
        df["session"]
        .astype(str)
        .str.split("XXX", n=1)
        .str[0]
        .str.strip()
    )

    # 2) Extract metadata
    pattern = r'^(?P<study>[^_]+)_(?P<participant_num>\d+)(?P<condition>[A-Za-z])_(?P<visit>[^_]+)(?:_(?P<run>[^_]+))?$'

    meta = df["session_base"].str.extract(pattern)

    # 3) Assign extracted columns
    df[meta.columns] = meta

    # 4) Convert participant number to integer (optional)
    df["participant_num"] = pd.to_numeric(df["participant_num"], errors="coerce")
    return df
   
def add_condition(df: pd.DataFrame):
    cond_df = (
        pd.DataFrame.from_dict(CONDITIONS, orient='index')  # subjects ↓, visits →
        .stack()                                          # melt visits into rows
        .reset_index()                                    # bring visit name & subject into columns
        .rename(columns={
            'level_0': 'partID',
            'level_1': 'sessID',
            0:           'condition'
        })
    )
    cond_df['partID'] = cond_df['partID'].astype(str).str.zfill(2)

    df = (
        df
        .merge(cond_df, on=['partID','sessID'], how='left')
    )
    return df

def reverse_score(column: np.ndarray):
    column_rev=column.max() + column.min() - column
    return column_rev

def plot_scores(
    data: pd.DataFrame, 
    y_input: str,
    hue_val: str, 
    palette: dict,
    day_breaks: dict, 
    markers: list, 
    x_ticks: list,
    x_label: str, 
    y_label: str, 
    save_dir: str,
    ylim: tuple
):
    g = sns.catplot(
        data=data,
        x="repID", y=y_input,
        hue=hue_val,
        kind="point",
        capsize=0.5,
        errorbar="se",
        palette=palette,
        markers=markers,
        height=6, aspect=1.2,
        legend=False # ← disable legend,
    )

    ax = g.ax

    # define your three bands in terms of these positions:
    ax.axvspan(day_breaks['day1'][0] - 0.2, day_breaks['day1'][1] + 0.2,
            color='#fff2b2', alpha=0.3, zorder=0)


    ax.set_xticks(ax.get_xticks())
    ax.set_xticklabels(x_ticks, rotation=45)

    # axis labels & title
    ax.set_xlabel(x_label)
    ax.set_ylabel(y_label)
    ax.set_ylim(ylim)
    plt.savefig(save_dir)
    plt.show()

    return None 



def mixed_anova_test(df: pd.DataFrame, dv: str, within: str, between: str, subject: str):
    """
    Fit a mixed ANOVA (split-plot) using pingouin.

    Parameters
    ----------
    df      : long-format DataFrame
    dv      : dependent variable column
    within  : within-subjects factor column (e.g. 'repID')
    between : between-subjects factor column (e.g. 'condition')
    subject : participant identifier column

    Returns
    -------
    aov : ANOVA table (DataFrame) with columns Source, F, p-unc, p-GG-corr, ng2, eps
    """
    aov = pg.mixed_anova(
        data=df,
        dv=dv,
        within=within,
        between=between,
        subject=subject,
        correction='auto'  # applies GG correction when sphericity is violated
    )
    print("\nMixed ANOVA:")
    print(aov.to_string(index=False))
    return aov


def significant_terms_mixed(aov: pd.DataFrame, alpha: float = 0.05):
    """
    Return list of significant Source names from a pingouin mixed_anova table.
    Uses p-GG-corr when available (within-subject effects), else p-unc.
    """
    sig = []
    for _, row in aov.iterrows():
        p_gg = row.get('p-GG-corr', np.nan)
        p = p_gg if pd.notna(p_gg) else row['p-unc']
        if pd.notna(p) and p < alpha:
            sig.append(row['Source'])
    return sig


def post_hoc_mixed(df: pd.DataFrame, terms: list, dv: str, within: str, between: str,
                   subject: str, padjust: str = 'holm'):
    """
    Post-hoc pairwise tests for significant terms from a mixed ANOVA.

    - Between main effect  -> between-subjects pairwise tests (independent)
    - Within main effect   -> within-subjects pairwise tests (paired)
    - Interaction          -> full factorial pairwise tests

    Returns
    -------
    results : dict[source_name] -> DataFrame
    """
    results = {}
    for term in terms:
        print(f"\nPost-hoc comparisons for '{term}':")
        if term == between:
            ph = pg.pairwise_tests(
                data=df, dv=dv,
                between=between,
                subject=subject,
                padjust=padjust,
                effsize='cohen'
            )
        elif term == within:
            ph = pg.pairwise_tests(
                data=df, dv=dv,
                within=within,
                subject=subject,
                padjust=padjust,
                effsize='cohen'
            )
        else:  # Interaction
            ph = pg.pairwise_tests(
                data=df, dv=dv,
                within=within,
                between=between,
                subject=subject,
                padjust=padjust,
                effsize='cohen'
            )
        results[term] = ph
        print(ph.to_string(index=False))
    return results


def run_stats_mixed(df: pd.DataFrame, dv: str, within: str, between: str, subject: str,
                    alpha: float = 0.05, padjust: str = 'holm'):
    """
    1) Fit mixed ANOVA (pingouin) with correct within/between-subject error terms
    2) Print ANOVA table
    3) Identify significant terms (using GG-corrected p for within-subject effects)
    4) Run post-hoc pairwise tests for significant terms

    Returns
    -------
    aov, sig_terms, posthocs
    """
    aov = mixed_anova_test(df, dv, within=within, between=between, subject=subject)
    sig_terms = significant_terms_mixed(aov, alpha=alpha)

    print("\nSignificant terms:")
    print(sig_terms if sig_terms else "None")

    posthocs = post_hoc_mixed(df, sig_terms, dv, within=within, between=between,
                               subject=subject, padjust=padjust) if sig_terms else {}
    return aov, sig_terms, posthocs




# %%
