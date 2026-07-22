function ShortNameList = suppressSignalList(LongNameList,AllShortSignalNames)
% Suppress all signals in LONGNAMELIST to SHORTNAME appearing
% ALLSHORTSIGNALNAMES. All data are cell arrays.
%
% LongNameList = {'y(1)','y(2)','y(3)', ...
%                  'r(1)(1)','r(1)(2)','r(1)(3)',...
%                  'x(1)','x(2)','x(3)'};
% AllShortSignalNames = {'y','r','r(1)','z','v'};
% returns
% SignalList = {'y','r(1)'}
% and
% LongNameList = {'y(1)','y(2)','y(3)', ...
%                  'r(1)',...
%                  'x(1)','x(2)','x(3)'};
% AllShortSignalNames = {'y','r(1)','z','v'};
% returns
% SignalList = {'y','r(1)'}

% Copyright 2013 The MathWorks, Inc.

ShortNameList = cell(0,1);
for ct=1:length(AllShortSignalNames)
    Name = AllShortSignalNames{ct};
    ind = strmatch(Name,LongNameList,'exact');
    if ~isempty(ind) % exact match
        ShortNameList{end+1} = Name;
        LongNameList(ind)=[];
    else % multiple signal case
        indexes = strfind(LongNameList,[Name '(']);
        NonEmptyInd = find(cellfun(@(x) ~isempty(x)  && ((length(x)==1) && (x==1)),indexes),'1');
        for ct1=1:length(NonEmptyInd)
            TmpName = LongNameList{ct1}(length([Name '('])+1:end);
            if ~strcmp(TmpName(end),')')
                NonEmptyInd(ct1)=0;
            end            
        end
        LongNameList(NonEmptyInd)=[];
        if any(NonEmptyInd)
            ShortNameList{end+1} = Name;
        end
    end
end