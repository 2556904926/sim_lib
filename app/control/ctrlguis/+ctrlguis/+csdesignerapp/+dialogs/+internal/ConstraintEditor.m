classdef ConstraintEditor < controllib.ui.internal.dialog.AbstractDialog
    % ConstraintEditor  Dialog to edit any constraint from a given client

    % Copyright 1986-2023 The Mathworks, Inc.

    properties (Access = public)
        ContainerList   % List of constraint containers
        ConstraintList  % All constraints in targeted Container
        ResBundle = editconstr.ResourceBundle
    end

    properties (Access = protected, SetObservable = true)
        Container       % Targeted constraint container
        Constraint      % Edited constraint
    end

    properties (Access = private)
        ParamEditor     % Parameter editor handles
        Listeners       % Permanent Listeners
        TempListeners   % Listeners associated w/ targeted constraint
        ConstrDropdown
        ConstrDropdownLbl
        ConstrPanel
        ButtonPanel
        EditorSelect
    end

    methods (Access = public)

        function this = ConstraintEditor(ContainerList)
            %ConstraintEditor  Constructor for @ConstraintEditor class.

            % Initialize Container list.
            this.ContainerList = ContainerList;
        end

        function close(this, varargin)
            %CLOSE  Hides dialog.

            if this.UIFigure.Visible
                % Hide dialog
                close@controllib.ui.internal.dialog.AbstractDialog(this);

                % RE: Needed to properly manage Constr.Selected when dialog becomes visible again
                %     Do it first to remove all constraint listeners.
                this.Constraint = [];
                this.ConstraintList = [];

                % RE: Needed to correctly update list of constraints after hiding dialog
                this.Container = [];
            end
        end

        function List = getlist(this,key)
            %GETLIST  Builds requested list.
            switch key
                case 'ActiveContainers'
                    % List of visible containers with editable constraints
                    List = this.ContainerList;
                    hasConstr = logical([]);
                    for ct = length(List):-1:1
                        if controllib.chart.internal.utils.isChart(List(ct))
                            hasConstr(ct) = ~isempty(plotconstr.findConstrOnAxis(List(ct).getChartAxes));
                        else
                            if isa(List(ct).Axes,"controllib.chart.internal.view.axes.BaseAxesView")
                                hasConstr(ct) = ~isempty(plotconstr.findConstrOnAxis(List(ct).Axes.getAxes));
                            else
                                hasConstr(ct) = ~isempty(plotconstr.findConstrOnAxis(List(ct).Axes.getaxes));
                            end
                        end
                    end
                    List = List(hasConstr,:);
                case 'Constraints'
                    % List of active constraints in targeted container
                    if controllib.chart.internal.utils.isChart(this.Container)
                        cList = plotconstr.findConstrOnAxis(this.Container.getChartAxes);
                    else
                        if isa(this.Container.Axes,"controllib.chart.internal.view.axes.BaseAxesView")
                            cList = plotconstr.findConstrOnAxis(this.Container.Axes.getAxes);
                        else
                            cList = plotconstr.findConstrOnAxis(this.Container.Axes.getaxes);
                        end
                    end

                    List = cList(1).TextEditor;
                    for ct=2:numel(cList)
                        List(ct) = cList(ct).TextEditor;
                    end
            end
        end

        function boo = isVisible(this)
            %ISVISIBLE  Returns 1 if editor is visible.

            if isempty(this.UIFigure)
                % UI does not exist yet
                boo = 0;
            else
                boo = this.UIFigure.Visible;
            end
        end

        function target(this, Container, Constr)
            %TARGET  Points dialog to a particular container/constraint.

            % RE: Target sets targeted container/constraint w/o bringing editor upfront

            ni = nargin;

            % Set target container (will also set ConstraintList and related listeners)
            if ni<2  % no container specified
                CList = this.getlist('ActiveContainers');
                if isempty(CList)
                    this.close;
                    return
                else
                    Container = CList(1);
                end
            end
            this.Container = Container;

            % Update constraint list (constraints may be added and deleted in container)
            ConstrList = this.getlist('Constraints');
            if isempty(ConstrList)
                this.close;
                return
            elseif ~isequal(this.ConstraintList,ConstrList)
                this.ConstraintList = ConstrList;
                % Force refresh of constraint list
                this.Constraint = [];
            end

            % Set target constraint
            if ni<3  % no constraint specified
                idx = [this.ConstraintList.Selected];
                SelectedConstr = this.ConstraintList(idx);
                if isscalar(SelectedConstr)
                    Constr = SelectedConstr(1);
                else
                    Constr = this.ConstraintList(1); % default to 1st if none or more than one selected
                end
            end
            this.Constraint = Constr;
        end

        function show(this,varargin)
            %SHOW  Brings up and points dialog to a particular container/constraint.

            if isempty(this.UIFigure)
                show@controllib.ui.internal.dialog.AbstractDialog(this);
            end
            % Target editor
            this.target(varargin{:});
            %Force parambox to update, as contents only update when visible
            if ~this.UIFigure.Visible
                LocalConstraintBox(this);
                this.UIFigure.Visible = true;
            end
        end

    end  % public methods

    methods (Hidden = true)
        function wdgts = qeGetWidgets(this)
            wdgts.ParamEditor = this.ParamEditor;
            wdgts.ConstrDropdown = this.ConstrDropdown;
            wdgts.ConstrDropdownLbl = this.ConstrDropdownLbl;
            wdgts.ButtonPanel = this.ButtonPanel;
            wdgts.EditorSelect = this.EditorSelect;
        end
    end

    methods(Access = protected)

        function buildUI(this)
            % Set grid layout
            g = uigridlayout(this.UIFigure,[3 2],'Scrollable','on');
            g.RowHeight = {'fit','1x','fit'};
            g.ColumnWidth = {'fit','1x'};
            % Dropdown text and combo box
            this.ConstrDropdownLbl = uilabel(g);
            this.ConstrDropdownLbl.Layout.Row = 1;
            this.ConstrDropdownLbl.Layout.Column = 1;
            this.ConstrDropdown = uidropdown(g);
            this.ConstrDropdown.Layout.Row = 1;
            this.ConstrDropdown.Layout.Column = 2;
            % Parameter frame
            this.ConstrPanel = uipanel(g);
            this.ConstrPanel.Layout.Row = 2;
            this.ConstrPanel.Layout.Column = [1 2];
            this.ConstrPanel.BorderType = 'none';
            this.ConstrPanel.FontWeight = 'bold';
            % EditorSelect (not displayed)
            this.EditorSelect = uidropdown(g);
            this.EditorSelect.Visible = false;
            this.EditorSelect.Layout.Row = 3;
            % Button panel
            this.ButtonPanel = controllib.widget.internal.buttonpanel.ButtonPanel(g,["Help" "Close"]);
            buttonContainer = getWidget(this.ButtonPanel);
            buttonContainer.Layout.Row = 3;
            buttonContainer.Layout.Column = [1 2];
            buttonContainer.Padding = 0;
            this.configureLabels;
        end

        function connectUI(this)
            % Listeners to self for cleanup
            this.Listeners = [addlistener(this.UIFigure,'ObjectBeingDestroyed',@(~,~) LocalDestroy(this)); ...
                addlistener(this,'Container','PostSet',@(~,~) LocalContainer(this)); ...
                addlistener(this,'Constraint','PostSet',@(~,~) LocalConstraint(this))];
            % Add callbacks
            this.ConstrDropdown.ValueChangedFcn = @(~,~) localSetConstr(this);
            this.ButtonPanel.CloseButton.ButtonPushedFcn = @(~,~) close(this);
            this.ButtonPanel.HelpButton.ButtonPushedFcn = @(~,~) localHelp(this);
        end

        function configureLabels(this)
            % Use the resource bundle to set the dialog labels
            this.Title = ctrlMsgUtils.message(this.ResBundle.lblEditDlgTitle);
            this.ConstrPanel.Title = ctrlMsgUtils.message(this.ResBundle.lblRequirementParameters);
            this.ConstrDropdownLbl.Text = ctrlMsgUtils.message(this.ResBundle.lblEditRequirementSelector);
        end

        function refresh(this,key)
            %REFRESH  Updates popul lists.

            % RE: Assumes container/constraint list is non empty
            switch key
                case 'Containers'
                    % Update container list
                    List = this.getlist('ActiveContainers');
                    LocalContainerPopUp(this, List, find(arrayfun(@(x)isequal(x,this.Container),List)));
                case 'Constraints'
                    % Update constraint list
                    List = this.ConstraintList;
                    LocalConstraintsPopUp(this, List, find(this.Constraint==List));
            end
        end

    end  % protected methods

    methods (Access = private)

        function localSetConstr(this)
            % Manage Select Constraint combobox action

            %New constraint selected
            idx = find(strcmp(this.ConstrDropdown.Items,this.ConstrDropdown.Value));
            this.target(this.Container, this.ConstraintList(idx));
        end

        function localRefreshConstr(this)
            % Manage focus gained on combobox
            this.ConstraintList = this.ConstraintList(isvalid(this.ConstraintList));
            this.refresh('Constraints');
        end

        function LocalContainerPopUp(this, List, index)
            % Repopulate and set container combobox

            % Clean-up the Choice list
            PopUp = this.EditorSelect;

            % Update choice list content
            for ct = 1:length(List)
                % Remove '(C)' and '(F)' from the title strings
                if controllib.chart.internal.utils.isChart(List(ct))
                    str = List(ct).Title.String;
                else
                    str = List(ct).Axes.Title;
                end

                str = strrep(strrep(str, '(C)', ''), '(F)','');
                PopUp.Items{ct} = sprintf(char(str));
            end
            PopUp.Items(ct+1:end) = [];
            if numel(List)>0 && ~isempty(index)
                PopUp.Value = PopUp.Items(index);
            end
        end

        function LocalConstraintsPopUp(this, List, index)
            % Repopulate and set constraints combobox

            % Clean-up the choice list
            PopUp = this.ConstrDropdown;
            nPopUpItems = numel(PopUp.Items);
            nList = numel(List);

            %Determine if the popup needs to be refreshed
            refreshPopUp = nList ~= nPopUpItems; %CHange in number of items
            if ~refreshPopUp
                %Check if any items changed
                ct = 1;
                while ~refreshPopUp && ct <= nPopUpItems
                    if strcmp(PopUp.Items(ct),List(ct).describe('detail'))
                        ct = ct + 1;
                    else
                        refreshPopUp = true;
                    end
                end
            end

            if refreshPopUp
                % Update choice list content
                for i=1:numel(List)
                    this.ConstrDropdown.Items(i) = {List(i).describe('detail')};
                end
                this.ConstrDropdown.Items(i+1:end) = [];
            end

            %Switch to selected item
            if ~isempty(index)
                this.ConstrDropdown.Value = this.ConstrDropdown.Items(index);
            end
        end

        function LocalContainer(this)
            % Logic to update container choice list. Triggered when container changes
            if ~isempty(this.Container)
                % Update container list
                this.refresh('Containers');
            end
        end

        function LocalConstraint(this)
            % Logic to update constraint parameter box.
            if ~isempty(this.Constraint)
                % Update constraint popup list
                this.refresh('Constraints');

                % Update parameter box
                LocalConstraintBox(this);

                % Turn markers on for edited constraint
                this.Constraint.Selected = true;

                % Listener to Constarint move/resize using mouse.
                localAddTempListeners(this)
            else
                % Detargeting: remove listeners
                localRemoveListeners(this);
            end
        end

        function localAddTempListeners(this)
            % Add temporary constraint listeners
            if ~isempty(this.TempListeners) && isvalid(this.TempListeners)
                delete(this.TempListeners)
            end
            Constr = this.Constraint;
            this.TempListeners = addlistener(this.Constraint, 'ObjectBeingDestroyed', @(~,~) localConstraintDelete(this,Constr));
        end

        function LocalConstraintBox(this)
            % Updates constraint editor parameter box.

            % Clean-up the parameter box
            if ~isempty(this.ParamEditor)
                % Clean up current editor settings
                if ishandle(this.ParamEditor.Listeners)
                    delete(this.ParamEditor.Listeners);
                end
                this.ParamEditor = [];
            end
            % Update parameters box content
            Constr = this.Constraint.removeWidgets;
            Constr.DialogVersion = 'uifigure';
            this.ParamEditor = Constr.getWidgets(this.ConstrPanel);
        end

        function localConstraintDelete(this,Constr)
            % Manage deletion of active constraint
            if ~isscalar(this.ConstraintList)
                %Remove deleted constraint from list
                idx = arrayfun(@(x)~isequal(x,Constr),this.ConstraintList);
                first = this.ConstraintList(find(idx,1,'first'));
                if isvalid(first)
                    this.target(this.Container,first);
                    this.refresh('Constraints');
                else
                    %Deleted one and only constraint
                    this.LocalDestroy;
                end
            else
                %Deleted on and only constraint
                this.LocalDestroy;
            end
            this.refresh('Constraints');
        end

        function LocalDestroy(this)
            % Delete the editor dialog.

            % Remove listeners
            localRemoveListeners(this);
            % Hide dialog
            this.hide;
        end

        function localRemoveListeners(this)
            % Helper function to remove listeners and dependencies
            if ~isempty(this.ParamEditor)
                % Clean up current editor settings
                if ishandle(this.ParamEditor.Listeners)
                    if iscell(this.ParamEditor.Listeners)
                        delete(this.ParamEditor.Listeners{:});
                    else
                        delete(this.ParamEditor.Listeners);
                    end
                end
            end
            this.ParamEditor = [];
            delete(this.TempListeners);
            this.TempListeners = [];
            if ~isempty(this.Constraint)
                Constr = this.Constraint.removeWidgets;
                Constr.DialogVersion = 'uifigure';
                this.ParamEditor = Constr.getWidgets(this.ConstrPanel);
            end
        end

        function localHelp(this)
            % Display edit help
            mapfile = this.Constraint.HelpData.MapFile;
            topic   = this.Constraint.HelpData.TopicEdit;
            try
                helpview('control',topic)
            catch E %#ok<NASGU>
                uialert(this.UIFigure,ctrlMsgUtils.message('Controllib:graphicalrequirements:errHelpPage',mapfile, topic),'')
            end
        end

    end  % private methods

end