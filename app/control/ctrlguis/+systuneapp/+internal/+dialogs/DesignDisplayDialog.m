classdef (Hidden) DesignDisplayDialog < controllib.ui.internal.dialog.AbstractDialog
    %% Class for display designs.

    % Copyright 2013-2021 The MathWorks, Inc.

    %% Properties
    properties(Access=private)
        DesignData
        Widgets = struct('dialogLayout',[],'txtDesignSnapshot',[]);
    end

    %% Constructor
    methods
        function this = DesignDisplayDialog(designData)
            %% Constructs an instance of DesignDisplayDialog.

            this.DesignData = designData;
            this.Name = designData.Name;
            this.Title = getString(message('Control:systunegui:DesignDisplayTitle'));
        end
    end

    %% Public methods
    methods
        function updateUI(this)
            %% Updates design preview.

            displayText = getDisplayPreviewText(this.DesignData);
            this.Widgets.txtDesignSnapshot.Value = displayText;
        end
    end

    %% Protected methods
    methods(Access=protected)
        function buildUI(this)
            %% Builds widgets.

            % Set dialog size.
            this.UIFigure.Position(3:4) = [300 300];

            % Add dialog layout.
            dialogLayout = uigridlayout(this.UIFigure,[1 1]);
            this.Widgets.dialogLayout = dialogLayout;

            % Add noneditable text area.
            txtDesignSnapshot = uitextarea(dialogLayout, ...
                "Editable","off","WordWrap","off","FontName","Courier New");
            this.Widgets.txtDesignSnapshot = txtDesignSnapshot;
        end
    end

    %% Hidden methods.
    methods(Hidden)
        function widgets = qeGetWidgets(this)
            widgets = this.Widgets;
        end
    end
end
