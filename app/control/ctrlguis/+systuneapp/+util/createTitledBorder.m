function border = createTitledBorder(panel,title)
% Utility function to create a title border.

% Copyright 2013-21 The MathWorks, Inc.

if isa(panel,'matlab.ui.container.Panel')
    % uipanel for uifigure based dialogs
    panel.Title = title;
    panel.FontWeight = 'bold';
    panel.BorderType = 'none';
    panel.FontUnits = 'pixels';
    panel.FontSize = 12;
    panel.FontName = 'Helvetica';
end
