function varargout = hvn_syncChanOrder(inChOrdr,varargin)

% 'hvn_syncChanOrder' sorts the channels of an arbitrary number of
% fieldtrip datasets according to a given order
%
% created by H.-V.V. Ngo
%

%% housekeeping
if nargin < 2
    error('there need to be at least two inputs');
end

%..check first input argument
if ~iscell(inChOrdr)
    error('first input must be a cell array with channel names');
end
    

%% prepare output
varargout = cell(numel(varargin),1);


%% loop through given datasets and re-order data
for iData = 1 : numel(varargin)
    if numel(inChOrdr) ~= numel(varargin{iData}.label)
        error('unequal number of channel between dataset %s and inChOrdr',iData);
    else
        varargout{iData} = varargin{iData};
        
        [~,tmpOrdr]             = ismember(inChOrdr,varargout{iData}.label);
        varargout{iData}.label  = varargout{iData}.label(tmpOrdr);
        varargout{iData}.trial  = cellfun(@(x) x(tmpOrdr,:),varargout{iData}.trial,'UniformOutput',0);
    end
end
