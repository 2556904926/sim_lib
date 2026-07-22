function [SignalList,IsSingleSignal] = expandSignalList(SignalName,AllSignalList)
% Finds all signals with SIGNALNAME in ALLSIGNALLIST.
% 
% SignalName = 'Signal2'
% SignalList = {'Signal1','Signal2(1)','Signal2(2)','Signal2(3)'}
% returns
% List = {'Signal2(1)','Signal2(2)','Signal2(3)'}
% % SignalName = 'Signal1'
% returns 
% List = {'Signal1'}

% Copyright 2013 The MathWorks, Inc.

if any(cellfun(@(x) strcmp(x,SignalName),AllSignalList)) % exact match: single signal
    IsSingleSignal = true;
    SignalList = SignalName;
else
    IsSingleSignal = false;
    tmp = strfind(AllSignalList,[SignalName '(']);
    idx = cellfun(@(x) ~isempty(x) && ((length(x)==1) && (x==1)),tmp,'UniformOutput',false);
    SignalList = AllSignalList([idx{:}]');
end


