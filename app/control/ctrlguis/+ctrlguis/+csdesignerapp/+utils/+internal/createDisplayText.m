function DisplayText = createDisplayText(identifier,Label,CellData)
% Utility function for laying out label and data in celldata for display preview
% 'type'
% TypeName
%
% 'line'
% Label: Celldata{1}, Celldata{2}...
%
% 'section'
% Label:
%   Celldata{1}
%   Celldata{2}...
%
% 'design' (already indented and a new line)
% Label:
%
%   Celldata{1}
%   Celldata{2}...

% Copyright 2013 The MathWorks, Inc.

if nargin<3
    CellData = {};
end

if ~iscell(CellData) 
    if ischar(CellData) % If CellData is single string or double
        CellData = {CellData};
    elseif isnan(CellData)
        CellData = {};
    elseif isnumeric(CellData)    
        CellData = arrayfun(@(x) {num2str(x)},CellData);
    end        
end

switch identifier
    case 'type'
        DisplayText = sprintf('%s\n',Label);  % Label
    case 'line'
        if ~isempty(CellData)
            DisplayText = sprintf('%s: ',Label);  % Label: Celldata{1}, Celldata{2}...
            
            for ct=1:length(CellData)
                DisplayText = [DisplayText ...
                    sprintf('%s, ',CellData{ct})];
            end
            DisplayText = sprintf('%s\n',DisplayText(1:end-2)); % remove last comma
        else
            DisplayText = '';
        end
    case 'section'
        if ~isempty(CellData)
            DisplayText = sprintf('%s:\n',Label); % Label:\n Celldata{1}\n Celldata{2}\n
            for ct=1:length(CellData)
                DisplayText = [DisplayText ...
                    sprintf('   %s\n',CellData{ct})];
            end
        else
            DisplayText = '';
        end
    case 'design'
        if ~isempty(CellData)
            DisplayText = sprintf('%s:\n\n',Label); % Label:\n Celldata{1}\n Celldata{2}\n
            for ct=1:length(CellData)
                DisplayText = [DisplayText ...
                    sprintf('%s\n',CellData{ct})];
            end
        else
            DisplayText = '';
        end        
end

end