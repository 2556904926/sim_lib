classdef Preferences < handle & matlab.mixin.Copyable & matlab.mixin.SetGet
    % Preference data object for Control System Designer

    % Copyright 2020-2023 The MathWorks, Inc.

    properties (SetObservable = true, AbortSet)

        %---Units/Scales
        FrequencyUnits
        FrequencyScale

        MagnitudeUnits
        MagnitudeScale

        PhaseUnits

        %---Grids
        Grid

        %---Fonts
        TitleFontSize
        TitleFontWeight
        TitleFontAngle
        XYLabelsFontSize
        XYLabelsFontWeight
        XYLabelsFontAngle
        AxesFontSize
        AxesFontWeight
        AxesFontAngle

        %---Colors
        AxesForegroundColor
        RequirementColor = controllib.plot.internal.utils.GraphicsColor(8).SemanticName

        %---Siso Tool Options
        CompensatorFormat
        ShowSystemPZ
        LineStyle
        PadeOrder = 2;
        FactoryValue

        PadeOrderSelectionData = struct(...
            'PadeOrder', 2,...
            'Bandwidth', 10,...
            'UseBandwidth', false);



        MultiModelFrequencySelectionData = struct(...
            'AutoModeData', logspace(-2,2,300),...
            'UserModeString', 'logspace(-2,2,300)',...
            'UserModeData', logspace(-2,2,300), ...
            'UseAutoMode', true);

        %---Phase Wrapping
        UnwrapPhase
        PhaseWrappingBranch
        
        % Plot Update
        RealTimePlotUpdateEnabled = true

        %---Handle to Data related to tool
        Target

        %---UI Preferences
        UIFontSize

        %---Handle to Toolbox Preferences
        ToolboxPreferences

        %---Handle to Frame used to edit these preferences
        EditorFrame

        %---Listeners
        Listeners
    end

    properties (Access = private)
        %--- Dirty Flag
        PreferenceDirtyFlag = false

        Dialog
    end

    properties (GetAccess=?ctrlguis.csdesignerapp.dialogs.internal.PreferencesDialog, SetAccess=private)
        SemanticLineStyle
    end

    methods
        function this = Preferences(Tool)
            %PREFERENCESS - SISO Tool preferences object constructor
            %
            %
            this.Listeners = controllibutils.ListenerManager;

            %---Get a copy of the toolbox preferences
            this.ToolboxPreferences    = cstprefs.tbxprefs;

            %---Copy relevant toolbox preferences
            if strcmpi(this.ToolboxPreferences.FrequencyUnits, 'auto')
                % auto is currently not supported in sisotool graphical editors
                this.FrequencyUnits        = 'rad/s';
            else
                this.FrequencyUnits        = this.ToolboxPreferences.FrequencyUnits;
            end
            this.FrequencyScale        = this.ToolboxPreferences.FrequencyScale;
            this.MagnitudeUnits        = this.ToolboxPreferences.MagnitudeUnits;
            this.MagnitudeScale        = this.ToolboxPreferences.MagnitudeScale;
            this.PhaseUnits            = this.ToolboxPreferences.PhaseUnits;
            this.Grid                  = this.ToolboxPreferences.Grid;
            this.TitleFontSize         = min(this.ToolboxPreferences.TitleFontSize,9); % Defaults in graphics 2 are large
            this.TitleFontWeight       = this.ToolboxPreferences.TitleFontWeight;
            this.TitleFontAngle        = this.ToolboxPreferences.TitleFontAngle;
            this.XYLabelsFontSize      = min(this.ToolboxPreferences.XYLabelsFontSize,9); % Defaults in graphics 2 are large
            this.XYLabelsFontWeight    = this.ToolboxPreferences.XYLabelsFontWeight;
            this.XYLabelsFontAngle     = this.ToolboxPreferences.XYLabelsFontAngle;
            this.AxesFontSize          = this.ToolboxPreferences.AxesFontSize;
            this.AxesFontWeight        = this.ToolboxPreferences.AxesFontWeight;
            this.AxesFontAngle         = this.ToolboxPreferences.AxesFontAngle;
            this.AxesForegroundColor   = this.ToolboxPreferences.AxesForegroundColor;
            this.CompensatorFormat     = this.ToolboxPreferences.CompensatorFormat;
            this.ShowSystemPZ          = this.ToolboxPreferences.ShowSystemPZ;
            this.LineStyle             = this.ToolboxPreferences.SISOToolStyle;
            this.UnwrapPhase           = this.ToolboxPreferences.UnwrapPhase;
            this.PhaseWrappingBranch   = this.ToolboxPreferences.PhaseWrappingBranch;
            this.Target                  = Tool;
            this.UIFontSize            = this.ToolboxPreferences.UIFontSize;
            this.EditorFrame           = [];

            %---Install listeners
            pu = {'FrequencyUnits';...
                'MagnitudeUnits';...
                'PhaseUnits'};
            ps = {'FrequencyScale';...
                'MagnitudeScale'};
            psty = {'TitleFontSize';...
                'TitleFontSize';...
                'TitleFontWeight';...
                'TitleFontAngle';...
                'XYLabelsFontSize';...
                'XYLabelsFontWeight';...
                'XYLabelsFontAngle';...
                'AxesFontSize';...
                'AxesFontWeight';...
                'AxesFontAngle'};
            weakThis = matlab.lang.WeakReference(this);
            L1 = [...
                addlistener(this,ps,'PostSet',@(es,ed)this.localSetScale(es, ed));...
                addlistener(this,pu,'PostSet',@(es,ed)this.localSetUnits(es,ed));...
                addlistener(this,psty,'PostSet',@(es,ed)this.localSetStyle(es,ed));...
                addlistener(this,'Grid','PostSet',@(es,ed)this.localSetGrid(es,ed));...
                addlistener(this,'AxesForegroundColor',...
                'PostSet',@(es,ed)this.localSetEditor(es,ed,'LabelColor'));...
                addlistener(this,'LineStyle',...
                'PostSet',@(es,ed)this.localSetEditor(es,ed,'LineStyle'));...
                addlistener(this,'CompensatorFormat',...
                'PostSet',@(es,ed)localChangeFormat(weakThis.Handle, es, ed));...
                addlistener(this,'ShowSystemPZ',...
                'PostSet',@(es,ed)this.localShowSystemPZ(es,ed))];

            this.Listeners.deleteListeners;
            this.Listeners.addListeners(L1);

            % Initialize semantic colors
            this.SemanticLineStyle.Color.ClosedLoop = controllib.plot.internal.utils.GraphicsColor(4).SemanticName;
            this.SemanticLineStyle.Color.Compensator = controllib.plot.internal.utils.GraphicsColor(10).SemanticName;
            this.SemanticLineStyle.Color.Margin = controllib.plot.internal.utils.GraphicsColor(3).SemanticName;
            this.SemanticLineStyle.Color.PreFilter = controllib.plot.internal.utils.GraphicsColor(5).SemanticName;
            this.SemanticLineStyle.Color.Response = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
            this.SemanticLineStyle.Color.System = controllib.plot.internal.utils.GraphicsColor(1).SemanticName;
        end

        function S = saveSession(this)
            % Save properties in a structure
            S = struct('FrequencyUnits',this.FrequencyUnits,...
                'FrequencyScale',this.FrequencyScale,...
                'MagnitudeUnits',this.MagnitudeUnits,...
                'PhaseUnits',this.PhaseUnits,...
                'Grid',this.Grid,...
                'TitleFontSize',this.TitleFontSize,...
                'TitleFontAngle',this.TitleFontAngle,...
                'XYLabelsFontSize',this.XYLabelsFontSize,...
                'XYLabelsFontWeight',this.XYLabelsFontWeight,...
                'XYLabelsFontAngle',this.XYLabelsFontAngle,...
                'AxesFontSize',this.AxesFontSize,...
                'AxesFontWeight',this.AxesFontWeight,...
                'AxesFontAngle',this.AxesFontAngle,...
                'AxesForegroundColor',this.AxesForegroundColor,...
                'RequirementColor',this.RequirementColor,...
                'CompensatorFormat',this.CompensatorFormat,...
                'ShowSystemPZ',this.ShowSystemPZ,...
                'LineStyle',this.LineStyle,...
                'PadeOrder',this.PadeOrder,...
                'FactoryValue',this.FactoryValue,...
                'PadeOrderSelectionData',this.PadeOrderSelectionData,...
                'MultiModelFrequencySelectionData',this.MultiModelFrequencySelectionData,...
                'UnwrapPhase',this.UnwrapPhase,...
                'PhaseWrappingBranch',this.PhaseWrappingBranch,...
                'UIFontSize',this.UIFontSize,...
                'RealTimePlotUpdateEnabled',this.RealTimePlotUpdateEnabled);
        end

        function loadSession(this,S)
            % Assign values to properties from structure S
            set(this,S);
        end

        function setDirty(this,flag)
            if islogical(flag)
                this.PreferenceDirtyFlag = flag;
                if flag
                    controllib.ui.internal.dirtymgr.DirtyManager.getInstance(...
                        this.Target.getData().UniqueName).setDirty(flag);
                end
            end
        end

        function flag = isDirty(this)
            flag = this.PreferenceDirtyFlag;
        end

        function dlg = getDialog(this)
            if isempty(this.Dialog) || ~isvalid(this.Dialog)
                this.Dialog = ctrlguis.csdesignerapp.dialogs.internal.PreferencesDialog(this);
                registerDialog(this.Target,this.Dialog);
            end
            dlg = this.Dialog;
        end
        
        function setPlotUpdateEnabled(this,value)
            % Enable/Disable response plot update.
            %   setPlotUpdateEnabled(this) enables/disables based on stored
            %       preferences setting
            %   setPlotUpdateEnabled(this,true) enables plot update
            %   setPlotUpdateEnabled(this,false) disables plot update
            arguments
                this
                value = this.RealTimePlotUpdateEnabled
            end
            plotList = this.Target.getPlotsManager.getResponsePlotList;
            for k = 1:length(plotList)
                plotList(k).ResponseUpdateEnabled = value;
            end
        end

        function resetLineColor(this,colorType)
            this.LineStyle.Color.(colorType) = ...
                cstprefs.tbxprefs().SISOToolStyle.Color.(colorType);
        end
    end

    methods (Static = true)
        %-------------------- Listeners callbacks --------------------------------

        % Set units (for all editors)
        function localSetUnits(eventSrc,eventData)
            sisodb = eventData.AffectedObject.Target;
            % Graphical editors
            Editors = sisodb.getToolsManager.getPlotEditors;
            for ct=1:length(Editors)
                Editors(ct).setunits(eventSrc.Name,eventData.AffectedObject.(eventSrc.Name))
                updatelims(Editors(ct));
            end
        end

        % Set scales
        function localSetScale(eventSrc,eventData)
            Editors = eventData.AffectedObject.Target.getToolsManager.getPlotEditors;
            for ct=1:length(Editors)
                Editors(ct).setscale(eventSrc.Name,eventData.AffectedObject.(eventSrc.Name))
            end
        end

        % Set editor property (for all editors)
        function localSetEditor(eventSrc,eventData,EditorProperty)
            sisodb = eventData.AffectedObject.Target;
            PE = sisodb.getToolsManager.getPlotEditors;
            for ct=1:numel(PE)
                PE(ct).(EditorProperty) = eventData.AffectedObject.(eventSrc.Name);
            end
        end

        % Set grid (for all editors)
        function localSetGrid(eventSrc,eventData)
            Editors = eventData.AffectedObject.Target.getToolsManager.getPlotEditors;
            for ct=1:length(Editors)
                Editors(ct).Axes.Style.Axes.XGrid = eventData.AffectedObject.(eventSrc.Name);
                Editors(ct).Axes.Style.Axes.YGrid = eventData.AffectedObject.(eventSrc.Name);
            end
        end

        % Set label or axes style
        function localSetStyle(eventSrc,eventData)
            sisodb = eventData.AffectedObject.Target;
            PE = sisodb.getToolsManager.getPlotEditors;
            switch lower(eventSrc.Name([1 2]))
                case 'ti'
                    % Title related
                    Property = strrep(eventSrc.Name,'Title','');
                    for ct=1:length(PE)
                        set(PE(ct).Axes.Style.Title,Property,eventData.AffectedObject.(eventSrc.Name));
                    end
                case 'xy'
                    % XY label related
                    Property = strrep(eventSrc.Name,'XYLabels','');
                    for ct=1:length(PE)
                        set(PE(ct).Axes.Style.XLabel,Property,eventData.AffectedObject.(eventSrc.Name));
                        set(PE(ct).Axes.Style.YLabel,Property,eventData.AffectedObject.(eventSrc.Name));
                    end
                case 'ax'
                    % Axes style
                    Property = strrep(eventSrc.Name,'Axes','');
                    for ct=1:length(PE)
                        set(PE(ct).Axes.Style.Axes,Property,eventData.AffectedObject.(eventSrc.Name));
                    end
            end
        end

        % Set system pole/zero visibility
        function localShowSystemPZ(eventSrc,eventData)
            Editors = eventData.AffectedObject.Target.getToolsManager.getPlotEditors;
            for ct=1:length(Editors)
                if isa(Editors(ct),'ctrlguis.csdesignerapp.plot.internal.BodeEditorOL') || isa(Editors(ct),'ctrlguis.csdesignerapp.plot.internal.NicholsEditor')
                    Editors(ct).ShowSystemPZ = eventData.AffectedObject.ShowSystemPZ;
                end
            end
        end

        % Enable/disable java GUI based on CSHelpMode
        function LocalSwitchMode(eventSrc,eventData)
            sisodb = eventData.AffectedObject.UserData;
            if ~isempty(sisodb.Preferences.EditorFrame)
                if strcmpi(eventData.NewValue,'on')
                    sisodb.Preferences.EditorFrame.setEnabled(false)
                else
                    sisodb.Preferences.EditorFrame.setEnabled(true)
                end
            end
        end
    end

    methods
        function localChangeFormat(this, eventSrc,eventData)
            % Change compensator format

            setFormat(this.Target.getData,eventData.AffectedObject.(eventSrc.Name));
            % Update all plots when changing format (the "normalized" data used in the root locus
            % and bode editors becomes stale, causing bad behaviors when changing format, then
            % modifying the loop gain, see geck 88273)
        end

        function LocalConfigChanged(this)
            this.MultiModelFrequencySelectionData.AutoModeData = [];
        end

        function set.FrequencyUnits(this, ProposedValue)
            if strcmpi(ProposedValue,'rad/sec')
                this.FrequencyUnits = 'rad/s';
            else
                this.FrequencyUnits = ProposedValue;
            end
        end

        function lineStyle = get.LineStyle(this)
            lineStyle = this.LineStyle;
            if ~isempty(lineStyle)
                for colorType = fieldnames(lineStyle.Color)'
                    if isLineStyleAuto(this,colorType{1},lineStyle.Color.(colorType{1}))
                        lineStyle.Color.(colorType{1}) = this.SemanticLineStyle.Color.(colorType{1});
                    end
                end
            end
        end
    end

    methods (Access = private)
        function value = isLineStyleAuto(this,colorType,colorValue)
            arguments
                this
                colorType (1,1) string
                colorValue
            end
            if isnumeric(colorValue) && ...
                    (isequal(colorValue,cstprefs.tbxprefs().SISOToolStyle.Color.(colorType)))
                value = true;
            else
                value = false;
            end
        end
    end
end