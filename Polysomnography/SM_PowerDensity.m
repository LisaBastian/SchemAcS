function SM_PowerDensity(dirScoring,dirData,dirSave,channel_list)

scoringFiles = loadFile(dirScoring,'SchemAcS','start');

data_preproc = dir(dirData);
data_preproc = data_preproc(~startsWith({data_preproc.name},'.'));

for iSub = 1:numel(scoringFiles)
    clear scoring data 
    load(strcat(dirScoring,scoringFiles(iSub).name));
    load(strcat(dirData,data_preproc(iSub).name))

    cfg = [];
    cfg.scoring        = scoring;
    cfg.stages         = {'N2','N3'};
    cfg.channel        = data.label(contains(data.label,channel_list));
    cfg.segmentlength  = 5;
    cfg.segmentoverlap = 0.1;
    
    cfg.fooof          = 'yes'; % this will also put the fooofed signals in the res_power_bin
    %cfg.freq_range     = [0.5 20]; % min_freq max_freq
    cfg.max_peaks      = 3;
    cfg.peak_threshold = 1;
    cfg.aperiodic_mode = 'knee'; %knee or fixed
    cfg.peak_type      = 'best'; %cauchy or gaussian or best

    [res_power_bin, res_power_band] = st_power(cfg, data);
    t_power = table(res_power_bin.table.channel,res_power_bin.table.freq,res_power_bin.table.mean_power_over_segments,...
        'VariableNames',{'channel','freqs','powers'});
    writetable(t_power,strcat(dirSave,extractBefore(scoringFiles(iSub).name,'_scoring'),'_fooof_export.csv'),'Delimiter',',','QuoteStrings','all');
    
    save(strcat(dirSave,extractBefore(scoringFiles(iSub).name,'_scoring'),'-freqSpectrum.mat'),'res_power_bin')
    save(strcat(dirSave,extractBefore(scoringFiles(iSub).name,'_scoring'),'-freqBands.mat'),'res_power_band')

    %plot the results
    figure(iSub)

    labels = data.label(contains(data.label,channel_list));
    hold on
    for i = 1:length(data.label(contains(data.label,channel_list)))
        chan = labels{i};
        freq = res_power_bin.table.freq(strcmp(res_power_bin.table.channel,chan));
        pow  = log(res_power_bin.table.mean_power_over_segments(strcmp(res_power_bin.table.channel,chan)));
        plot(freq(20:100), pow(20:100),'LineWidth',2);
        %plot(res_power_bin.table.freq(strcmp(res_power_bin.table.channel,chan)),...
        %    log(res_power_bin.table.mean_powerDensity_over_segments_fooofed_aperiodic_fit(strcmp(res_power_bin.table.channel,chan))))
        title(extractBefore(scoringFiles(iSub).name,'_scoring'))

    end
    hold off

    legend(labels)
    saveas(gcf,strcat(dirSave,'plots/',scoringFiles(iSub).name,'_freqspec.pdf'))
end

%export the data
%cfg = [];

%fg.prefix = 'example';
%cfg.infix  = subject.name;
%cfg.postfix = '';
%filelist_res_power = st_write_res(cfg, res_power_bin, res_power_band, res_power_fooof); 