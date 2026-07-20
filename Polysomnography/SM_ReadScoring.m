function SM_ReadScoring(dirScoring,dirSave,dirFig)

dataFiles = loadFile(dirScoring,'SchemAcS','start');

for iSub = 1:length(dataFiles)
    
    cfg = [];
    cfg.scoringfile   = strcat(dirScoring,dataFiles(iSub).name);
    %cfg.scoringarousalsfile = strcat(dirArtifact,artifactFiles(iSub).name);
    cfg.scoringformat = 'schlafaus';
    cfg.standard      = 'aasm'; % 'aasm' or 'rk'
    scoring = st_read_scoring(cfg);

    if isfield(scoring,'arousals')
        scoring = st_exclude_events_scoring(cfg, scoring, scoring.arousals.start, scoring.arousals.stop);
    end

    %save the scorings 
    save(strcat(dirSave,extractBefore(dataFiles(iSub).name,'_export'), '_scoring.mat'),'scoring');
    
    %duration of each sleep stage in minutes
    dur_Wake(iSub) = sum(strcmp(scoring.epochs, 'W'))*30/60;
    dur_N1(iSub)   = sum(strcmp(scoring.epochs, 'N1'))*30/60;
    dur_N2(iSub)   = sum(strcmp(scoring.epochs, 'N2'))*30/60;
    dur_N3(iSub)   = sum(strcmp(scoring.epochs, 'N3'))*30/60;
    dur_REM(iSub)  = sum(strcmp(scoring.epochs, 'R'))*30/60;

    cfg = [];
    cfg.plottype      = 'classic';
    cfg.colorscheme   = 'dark';
    cfg.plotlightsoff = 'no';
    cfg.plotlightson  = 'no';
    cfg.plotunknown   = 'no';
    cfg.plotexcluded  = 'yes';
    st_hypnoplot(cfg,scoring);
    saveas(gcf,strcat(dirFig,'hypnoplot_',extractBefore(dataFiles(iSub).name,'_export'),'.pdf'))

end

sleep_descriptives = table(dur_Wake',dur_N1',dur_N2',dur_N3',dur_REM','VariableNames',{'Wake_min','N1_min','N2_min','N3_min','REM_min'});
save(strcat(dirSave,'sleep_descriptives_table.mat'),'sleep_descriptives')