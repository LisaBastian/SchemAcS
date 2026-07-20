function nfbSpindle_preproc_dataimport(iSub,iTime)

% ADHD-Sleep project (in collaboration with A. Prehn-Kristensen (UKSH Kiel))
% 
% preprocessing of data
% - data import
% - optional: upsampling to 256 Hz
% - sleep staging import
% - bad channel and artifact inspection
% - data export
%
% created by H.-V.V. Ngo
% last update: 23-01-17 by HVN
%


%% timekeeping
scrptSta = tic;


%% directories
switch getenv('Computername')
    case {'SOBAN00DLE-PC';'SOBAN00DLE-NB'}
        
        addpath('D:\GitHub\hvn_funs')

        dirData = 'D:\Box\myBox\projects\nfbSpindle\data_orig';
        dirSave = 'D:\Box\myBox\projects\nfbSpindle\data_ana';
        
        inMont = load('D:\Box\myBox\projects\nfbSpindle\eegMontage\nfbSpindle_mont.mat');
    otherwise
        addpath('C:\toolboxes\fieldtrip-20220216');
        addpath('C:\toolboxes\hvn_funs')

        dirData = 'C:\Users\hn23395\Box\myBox\projects\nfbSpindle\data_orig';
        dirSave = 'C:\Users\hn23395\Box\myBox\projects\nfbSpindle\data_ana';
        
        inMont = load('C:\Users\hn23395\Box\myBox\projects\nfbSpindle\eegMontage\nfbSpindle_mont.mat');
end



ft_defaults


%% general parameters
numSub  = 49;


%% subject list and selection
inSub       = cell(numSub,1);
inSub{1}    = '26_A_001';
inSub{2}    = '26_A_002';
inSub{3}    = '26_A_003';
inSub{4}    = '26_A_004';
inSub{5}    = '26_A_005';
inSub{6}    = '26_A_006';
inSub{7}    = '26_A_007';
inSub{8}    = '26_A_008';

inSub{9}    = '26_B_051';
inSub{10}   = '26_B_052';
inSub{11}   = '26_B_053';
inSub{12}   = '26_B_054';
inSub{13}   = '26_B_055';
inSub{14}   = '26_B_056';
inSub{15}   = '26_B_057';
inSub{16}   = '26_B_058';

inSub{17}   = '26_C_001'; 
inSub{18}   = '26_C_002';
inSub{19}   = '26_C_003';
inSub{20}   = '26_C_004';
inSub{21}   = '26_C_005';
inSub{22}   = '26_C_006';
inSub{23}   = '26_C_007';
inSub{24}   = '26_C_008';
inSub{25}   = '26_C_009';
inSub{26}   = '26_C_010';
inSub{27}   = '26_C_011';

inSub{28}   = '26_D_051';
inSub{29}   = '26_D_052';
inSub{30}   = '26_D_053';
inSub{31}   = '26_D_054';
inSub{32}   = '26_D_055';
inSub{33}   = '26_D_056';
inSub{34}   = '26_D_057';
inSub{35}   = '26_D_058';
inSub{36}   = '26_D_059';
inSub{37}   = '26_D_060';
inSub{38}   = '26_D_061';

inSub{39}   = '26_E_001';
inSub{40}   = '26_E_002';
inSub{41}   = '26_E_003';
inSub{42}   = '26_E_004';
inSub{43}   = '26_E_006';

inSub{44}   = '26_F_051';
inSub{45}   = '26_F_052';
inSub{46}   = '26_F_053';
inSub{47}   = '26_F_054';
inSub{48}   = '26_F_055';
inSub{49}   = '26_F_056';


%% check time point
switch iTime
    case 0
        postfix = '_baseline';
    case 1
        postfix = '_Stim_1';
    case 2
        postfix = '_Stim_2';
    otherwise
        error('no valid input!');
end


%% check for existing supplement
if exist(fullfile(dirSave,[inSub{iSub} postfix '-supplmt.mat']),'file')
    fprintf('.. load existing supplement\n');
    supplmt = load(fullfile(dirSave,[inSub{iSub} postfix '-supplmt.mat']));
    
    artfct  = supplmt.artfct;
    arousal = supplmt.arousal;
    bad_ch  = supplmt.bad_ch;
    
    clear supplmt
else
    artfct  = [];
    arousal = [];
    bad_ch  = [];
end


%% eeg data import
%.. load data
fprintf('.. load data\n');
tfg         = [];
tfg.channel = [inMont.lay.label; 'A1'; 'A2'];
tfg.dataset = fullfile(dirData,sprintf('%s%s.edf',inSub{iSub,1},postfix));
inData      = ft_preprocessing(tfg);

%.. filter data
fprintf('.. filter data\n');
tfg                     = [];
tfg.hpfilter            = 'yes';
tfg.hpfreq              = 0.3;
tfg.hpfiltord           = 3;
tfg.hpinstabilityfix    = 'reduce';
tfg.lpfilter            = 'yes';
tfg.lpfilttype          = 'fir';
tfg.lpfreq              = 35;
tfg.lpfiltord           = 3*fix(inData.fsample/tfg.lpfreq)+1;
tfg.lpinstabilityfix    = 'reduce';
inData                  = ft_preprocessing(tfg,inData);

%.. optional: upsampling to 256 Hz
if inData.fsample ~= 256
    tfg             = [];
    tfg.resamplefs  = 256;
    inData          = ft_resampledata(tfg,inData);
end

%.. remove unnecessary fields and add sampleinfo
inData.sampleinfo   = [1 size(inData.trial{1},2)];
inData              = rmfield(inData,{'cfg';'hdr'});


%% import sleep staging
inMrkr      = ft_read_event(fullfile(dirData,sprintf('%s%s_FT.vmrk',inSub{iSub,1},postfix)));
inStaging   = {inMrkr.value}';

%.. re-coding of sleep stages
tmpStaging = nan(numel(inStaging),1);
tmpStaging(ismember(inStaging,{' W'}),:)    = 0;
tmpStaging(ismember(inStaging,{' N1'}),:)   = 1;
tmpStaging(ismember(inStaging,{' N2'}),:)   = 2;
tmpStaging(ismember(inStaging,{' N3'}),:)   = 3;
tmpStaging(ismember(inStaging,{' N4'}),:)   = 4;
tmpStaging(ismember(inStaging,{' R'}),:)    = 5;
tmpStaging(ismember(inStaging,{' A'}),:)    = 7;
tmpStaging(ismember(inStaging,{' M'}),:)    = 8;

%.. create sleep staging vector
tfg             = [];
tfg.type        = 'Matlab';
tfg.hypnogram   = tmpStaging;
staging         = hvn_importHypnogram(tfg, inData.fsample, inData.sampleinfo(2));


%% inspect data
fprintf('.. inspect data\n');

%.. Prepare cfg
tfg         = [];
tfg.event   = struct;

idx     = 1;
iEpch   = 10 * inData.fsample;
while iEpch < inData.sampleinfo(1,2)
    if ismember(staging(1,iEpch),2:5)
        tfg.event(idx).type      = 'SlSt';
        tfg.event(idx).value     = num2str(staging(1,iEpch));
        tfg.event(idx).sample    = iEpch;
        tfg.event(idx).duration  = 1;
        tfg.event(idx).offset    = 0;

        idx = idx + 1;
    end
    
    iEpch = iEpch + (30 * inData.fsample);
end

%.. last preparations
tfg.blocksize                   = 30;
tfg.viewmode                    = 'vertical';
tfg.ylim                        = [-100 100];
tfg.artfctdef.arousal.artifact  = arousal;
tfg.artfctdef.visual.artifact   = artfct;
tfg.artfctdef.sleep.artifact    = [cell2mat({tfg.event(:).sample})' cell2mat({tfg.event(:).sample})'+5];

%.. inspect data
tfg = ft_databrowser(tfg, inData);

%.. save arousals and artifacts
arousal = tfg.artfctdef.arousal.artifact;
artfct  = tfg.artfctdef.visual.artifact;

%.. user input for bad channels
if ~isempty(bad_ch)
    fprintf('   previously identified bad channels: '); 
    for iCh = 1 : size(bad_ch)
        fprintf('%s ',bad_ch{iCh})
    end
    fprintf('\n');
end
bad_ch = input('Specify bad channels (leave empty for none!): ');


%% save results
fprintf('.. save data\n');

%.. eeg data
tfg             = [];
tfg.saveDir     = dirSave;
tfg.saveName    = inSub{iSub};
tfg.precision   = 'int16';
tfg.bitRes      = 0.5;
hvn_exportFTtoBP_eeg(tfg,inData)

%.. create and save supplement
supplmt         = [];
supplmt.fsample = inData.fsample;
supplmt.datalen = inData.sampleinfo(2);
supplmt.label   = inData.label;
supplmt.slpstg  = staging;
supplmt.bad_ch  = bad_ch;
supplmt.artfct  = artfct;
supplmt.arousal = arousal;

save(fullfile(dirSave,[inSub{iSub} postfix '-supplmt.mat']), '-struct', 'supplmt');


%% timekeeping
fprintf('running time: %.2f s\n', toc(scrptSta));
