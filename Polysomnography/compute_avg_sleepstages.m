
conditions = {'wake','sleep'};

for cond = 1:length(conditions)
    load(strcat('/Volumes/T7/01_SchemAcS/05_Analysis/SleepAnalysis/Scorings/sleep_descriptives_table_',conditions{cond},'.mat'));
    data = sleep_descriptives;
    clear sleep_descriptives
    % --- Compute TST (sum of all stages) per participant ---
    TST = sum(data, 2);
    TST = TST.sum;

    % --- Compute percentage columns (relative to TST) ---
    pct_WASO = (data.Wake_min ./ TST) * 100;
    pct_N1   = (data.N1_min ./ TST) * 100;
    pct_N2   = (data.N2_min ./ TST) * 100;
    pct_N3   = (data.N3_min ./ TST) * 100;
    pct_REM  = (data.REM_min ./ TST) * 100;

    % --- Build full results table ---
    data.TST = TST;
    data.pctWASO = pct_WASO;
    data.pct_N1 = pct_N1;
    data.pct_N2 = pct_N2;
    data.pct_N3 = pct_N3;
    data.pct_REM = pct_REM;

    % --- Compute group averages ---
    groupAvg = mean(data, 1);
    groupSD  = std(data,1);
    groupmin = min(data,[],1);
    groupmax = max(data,[],1);

    % --- Display results ---
    disp("========== Per-Participant Results ==========");
    disp(data);

    disp("========== Group Averages ==========");
    disp(groupAvg);
    disp(groupSD);
    disp(groupmin);
    disp(groupmax);
end



