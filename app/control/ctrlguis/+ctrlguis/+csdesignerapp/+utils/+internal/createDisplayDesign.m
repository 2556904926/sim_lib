function DisplayText = createDisplayDesign(DesignData)
% Utility function for display text of Design Object.

% Copyright 2013 The MathWorks, Inc.
DisplayText = [];
fn = fieldnames(DesignData);
for ct = 1:length(fn)
    str = evalc('DesignData.(fn{ct})');
    str = str(2:end);
    str = strrep(str,'ans =', sprintf('%s =', fn{ct}));
    str2 = strsplit(str,'Name:');
    aDisplayText=str2{1};
    DisplayText = [DisplayText,aDisplayText];
end

