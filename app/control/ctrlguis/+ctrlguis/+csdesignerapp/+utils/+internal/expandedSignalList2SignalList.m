function ShortNameList = expandedSignalList2SignalList(LongNameList)
% Suppress all signals in LONGNAMELIST to SHORTNAMELIST. All data are cell arrays.
%
% LongNameList = {'y(1)','y(2)','y(3)', ...
%                  'r(1)','r(2)','r(3)',...
%                  'x(1)','x(2)','x(3)'};
% AllShortSignalNames = {'y','r','x'};
% returns
% SignalList = {'y','r','x'}

% Copyright 2013 The MathWorks, Inc.

ShortNameList = cell(0,1);
while ~isempty(LongNameList)
    Name = LongNameList{1};
    
    index = max(strfind(Name,'('));
    if isempty(index) % single signal
        LongNameList = setdiff(LongNameList,Name);
        ShortNameList{end+1} = Name;
    else % there is paranthesis in name
        NameRoot = Name(1:index-1);
        indexes = strfind(LongNameList,[NameRoot '(']);
        NonEmptyInd = find(cellfun(@(x) ~isempty(x)  && ((length(x)==1) && (x==1)),indexes),'1');
        for ct1=1:length(NonEmptyInd)
            TmpName = LongNameList{ct1}(length([NameRoot '('])+1:end);
            if ~strcmp(TmpName(end),')')
                NonEmptyInd(ct1)=0;
            end
        end
        LongNameList(NonEmptyInd)=[];
        if any(NonEmptyInd)
            ShortNameList{end+1} = NameRoot;
        end                
    end
end


