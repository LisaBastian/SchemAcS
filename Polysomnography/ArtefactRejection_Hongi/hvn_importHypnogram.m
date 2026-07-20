%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Slythm_Import_Hypnogram
% by H.-V.V Ngo
%
% Imports sleep scoring into an existing Fieldtrip data structure
% - Requires Fieldtrip format
% - Requires hypnogram as text (as provided by SchlafAus)
%
% Usage: outScoring = Slythm_Import_Hypnogram(cfg, inData)
%
% Configuration parameters
% cfg.epochLen  = scalar representing the length of a scoring epoch in s, default 30 s
% cfg.hypnogram = Text file containing sleep staging
% cfg.type      = string specifing the hypnogram layout:
%                 'SchlafAus', 'REMLogic', 'plain', 'Matlab', 'Kiel'
%
% last update 18-11-24 by HVN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function outScoring = hvn_importHypnogram(cfg, inFsample, inDatalen)

%% Bookkeeping
%--- Check numbers of arguments
if nargin ~= 3
    error('Wrong number of arguments');
end

%--- Check if scoring window is given, if not set to 30 s
if ~isfield(cfg,'epochLen')
    cfg.epochLen = 30;
end

%--- Check if hypnogram file is given, if not throw error
if ~isfield(cfg,'hypnogram')
    error('Hypnogram required');
end

%--- Check if hypnogram type is given, if not set to 'SchlafAus'
if ~isfield(cfg,'type')
    cfg.type = 'SchlafAus';
end


%% Prepare data depending on type
switch cfg.type
    case 'SchlafAus' % Combine sleep staging and arousal information, e.g. S1 + MA = 11 and S3 + MA = 13
        inHypno     = dlmread(cfg.hypnogram);
        tmpScoring  = inHypno(:,1) + (inHypno(:,2) * 10);
        
        clear inHypno
    case 'REMLogic'
        inHypno     = readtable(cfg.hypnogram,'HeaderLines', 18,'ReadVariableNames', 0);           %% Read Event file and skip first 18 lines
        tmpHypno    = table2cell(inHypno(:,1));                             %% Extract first column
    
        %--- Re-code scoring
        tmpScoring = nan(numel(tmpHypno),1);
        tmpScoring(ismember(tmpHypno,{'W'}),:)  = 0;
        tmpScoring(ismember(tmpHypno,{'N1'}),:) = 1;
        tmpScoring(ismember(tmpHypno,{'N2'}),:) = 2;
        tmpScoring(ismember(tmpHypno,{'N3'}),:) = 3;
        tmpScoring(ismember(tmpHypno,{'R'}),:)  = 4;

        clear inHypno tmpHypno
        case 'REMLogic2'
        inHypno     = readtable(cfg.hypnogram,'HeaderLines', 14,'ReadVariableNames', 0);           %% Read Event file and skip first 18 lines
        tmpHypno    = table2cell(inHypno(:,2));                             %% Extract first column
    
        %--- Re-code scoring
        tmpScoring = nan(numel(tmpHypno),1);
        tmpScoring(ismember(tmpHypno,{'W'}),:)  = 0;
        tmpScoring(ismember(tmpHypno,{'N1'}),:) = 1;
        tmpScoring(ismember(tmpHypno,{'N2'}),:) = 2;
        tmpScoring(ismember(tmpHypno,{'N3'}),:) = 3;
        tmpScoring(ismember(tmpHypno,{'R'}),:)  = 4;

        clear inHypno tmpHypno
    case 'plain'
        inHypno     = dlmread(cfg.hypnogram);
        tmpScoring  = inHypno(:,1);
        
        clear inHypno
    case 'Matlab'
        tmpScoring = cfg.hypnogram;
    case 'Kiel'
        inHypno     = readtable(cfg.hypnogram,'HeaderLines', 7,'Delimiter',';','ReadVariableNames',0);    %% Read scoring and skip first 7 lines
        tmpHypno  = table2cell(inHypno(:,2));
        
        tmpScoring = nan(numel(tmpHypno),1);
        tmpScoring(ismember(tmpHypno,{'Wach'}),:)   = 0;
        tmpScoring(ismember(tmpHypno,{'N1'}),:)     = 1;
        tmpScoring(ismember(tmpHypno,{'N2'}),:)     = 2;
        tmpScoring(ismember(tmpHypno,{'N3'}),:)     = 3;
        tmpScoring(ismember(tmpHypno,{'Rem'}),:)    = 4;
end


%% Up-sample sleep staging to the sampling rate of inData EEG taking into account the scoring epoch length
tmpEpochLen = round(cfg.epochLen * inFsample);
tmpScoring = repmat(tmpScoring,1,tmpEpochLen)';
tmpScoring = reshape(tmpScoring,1,numel(tmpScoring));

outScoring = zeros(1,inDatalen);
    
if inDatalen > numel(tmpScoring)
    outScoring(1:numel(tmpScoring)) = tmpScoring(1:numel(tmpScoring));
else
    outScoring(1:inDatalen) = tmpScoring(1:inDatalen);
end

clear tmpScoring tmpEpochLen

end % of function
