function [boolEnableAddLoopButton, Widgets] = utCompensatorDisplay( ...
                                                compensatorList, ...
                                                parentGridLayout, ...
                                                selectedCompensator)
    % UTCOMPENSATORDISPLAY creates the UI Components for Compensator 
    % Section in Compensator Dialog and Automated Tuning Dialogs
    
    dropdownItems = {compensatorList.Name};
    % adding additional row with 1x to accomodate layout issues
    gridLayoutDisplay = uigridlayout(parentGridLayout, ...
                                [1 5]);
    gridLayoutDisplay.RowHeight = {'fit', '1x'};
    gridLayoutDisplay.ColumnWidth = {'1x', 'fit', 'fit', '4x', 'fit'};
    gridLayoutDisplay.Layout.Row = 1;
    gridLayoutDisplay.Layout.Column = [1 2];
    

    gridLayoutDropdown = uigridlayout(gridLayoutDisplay, [1 1]);
    gridLayoutDropdown.RowHeight = {'fit', '1x'};
    gridLayoutDropdown.ColumnWidth = {'1x'};
    gridLayoutDropdown.Layout.Row = 1;
    gridLayoutDropdown.Layout.Column = 1;
    

    compListDropdown = uidropdown(gridLayoutDropdown);
    compListDropdown.Layout.Row = 1;
    compListDropdown.Layout.Column = 1;
    compListDropdown.Items = dropdownItems;
    
    compEqualToLabel = uilabel(gridLayoutDisplay);
    compEqualToLabel.Layout.Row = 1;
    compEqualToLabel.Layout.Column = 2;
    compEqualToLabel.Text = '=';
    
    % get text for gain and pole-zero labels
    if isempty(compensatorList)
        % If there are no loops/ compensators to be tuned
        PZString = '';
        GainString = sprintf('%s', getString(message( ...
            'Control:designerapp:NotTunableByMethod')));
        % enableButtons(this, 'off');
        boolEnableAddLoopButton = false;
    else
        [PZString, GainString, lenString] = ctrlguis.csdesignerapp.utils. ...
            internal.utParseCompDisplay( ...
            selectedCompensator);
        % enableButtons(this, 'on');
        boolEnableAddLoopButton = true;
    end
    
    gridLayoutEditfield = uigridlayout(gridLayoutDisplay, [1 1]);
    gridLayoutEditfield.RowHeight = {'fit', '1x'};
    gridLayoutEditfield.ColumnWidth = {'1x'};
    gridLayoutEditfield.Layout.Row = 1;
    gridLayoutEditfield.Layout.Column = 3;

    compGainEditField = uieditfield(gridLayoutEditfield, 'numeric');
    compGainEditField.Layout.Row = 1;
    compGainEditField.Layout.Column = 1;
    compGainEditField.Value = str2num(GainString);
%     compGainEditField.Interpreter = 'html';
%             compGainLabel.WordWrap = 'on';
    
    compPZLabel = uilabel(gridLayoutDisplay);
    compPZLabel.Layout.Row = 1;
    compPZLabel.Layout.Column = 4;
    compPZLabel.Interpreter = 'latex'; %'html'; %'html';
    compPZLabel.VerticalAlignment = 'center';
    compPZLabel.Text = PZString;

    % add to Widgets
    Widgets.CompListDropdown = compListDropdown;
    Widgets.CompPZLabel = compPZLabel;
    Widgets.CompGainLabel = compGainEditField;
end

