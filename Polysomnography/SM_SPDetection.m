function SM_SPDetection(dirScoring,dirData,dirFreqs,dirSaveSP,WinLen,channel_list,sp_type,condition)

scoringFiles = loadFile(dirScoring,'SchemAcS','start');
res_freqpeaks = readtable(strcat(dirFreqs,'spindle_power_peak_freqs_',condition,'.csv'));
dataFiles = loadFile(dirData,'.mat','end');
dataFiles = dataFiles(~startsWith({dataFiles.name},'.'));

res_spindles_channels = cell(1,numel(scoringFiles));
res_spindles_events = cell(1,numel(scoringFiles));

for iSub = 1:length(scoringFiles)    
    
    %check if slow or fast spindles should be computed
    if strcmp(sp_type,'Slow')
        freqpeak   = res_freqpeaks.freqpeak1(iSub);
    elseif strcmp(sp_type,'Fast')
        freqpeak   = res_freqpeaks.freqpeak2(iSub);
    end 
    
    if isnan(freqpeak) %only detect if freqpeak exits
        continue
    end

    %load data 
    load(strcat(dirScoring,scoringFiles(iSub).name));
    load(strcat(dirData,dataFiles(iSub).name));

    %detect spindle events 1.2Hz around peak 
    cfg = [];
    cfg.scoring          = scoring;
    cfg.stages           = {'N2', 'N3'}; % {'R'};
    cfg.channel          = data.label(contains(data.label,channel_list));
    cfg.centerfrequency  = freqpeak;
    cfg.mergewithin      = 0;
    cfg.leftofcenterfreq = WinLen;
    cfg.leftofcenterfreq = WinLen;
    [res_spindles_channel, res_spindles_event] = st_spindles(cfg, data);

    %add participant ID 
    res_spindles_channel.ID = data.ID;
    res_spindles_event.ID   = data.ID;

    %append participants
    res_spindles_channels{iSub} = res_spindles_channel;
    res_spindles_events{iSub} = res_spindles_event;
end

save(strcat(dirSaveSP,sp_type,'/Spindles_channels.mat'),'res_spindles_channels');
save(strcat(dirSaveSP,sp_type,'/Spindles_events.mat'),'res_spindles_events');

res_spindles_channels = res_spindles_channels(cell2mat(cellfun(@(x) ~isempty(x), res_spindles_channels,'UniformOutput',false)));


%summarize the spindle parameters across subjects 
coun = cellfun(@(x) x.table.count,res_spindles_channels,'UniformOutput',false);
spindles_out.count = vertcat(coun{:});
den = cellfun(@(x) x.table.density_per_minute,res_spindles_channels,'UniformOutput',false);
spindles_out.densities = vertcat(den{:});
freq = cellfun(@(x) x.table.mean_frequency_by_mean_pk_trgh_cnt_per_dur,res_spindles_channels,'UniformOutput',false);
spindles_out.frequencies = vertcat(freq{:});
dur = cellfun(@(x) x.table.mean_duration_seconds,res_spindles_channels,'UniformOutput',false);
spindles_out.durations = vertcat(dur{:});
amp = cellfun(@(x) x.table.mean_amplitude_trough2peak_potential,res_spindles_channels,'UniformOutput',false);
spindles_out.amplitudes = vertcat(amp{:});
chan = cellfun(@(x) x.table.channel,res_spindles_channels,'UniformOutput',false);
spindles_out.channels = vertcat(chan{:});


save(strcat(dirSaveSP,sp_type,'/Spindle_parameters.mat'),"spindles_out");

%compute one-way ANOVAs
params = fieldnames(spindles_out);
params = params(2:5);

for ii = 1:numel(params)
    [p,tbl,stats] = anova1(spindles_out.(params{ii}),spindles_out.channels,'off');
    save(strcat(dirSaveSP,sp_type,'/stats/',params{ii},'_pval'),"p")
    save(strcat(dirSaveSP,sp_type,'/stats/',params{ii},'_Ftable'),"tbl")
    [c,~,~,gnames] = multcompare(stats);
    save(strcat(dirSaveSP,sp_type,'/stats/',params{ii},'_followUp_tbl'),"c")
    save(strcat(dirSaveSP,sp_type,'/stats/',params{ii},'_followUp_label'),"gnames")
end 

%plot the results 
bar_graphs(strcat(dirSaveSP,sp_type,'/'),'Spindle_parameters',params,spindles_out,'Spindle');


end

