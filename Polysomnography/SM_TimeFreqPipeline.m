function SM_TimeFreqPipeline(dirData,dirScoring,dirSO,dirSave, ...
    channs,triallength,low_freq,high_freq,freq_step,faslt_baseline)

%load data files
load(strcat(dirSO,'SO_events.mat'))
dataFiles = loadFile(dirData,'.mat','end');
dataFiles = dataFiles(~startsWith({dataFiles.name},'.'));
scoringFiles = loadFile(dirScoring,'SchemAcS','start');
dataSOevents = cell(1,numel(res_slowwaves_events));
dataEventmatch = cell(1,numel(res_slowwaves_events));


for iSub = 1:numel(res_slowwaves_events)
    clear TF_params

    %load data
    load(strcat(dirData,dataFiles(iSub).name));
    load(strcat(dirScoring,scoringFiles(iSub).name));

    res_SO = res_slowwaves_events{iSub};
    channels =data.label(ismember(data.label,channs));

    for chan = 1:numel(channels)
        channel = channels{chan};

        %get SO troughs for N2 & N3
        slowwave_troughs = res_SO.table.seconds_trough_max(strcmp(res_SO.table.channel,channel));
        
        stage_channel = find(strcmp(res_SO.table.channel,channel));
        N2_SO_idx = find(ismember(stage_channel,(find(strcmp(res_SO.table.stage,{'N2'}))))); %find how many SO occured in each sleep stage to match non-SO trials
        num_SO_N2 = numel(N2_SO_idx);
        N3_SO_idx = find(ismember(stage_channel,(find(strcmp(res_SO.table.stage,{'N3'})))));
        num_SO_N3 = numel(N3_SO_idx);
        
        %define trials around SO troughs for N2 & N3
        beg_SOtrial_N2  = (slowwave_troughs(N2_SO_idx,:)*data.fsample)-(triallength*data.fsample/2);
        end_SOtrial_N2  = (slowwave_troughs(N2_SO_idx,:)*data.fsample)+(triallength*data.fsample/2);
        length_SOs_N2 = [(beg_SOtrial_N2+1) end_SOtrial_N2]; %find the trials of the SOs in stage N2
        SOlength_row_N2 = (reshape(length_SOs_N2',[],1))';

        beg_SOtrial_N3  = (slowwave_troughs(N3_SO_idx,:)*data.fsample)-(triallength*data.fsample/2);
        end_SOtrial_N3  = (slowwave_troughs(N3_SO_idx,:)*data.fsample)+(triallength*data.fsample/2);
        length_SOs_N3   = [beg_SOtrial_N3 end_SOtrial_N3]; %find the trials of the SOs in stage N3
        SOlength_row_N3 = (reshape(length_SOs_N3',[],1))';

        %START the matching 
        epochlength_samples = scoring.epochlength*data.fsample;
        epochs_N2    = find(strcmp(scoring.epochs, 'N2'));
        epochs_N3    = find(strcmp(scoring.epochs, 'N3'));

        %do not consider excluded epochs
        exclude = find(scoring.excluded);
        excl_idx_N2 = find(ismember(epochs_N2,exclude));
        excl_idx_N3 = find(ismember(epochs_N3,exclude));
        epochs_N2(excl_idx_N2) = [];
        epochs_N3(excl_idx_N3) =[];


        %draw matches for sleep period N2
        concat_N2     = sort([((epochs_N2(:)-1)*epochlength_samples+1)' SOlength_row_N2 ((epochs_N2(:)+0)*epochlength_samples)']);
        intervals_N2  = [find(diff(concat_N2) > (data.fsample*triallength))' (find(diff(concat_N2) > (data.fsample*triallength))+1)'];%exlcude the periods with SO in it
        IOI_N2        = concat_N2(intervals_N2);
        short_IOI_N2  = [(IOI_N2(:,1)+(data.fsample*triallength/2)) IOI_N2(:,2)-(data.fsample*triallength/2)]; % make sure that that the period does not overlap

        trials_N2 = [];
        perc_trials_N2 = round((num_SO_N2./(num_SO_N2+num_SO_N3)*100),0);
        
        for ii = 1:perc_trials_N2
            row   = randi(length(IOI_N2));
            interv = short_IOI_N2(row,1):short_IOI_N2(row,2);
            int_idx   = randi(numel(interv));
            int = interv(int_idx);
            trials_N2(ii,:) = int;
        end

        %draw matches for sleep periods N3
        concat_N3 = sort([((epochs_N3(:)-1)*epochlength_samples+1)' SOlength_row_N3 ((epochs_N3(:)+0)*epochlength_samples)']); %beginning and end for detection period
        intervals_N3 = [find(diff(concat_N3) > (data.fsample*triallength))' (find(diff(concat_N3) > (data.fsample*triallength))+1)']; %exclude the periods with SO in it
        IOI_N3 = concat_N3(intervals_N3);
        short_IOI_N3 = [(IOI_N3(:,1)+(data.fsample*triallength/2)) IOI_N3(:,2)-(data.fsample*triallength/2)]; %WHY ARE THEY ONLY HALF THE LENGTH???

        trials_N3 = [];
        perc_trials_N3 = round((num_SO_N3./(num_SO_N2+num_SO_N3)*100),0);

        for ii = 1:perc_trials_N3
            row   = randi(length(IOI_N3));
            interv = short_IOI_N3(row,1):short_IOI_N3(row,2);
            int_idx   = randi(numel(interv));
            int = interv(int_idx);
            trials_N3(ii,:) = int;
        end

        Trialmatch_sample = [trials_N2; trials_N3];
        Trialmatch        = Trialmatch_sample./data.fsample;

        
        %take 100 random SO troughs and define trials for SO troughs
        idx = randperm(length(slowwave_troughs),100)';
        cfg = [];
        cfg.seconds = slowwave_troughs(idx);
        cfg.bounds = [-(triallength/2) (triallength/2)]; % 6 seconds 
        data_SOevents = ft_redefinetrial(cfg, data);


        % define a trial for matched events 
        cfg = [];
        cfg.seconds = Trialmatch;
        cfg.bounds = [-(triallength/2) (triallength/2)]; % 6 seconds 
        data_eventmatch = ft_redefinetrial(cfg, data);

        dataSOevents{iSub} = data_SOevents;
        dataEventmatch{iSub} = data_eventmatch;


        %create Time-Freq Spectra with Superlets (faslt)
        SLresultsSO = zeros(length(data_SOevents.trial),1,...
            length(low_freq:freq_step:high_freq),(data.fsample*triallength)+1);

        chan_idx = find(ismember(data.label,channel));
        for ss = 1:length(data_SOevents.trial)
            trial = data_SOevents.trial{ss}(chan_idx,:); %for channel Fz, Cz = 5
            SLresultsSO(ss,1,:,:) = faslt(trial, data.fsample, low_freq:freq_step:high_freq, 7, [5 15], 0);
        end

        SLresultsMatch = zeros(length(data_eventmatch.trial),1,...
            length(low_freq:freq_step:high_freq),(data.fsample*triallength)+1); 

        for tt = 1:length(data_eventmatch.trial)
            trial = data_eventmatch.trial{tt}(chan_idx,:); %for channel Fz, Cz = 5
            SLresultsMatch(tt,1,:,:) = faslt(trial, data.fsample, low_freq:freq_step:high_freq, 7, [5 15], 0);
        end

        %make a baseline correction 
        SOevent_TF.label = {channel};
        SOevent_TF.freq = low_freq:freq_step:high_freq;
        SOevent_TF.time = -(triallength/2):(1/data.fsample):(triallength/2);
        SOevent_TF.powspctrm = SLresultsSO;
        SOevent_TF.dimord = 'rpt_chan_freq_time';

        Matchevent_TF.label = {channel};
        Matchevent_TF.freq = low_freq:freq_step:high_freq;
        Matchevent_TF.time = -(triallength/2):(1/data.fsample):(triallength/2);
        Matchevent_TF.powspctrm = SLresultsMatch;
        Matchevent_TF.dimord = 'rpt_chan_freq_time';

        cfg.baseline       = faslt_baseline; %[-1.5 1.5]; 
        cfg.baselinetype   = 'relchange';
        SOevent_freq       = ft_freqbaseline(cfg,SOevent_TF);
        Matchevent_freq    = ft_freqbaseline(cfg,Matchevent_TF);
        
        %cut power around 1.2s of SO trough

        SOevent_freq.powspctrm     = squeeze(SOevent_freq.powspctrm(:,:,:,round(1.8*data.fsample):floor(4.2*data.fsample)));
        SOevent_freq.time = SOevent_freq.time(:,round(1.8*data.fsample):round(4.2*data.fsample));
        Matchevent_freq.powspctrm = squeeze(Matchevent_freq.powspctrm(:,:,:,round(1.8*data.fsample):floor(4.2*data.fsample)));
        Matchevent_freq.time = Matchevent_freq.time(:,round(1.8*data.fsample):round(4.2*data.fsample));

        %save SO and match events for plotting     
        %save(strcat(dirSave,'SO_TF_',data.ID{1}),'SOevent_freq')
        %save(strcat(dirSave,'Match_TF_',data.ID{1}),'Matchevent_freq')

        %plot the results for each subject
        xlim = [-1.2 1.2];
        ylim = [low_freq high_freq];
        times2save = -1.2:.002:1.2;%1201 samples
        frex = linspace(low_freq,high_freq,((high_freq-low_freq)/freq_step)+1); %57 samples
        
        figure(iSub)
        imagesc(times2save,frex,squeeze(mean(SOevent_freq.powspctrm,1)))
        colorbar('eastoutside')
        set(gca,'YDir','normal')
        xlabel('Time (s) from SO Trough')
        ylabel('Frequency (Hz)');
        title(strcat('SO TF Plot',data.ID{1}))
        saveas(gcf,strcat(dirSave,'figures/SO_TF_Plot_',data.ID{1},'_',channel,'.pdf'))

        figure(iSub+numel(res_slowwaves_events))
        imagesc(times2save,frex,squeeze(mean(Matchevent_freq.powspctrm,1)))
        colorbar('eastoutside')
        set(gca,'YDir','normal')
        xlabel('Time (s) from SO Trough')
        ylabel('Frequency (Hz)');
        title(strcat('MATCH TF Plot',data.ID{1}))
        saveas(gcf,strcat(dirSave,'figures/Match_TF_Plot_',data.ID{1},'_',channel,'.pdf'))
        
        %create T-maps
        for jj = 1:size(SOevent_freq.powspctrm,2)
            for kk = 1:size(SOevent_freq.powspctrm,3)
                [~,~,~,stats] = ttest2(SOevent_freq.powspctrm(:,jj,kk),Matchevent_freq.powspctrm(:,jj,kk));
                tvalues(:,jj,kk) = stats.tstat;
            end
        end


        %append to SO TF structure 
        Tmap = SOevent_freq;
        Tmap.powspctrm = tvalues; 
        Tmap.dimord = ('chan_freq_time');
        

        %append to TF structure 
        TF_params.SO_data{chan}    = SOevent_freq.powspctrm;
        TF_params.Match_data{chan} = Matchevent_freq.powspctrm;
        TF_params.Tmaps{chan}      = squeeze(Tmap);
        

        %close all
        figure(iSub)
        imagesc(times2save,frex,squeeze(Tmap.powspctrm))
        colorbar('eastoutside')
        set(gca,'YDir','normal')
        xlabel('Time (s) from SO Trough')
        ylabel('Frequency (Hz)'); 
        title(strcat('TF Plot',extractBefore(dataFiles(iSub).name,'-')))
        %saveas(gcf,strcat(dirSave,'figures/TF_Plot_',extractBefore(dataFiles(iSub).name,'-'),'_',channel,'.pdf'))


                       
    end

    TF_params.ID = data.ID;
    save(strcat(dirSave,'TF_Parameters_',data.ID{1}),'TF_params','-v7.3')

end
end 