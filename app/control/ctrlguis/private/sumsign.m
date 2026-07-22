function SumSign = sumsign(SumBlock, Location, idx, ConfigData, AxisHandle, EditFlag)
% ------------------------------------------------------------------------%
% Function: sumsign
% Purpose: Sign box for Sum block
% Arguments:
%       SumBlock: Structure created by createsum
%       Location: Quadrant of sign {Q1,Q2,Q3,Q4}
%            idx: Index in configdata.feedback
%     ConfigData: @design object
%     AxisHandle: Parent Axis
%       EditFlag: boolean if sign is editable
%
% ------------------------------------------------------------------------%

%   Author(s): C. Buhr
%   Copyright 1986-2011 The MathWorks, Inc. 

offseta = 0.02; % Offset from sum circle for sign
offsetb = 0.02;

%Quadrant for location of sign
switch Location 
    case 'Q1'
        Position = getpos(SumBlock,'T') + [offseta, offsetb];
    case 'Q2'
        Position = getpos(SumBlock,'L') + [-offsetb, offseta];
    case 'Q3'
        Position = getpos(SumBlock,'B') + [-offseta, -offsetb];
    case 'Q4'
        Position = getpos(SumBlock,'R') + [offsetb, -offseta];
end

if ischar(idx)
    %manually specified string
    % revisit api for this case
    FBstr = idx;
else
    % Get current feedback sign
    if ConfigData.FeedbackSign(idx) == 1;
        FBstr = {'+',['S',num2str(idx)]};
    else
        FBstr = {'-',['S',num2str(idx)]};
    end
end

% Create sign label
SumSign.Label = handle(text('Parent', AxisHandle, ...
    'HorizontalAlignment', 'right', ...  
    'VerticalAlignment', 'cap', ...
    'FontUnits', 'pixels',...
    'String', FBstr, ...
    'Position', Position));

set(SumSign.Label,'FontSize',get(SumSign.Label,'FontSize')*.9)
set(SumSign.Label,'FontUnits','normalized');

% Check if sign value is editable
if EditFlag
    set(SumSign.Label,'buttondown',{@LocalUpdateSumSign idx ConfigData});
end

% ------------------------------------------------------------------------%
% Function: LocalUpdateSumSign
% Purpose: Update Sign of Sum
% ------------------------------------------------------------------------%
function LocalUpdateSumSign(hsrc, eventdata, idx, ConfigData)

if get(hsrc,'String') == '+';
    set(hsrc, 'String', '-');
    ConfigData.FeedbackSign(idx) = -1;
else
    set(hsrc, 'String', '+');
    ConfigData.FeedbackSign(idx) = 1;
end
