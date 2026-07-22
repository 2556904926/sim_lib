function [wc,Reqs,Options] = looptuneParser(varargin)
% Input parser for LOOPTUNE.

%   Copyright 2003-2012 The MathWorks, Inc.

% Look for crossover band spec
if nargin>0 && isnumeric(varargin{1})
   wc = varargin{1};  varargin = varargin(2:end);
else
   wc = [];
end

% Get options
iopt = find(cellfun(@(x) isa(x,'rctoptions.looptune'),varargin),1);
if isempty(iopt)
   Options = rctoptions.looptune();
else
   Options = varargin{iopt};  varargin(:,iopt) = [];
end

% Validate additional requirements
Reqs = varargin;
for ct=1:numel(Reqs)
   r = Reqs{ct};
   if ~isa(r,'TuningGoal.Generic')
      error(message('Control:tuning:looptune7',class(r)))
   else
      Reqs{ct} = r(:);
   end
end
Reqs = cat(1,Reqs{:});
