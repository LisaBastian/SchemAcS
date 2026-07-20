function SM_SODetection(dirScoring,dirData,dirSave,fu_SO,fl_SO,channel_list)

scoringFiles = loadFile(dirScoring,'SchemAcS','start');
dataFiles = loadFile(dirData,'.mat','end');
dataFiles = dataFiles(~startsWith({dataFiles.name},'.'));

res_slowwaves_channels = cell(1,numel(scoringFiles));
res_slowwaves_events = cell(1,numel(scoringFiles));

for iSub = 1:length(dataFiles)
    load(strcat(dirScoring,scoringFiles(iSub).name))
    load(strcat(dirData,dataFiles(iSub).name));
    
    cfg = [];
    cfg.scoring          = scoring;
    cfg.stages           = {'N2', 'N3'}; % {'R'};
    cfg.channel          = data.label(contains(data.label,channel_list));
    %cfg.minfreq          = fl_SO;
    %cfg.maxfreq          = fu_SO;
    [res_slowwaves_channel, res_slowwaves_event] = st_slowwaves(cfg, data);
    
    %add subject ID 
    res_slowwaves_channel.ID = data.ID;
    res_slowwaves_event.ID   = data.ID;

    %append participants
    res_slowwaves_channels{iSub} = res_slowwaves_channel;
    res_slowwaves_events{iSub} = res_slowwaves_event;
end

save(strcat(dirSave,'SO_channels.mat'),'res_slowwaves_channels');
save(strcat(dirSave,'SO_events.mat'),'res_slowwaves_events');

%summarize the SO parameters across subjects 
den = cellfun(@(x) x.table.density_per_minute,res_slowwaves_channels,'UniformOutput',false);
SO_out.densities = vertcat(den{:});
freq = cellfun(@(x) x.table.mean_frequency_by_duration,res_slowwaves_channels,'UniformOutput',false);
SO_out.frequencies = vertcat(freq{:});
dur = cellfun(@(x) x.table.mean_duration_seconds,res_slowwaves_channels,'UniformOutput',false);
SO_out.durations = vertcat(dur{:});
amp = cellfun(@(x) x.table.mean_amplitude_peak2trough_potential,res_slowwaves_channels,'UniformOutput',false);
SO_out.amplitudes = vertcat(amp{:});
slo = cellfun(@(x) x.table.mean_slope_to_trough_min_potential_per_second,res_slowwaves_channels,'UniformOutput',false);
SO_out.slopes = vertcat(slo{:});
chan = cellfun(@(x) x.table.channel,res_slowwaves_channels,'UniformOutput',false);
SO_out.channels = vertcat(chan{:});


save(strcat(dirSave,'SO_parameters.mat'),'SO_out');

params = fieldnames(SO_out);
params = params(1:4);

for ii = 1:numel(params)
    [p,tbl,stats] = anova1(SO_out.(params{ii}),SO_out.channels,'off');
    save(strcat(dirSave,'stats/',params{ii},'_pval'),"p")
    save(strcat(dirSave,'stats/',params{ii},'_Ftable'),"tbl")
    [c,~,~,gnames] = multcompare(stats);
    save(strcat(dirSave,'stats/',params{ii},'_followUp_tbl'),"c")
    save(strcat(dirSave,'stats/',params{ii},'_followUp_label'),"gnames")
end 


%plot the results 
bar_graphs(dirSave,'SO_parameters',params,SO_out,'SO');


