 %%% ##### project:
% 
% Script to calculate power spectra of sleep EEG data with olfactory
% cueing. Analysis is performed on 4-min ON and OFF cueing intervals.
% 
% Created by H.V.-V. Ngo, modified by K.M. Sobania

clear


%% timekeeping
scrptSta = tic;


%% Directories etc.
switch getenv('Computername')
    case {'SOBAN00DLE-NB';'SOBAN00DLE-PC'} % Hongi Laptop or home-pc
        addpath('D:\GitHub\hvn_funs');
    
        dirData = 'D:\GoogleDrive\work_uzl\tVNSCogn\data\eegOrig';
        dirSupp = 'D:\GoogleDrive\work_uzl\tVNSCogn\data\supplmt';
        dirSave = 'D:\GoogleDrive\work_uzl\tVNSCogn\results\spctrlpwr';
        
        filMont = 'D:\GitHub\tVNSCogn\eegMontage\tVNSCogn_mont.mat';
    
%     case 'IPSY-PC002' % hongi office-pc
%         addpath('C:\GitHub\hvn_funs');
%         addpath('C:\work\fieldtrip-20220617');
% 
%         dirData = 'C:\work\tmr\data';
%         dirSave = 'C:\work\tmr\results\spectrm_v2';
% 
%         filMont = 'C:\work\smh_hdeeg_mont\stf_hdeeg_mont2.mat';
end

ft_defaults

svName = '_spctrm_nrem';


%% prepare montage
inMont  = load(filMont);


%% fundamental parameters
numSub  = 23;       % number of subjects
numCh   = 27;       % number of channels

fsample = 500;


%% Subjects files
inSub       = cell(numSub,2);
inSub(1,:)    = {'tVNSCogn_s01',1};
inSub(2,:)    = {'tVNSCogn_s02',2};
inSub(3,:)    = {'tVNSCogn_s03',3};
inSub(4,:)    = {'tVNSCogn_s04',3};
inSub(5,:)    = {'tVNSCogn_s06',2};
inSub(6,:)    = {'tVNSCogn_s07',3};
inSub(7,:)    = {'tVNSCogn_s08',3};
inSub(8,:)    = {'tVNSCogn_s09',1};
inSub(9,:)    = {'tVNSCogn_s10',2}; 
inSub(10,:)   = {'tVNSCogn_s11',1};
inSub(11,:)   = {'tVNSCogn_s12',2};
inSub(12,:)   = {'tVNSCogn_s14',2};
inSub(13,:)   = {'tVNSCogn_s15',3};
inSub(14,:)   = {'tVNSCogn_s16',1};
inSub(15,:)   = {'tVNSCogn_s17',2};
inSub(16,:)   = {'tVNSCogn_s18',3};
inSub(17,:)   = {'tVNSCogn_s19',1};
inSub(18,:)   = {'tVNSCogn_s20',2};
inSub(19,:)   = {'tVNSCogn_s22',1};
inSub(20,:)   = {'tVNSCogn_s23',2};
inSub(21,:)   = {'tVNSCogn_s24',3};
inSub(22,:)   = {'tVNSCogn_s25',1};
inSub(23,:)   = {'tVNSCogn_s26',2};


%% result structure
out = [];

%.. a few general definitions
out.def.label   = ft_channelselection({'all'; '-TP*'},inMont.lay.label);
out.def.stage   = {'nrem'};

%.. dimensions of the results
out.dim.spctrm  = 'channel x frequency';
out.dim.mixed   = 'channel x frequency';
out.dim.frctl   = 'channel x frequency';

%.. central analysis parameters
out.param.method        = 'usual';                       % usual | irasa
out.param.stage         = [2 3];                        % stages n2 & n3
out.param.fftlen        = 8.192;                        % fft segment length (in s)
out.param.fftoverlap    = 0.5;                          % overlap of fft segments

out.freq = 1/out.param.fftlen: 1/out.param.fftlen : 30;     numFreq = numel(out.freq);     % frequency vector


%% Main loops
for iSub = 1 : numSub
    fprintf('ANALYSE sub %d\n',iSub);
    
    %.. save condition
    out.cond = inSub{iSub,2};
    
    %.. initiation of variables for results
    out.spctrm = nan(numCh,numFreq);   % individual oscillatory spectrum
    
    if strcmp(out.param.method,'irasa')
        out.mixed = nan(numCh,numFreq);   % individual oscillatory spectrum
        out.frctl = nan(numCh,numFreq);   % individual oscillatory spectrum
    end
    
    
    %% load supplmentary data
    inSupp  = load(fullfile(dirSupp,[inSub{iSub,1} '-supplmt.mat']));    %% supplement

    staging = inSupp.staging;
    artfct  = vertcat(inSupp.slp_arousal,inSupp.slp_artfct);
    bad_ch  = inSupp.bad_ch.sleep;
    ch_ref  = inSupp.ch_ref;
    datalen = inSupp.datalen;
    
    clear inSupp

    
    %% load data
    %.. eeg
    tfg         = [];
    tfg.dataset = fullfile(dirData,[inSub{iSub,1} '_sleep.vhdr']);
    tfg.channel = {'all'; '-EMG'; '-O*'; '-IO'};
    inData      = ft_preprocessing(tfg);

    %.. filtering
    for iCh = 1 : numCh
        fprintf('.');
        
        tmpFilt                 = ft_preproc_highpassfilter(inData.trial{1}(iCh,:),fsample,0.3,3,'but','twopass','reduce');
        tmpFilt                 = ft_preproc_lowpassfilter(tmpFilt,fsample,40,3*fix(fsample/40)+1,'fir','twopass');
        inData.trial{1}(iCh,:)  = ft_preproc_bandstopfilter(tmpFilt,fsample,[48 52]);
        
        clear tmp_filt
    end
    fprintf('\n');
    
%     %.. channel interpolation
%     if ~isempty(bad_ch)
%         tfg             = [];
%         tfg.method      = 'spline';
%         tfg.badchannel  = bad_ch;
%         tfg.neighbours  = inMont.neighbours;
%         tfg.elec        = inMont.elec;
%         tfg.senstype    = 'eeg';
%         inData          = ft_channelrepair(tfg,inData);
%     end
    
%     %.. re-referencing
%     tfg             = [];
%     tfg.reref       = 'yes';
%     tfg.refchannel  = ch_ref;
%     inData          = ft_preprocessing(tfg,inData);
%         
%     %.. remove mastoids
%     tfg             = [];
%     tfg.channel     = {'all'; '-TP*'};
%     inData          = ft_preprocessing(tfg,inData);
    
    %.. sort channels
    inData = hvn_syncChanOrder(ft_channelselection({'all'; '-TP*'},inMont.lay.label),inData);

        
    %% create sleep filter
    slpfltr = all([ismember(staging,out.param.stage); ~hvn_createBnrySignal(artfct,datalen)]);
        

    %% prepare first coarse-grain segmentation
    slpbout = hvn_extrctBnryBouts(slpfltr);

    tfg             = [];
    tfg.minlength   = out.param.fftlen;
    tfg.trl         = [slpbout(:,1), slpbout(:,2), zeros(size(slpbout,1),1)];

    clear slpbout

    if ~isempty(tfg.trl) && any((tfg.trl(:,2)-tfg.trl(:,1)) / inData.fsample >= tfg.minlength)

        %.. perform coarse-grain segmentation
        fftData = ft_redefinetrial(tfg,inData);

        %.. further segmentation in fine-grained segments
        tfg         = [];
        tfg.length  = out.param.fftlen;
        tfg.overlap = out.param.fftoverlap;
        fftData     = ft_redefinetrial(tfg,fftData);
        
        out.dof = size(fftData.sampleinfo,1);


        %% main spectral analysis
        switch out.param.method
            case 'usual'
                tfg         = [];
                tfg.method  = 'mtmfft';
                tfg.output  = 'pow';
                tfg.foi     = out.freq;
                tfg.taper   = 'hanning';
                tfg.pad     = 'nextpow2';
                fftRes      = ft_freqanalysis(tfg,fftData);

                out.spctrm(iCond,iPhase,:,:) = fftRes.powspctrm;
%             case 'irasa'
%                 tfg         = [];
%                 tfg.method  = 'irasa';
%                 tfg.output  = 'original';
%                 tfg.foi     = out.freq;
%                 tfg.taper   = 'hanning';
%                 tfg.pad     = 'nextpow2';
%                 fftRes      = ft_freqanalysis(tfg,fftData);
% 
%                 out.mixed(:,:) = fftRes.powspctrm;
% 
%                 tfg         = [];
%                 tfg.method  = 'irasa';
%                 tfg.output  = 'fractal';
%                 tfg.foi     = out.freq;
%                 tfg.taper   = 'hanning';
%                 tfg.pad     = 'nextpow2';
%                 fftRes      = ft_freqanalysis(tfg,fftData);
% 
%                 out.frctl(:,:)   = fftRes.powspctrm;
%                 out.spctrm(:,:)  = squeeze(out.mixed-out.frctl);
        end

        clear fftData fftRes

    end
    
    
    %% save individual results
    save(fullfile(dirSave,[inSub{iSub,1} svName '.mat']),'-struct','out');
    
end     %% iSub


%% timekeeping
fprintf('this shit took %.2f s\n', toc(scrptSta));
