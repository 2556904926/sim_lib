function DisplayText = createDisplayDesign(DesignData)
% Utility function for display text of Design Object.

% Copyright 2013 The MathWorks, Inc.
DisplayText = [];
for ct = 1:length(DesignData)
    str = evalc('showBlockValue(DesignData(ct).BlockParam)');
    str = strsplit(str,'-----------------------------------');
    for ct2=1:length(str)
        str2 = strsplit(str{ct2},'Name:');
        aDisplayText{ct2}=str2{1};
    end
    DisplayText = [DisplayText,aDisplayText];
end

