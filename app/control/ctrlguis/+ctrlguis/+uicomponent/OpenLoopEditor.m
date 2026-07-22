classdef OpenLoopEditor < matlab.ui.componentcontainer.ComponentContainer & ...
        controllib.chart.internal.foundation.MixInListeners

    %% Properties
    properties (Dependent,AbortSet,SetObservable)
        Plant DynamicSystem
        NominalPlantIndex (1,1) double
        Compensator DynamicSystem
        ViewType (1,1) string {mustBeMember(ViewType,["bode","nichols","rlocus"])}
    end

    properties (Dependent,SetAccess=private)
        View controllib.chart.editor.internal.EditorView
    end

    properties (Access=protected)
        SavedValues
    end

    properties (Hidden,SetAccess=private,NonCopyable,Transient)
        ID
    end

    properties (GetAccess=protected,SetAccess=private)
		Version (1,1) matlabRelease = matlabRelease
    end

    properties (Access=protected,Transient,NonCopyable)
        GridLayout matlab.ui.container.GridLayout {mustBeScalarOrEmpty}

        BodeEditor controllib.chart.editor.BodeEditor {mustBeScalarOrEmpty}
        NicholsEditor controllib.chart.editor.NicholsEditor {mustBeScalarOrEmpty}
        RLocusEditor controllib.chart.editor.RLocusEditor {mustBeScalarOrEmpty}

        BodeView controllib.chart.editor.view.BodeView {mustBeScalarOrEmpty}
        NicholsView controllib.chart.editor.view.NicholsView {mustBeScalarOrEmpty}
        RLocusView controllib.chart.editor.view.RLocusView {mustBeScalarOrEmpty}

        ViewTypeMenus (:,1) matlab.ui.container.Menu
        CompensatorEditorMenus (:,1) matlab.ui.container.Menu

        CompensatorEditor ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorDialog {mustBeScalarOrEmpty}
    end

    properties (Access=private)
        Plant_I
        NominalPlantIndex_I
        Compensator_I
        ViewType_I
    end

    %% Events
    events (HasCallbackProperty,NotifyAccess=private)
        CompensatorChanging
        CompensatorChanged
    end

    %% Destructor
    % Note: constructor is intentionally left as default to take advantage
    % of ComponentContainer
    methods
        function delete(this)
            delete(this.CompensatorEditor);
            delete@controllib.chart.internal.foundation.MixInListeners(this);
            delete@matlab.ui.componentcontainer.ComponentContainer(this);
        end
    end

    %% Get/Set
    methods
        % FixedPlant
        function FixedPlant = get.Plant(this)
            FixedPlant = this.Plant_I;
        end

        function set.Plant(this,Plant)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                Plant DynamicSystem {validateSetPlant(this,Plant)}
            end
            plantValue = getValue(Plant,'usample');
            curPlantValue = getValue(this.Plant_I,'usample');
            if nmodels(curPlantValue) ~= nmodels(plantValue)
                this.NominalPlantIndex_I = 1;
            end
            rLocusValid = ~isa(Plant,'FRDModel') && ~(hasdelay(Plant) && ~isdt(Plant));
            for ii = 1:length(this.ViewTypeMenus)                
                c = this.ViewTypeMenus(ii).Children(strcmp({this.ViewTypeMenus(ii).Children.Tag},"rlocuseditor"));
                c.Visible = rLocusValid;
            end
            this.Plant_I = Plant;
        end

        % NominalPlant
        function NominalPlant = get.NominalPlantIndex(this)
            NominalPlant = this.NominalPlantIndex_I;
        end

        function set.NominalPlantIndex(this,NominalPlant)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                NominalPlant (1,1) double {mustBePositive,mustBeInteger,validateSetNominalPlantIndex(this,NominalPlant)}
            end
            this.NominalPlantIndex_I = NominalPlant;
        end

        % Compensator
        function Compensator = get.Compensator(this)
            Compensator = this.Compensator_I;
        end

        function set.Compensator(this,Compensator)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                Compensator (1,1) DynamicSystem {ctrlguis.uicomponent.OpenLoopEditor.validateCompensator(Compensator)}
            end
            this.Compensator_I = zpk(Compensator);
            if ~isempty(this.CompensatorEditor) && isvalid(this.CompensatorEditor)
                updateUI(this.CompensatorEditor);
            end
        end

        % ViewType
        function ViewType = get.ViewType(this)
            ViewType = this.ViewType_I;
        end

        function set.ViewType(this,ViewType)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                ViewType (1,1) string {mustBeMember(ViewType,["bode","nichols","rlocus"]),validateSetViewType(this,ViewType)}
            end
            this.ViewType_I = ViewType;
            setupChart(this,this.ViewType); %Set up new view if needed
        end

        % View
        function View = get.View(this)
            setupChart(this,this.ViewType); %Ensure View is valid
            switch this.ViewType
                case "bode"
                    View = this.BodeView;
                case "nichols"
                    View = this.NicholsView;
                case "rlocus"
                    View = this.RLocusView;
            end
        end
    end

    %% Public methods
    methods
        function reset(this)
            for ii = 1:numel(this)
                pos = this(ii).Position;
                setup(this(ii));
                this(ii).Position = pos;
                reset(this(ii).BodeEditor);
                reset(this(ii).NicholsEditor);
                reset(this(ii).RLocusEditor);
            end
            reset@matlab.ui.componentcontainer.ComponentContainer(this);
        end
    end

    %% Static methods
    methods (Static)
        function thisLoaded = doloadobj(thisLoaded)
            upgradeToLatestVersion(thisLoaded);

            % Load editor views
            types = ["Bode";"Nichols";"RLocus"];
            for ii = 1:length(types)
                editorStr = types(ii)+"Editor";
                if isfield(thisLoaded.SavedValues,editorStr)
                    % Ensure chart is built
                    setupChart(thisLoaded,lower(types(ii)));
                else
                    continue;
                end
                viewStr = types(ii)+"View";
                props = thisLoaded.(viewStr).getCopyableProperties();
                for jj = 1:length(props)
                    thisLoaded.(editorStr).(props(jj)) = thisLoaded.SavedValues.(editorStr).(props(jj));
                end
                labelProps = thisLoaded.(viewStr).Title.getCopyableProperties();
                labels = ["Title";"Subtitle";"XLabel";"YLabel"];
                for jj = 1:length(labels)
                    for kk = 1:length(labelProps)
                        thisLoaded.(editorStr).(labels(jj)).(labelProps(kk)) = thisLoaded.SavedValues.(editorStr).(labels(jj)).(labelProps(kk));
                    end
                end
                axesStyleProps = thisLoaded.(viewStr).AxesStyle.getCopyableProperties();
                for jj = 1:length(axesStyleProps)
                    thisLoaded.(editorStr).AxesStyle.(axesStyleProps(jj)) = thisLoaded.SavedValues.(editorStr).AxesStyle.(axesStyleProps(jj));
                end
                if isfield(thisLoaded.SavedValues.(editorStr),"Characteristics")
                    chars = properties(thisLoaded.(viewStr).Characteristics);
                    for jj = 1:length(chars)
                        c = thisLoaded.(viewStr).Characteristics.(chars{jj});
                        cProps = properties(c);
                        for kk = 1:length(cProps)
                            thisLoaded.(editorStr).Characteristics.(chars{jj}).(cProps{kk}) = thisLoaded.SavedValues.(editorStr).Characteristics.(chars{jj}).(cProps{kk});
                        end
                    end
                end
            end

            thisLoaded.SavedValues = [];
        end
    end
    
    methods (Access={?matlab.graphics.mixin.internal.Copyable, ?matlab.graphics.internal.CopyContext}, Hidden)
        function thisCopy = copyElement(this)
            % Initialize component
            thisCopy = copyElement@matlab.ui.componentcontainer.ComponentContainer(this); 

            % Copy editor views
            types = ["Bode";"Nichols";"RLocus"];
            for ii = 1:length(types)
                editorStr = types(ii)+"Editor";
                if isempty(this.(editorStr)) || ~isvalid(this.(editorStr))
                    continue;
                else
                    % Ensure chart is built
                    setupChart(thisCopy,lower(types(ii)));
                end
                viewStr = types(ii)+"View";
                props = this.(viewStr).getCopyableProperties();
                for jj = 1:length(props)
                    thisCopy.(editorStr).(props(jj)) = this.(editorStr).(props(jj));
                end
                labelProps = this.(viewStr).Title.getCopyableProperties();
                labels = ["Title";"Subtitle";"XLabel";"YLabel"];
                for jj = 1:length(labels)
                    for kk = 1:length(labelProps)
                        thisCopy.(editorStr).(labels(jj)).(labelProps(kk)) = this.(editorStr).(labels(jj)).(labelProps(kk));
                    end
                end
                axesStyleProps = this.(viewStr).AxesStyle.getCopyableProperties();
                for jj = 1:length(axesStyleProps)
                    thisCopy.(editorStr).AxesStyle.(axesStyleProps(jj)) = this.(editorStr).AxesStyle.(axesStyleProps(jj));
                end
                if isprop(this.(viewStr),"Characteristics")
                    chars = properties(this.(viewStr).Characteristics);
                    for jj = 1:length(chars)
                        c = this.(viewStr).Characteristics.(chars{jj});
                        cProps = properties(c);
                        for kk = 1:length(cProps)
                            thisCopy.(editorStr).Characteristics.(chars{jj}).(cProps{kk}) = this.(editorStr).Characteristics.(chars{jj}).(cProps{kk});
                        end
                    end
                end
            end
        end
    end

    %% Protected methods
    methods (Access=protected)
        function setup(this)
            % Initial values
            this.Position = [10 10 400 400];
            this.Plant_I = ss(NaN);
            this.NominalPlantIndex_I = 1;
            this.Compensator_I = zpk(1);
            this.ViewType_I = "bode";
            this.Type = "openloopeditor";
            this.CompensatorChangedFcn = '';
            this.CompensatorChangingFcn = '';
            if isempty(this.ID)
                this.ID = matlab.lang.internal.uuid();
            end

            if isempty(this.GridLayout) || ~isvalid(this.GridLayout)
                this.GridLayout = uigridlayout(this,[1 1]);
            end
        end

        function update(this)
            this.GridLayout.BackgroundColor = this.BackgroundColor;
            % Generate chart and view
            setupChart(this,this.ViewType);
            % Parent active chart
            switch this.ViewType
                case "bode"
                    if ~isempty(this.NicholsEditor) && isvalid(this.NicholsEditor)
                        this.NicholsEditor.Parent = [];
                    end
                    if ~isempty(this.RLocusEditor) && isvalid(this.RLocusEditor)
                        this.RLocusEditor.Parent = [];
                    end
                    this.BodeEditor.Parent = this.GridLayout;
                case "nichols"
                    if ~isempty(this.BodeEditor) && isvalid(this.BodeEditor)
                        this.BodeEditor.Parent = [];
                    end
                    if ~isempty(this.RLocusEditor) && isvalid(this.RLocusEditor)
                        this.RLocusEditor.Parent = [];
                    end
                    this.NicholsEditor.Parent = this.GridLayout;
                case "rlocus"
                    if ~isempty(this.BodeEditor) && isvalid(this.BodeEditor)
                        this.BodeEditor.Parent = [];
                    end
                    if ~isempty(this.NicholsEditor) && isvalid(this.NicholsEditor)
                        this.NicholsEditor.Parent = [];
                    end
                    this.RLocusEditor.Parent = this.GridLayout;
            end
            % Validate data
            try
                this.validatePlantWithCompensator(this.Plant,this.Compensator);
            catch ME
                switch this.ViewType
                    case "bode"
                        this.BodeEditor.Responses.Visible = false;
                    case "nichols"
                        this.NicholsEditor.Responses.Visible = false;
                    case "rlocus"
                        this.RLocusEditor.Responses.Visible = false;
                end
                warning(ME.identifier,'%s',ME.message);
                return;
            end
            % Update data
            switch this.ViewType
                case "bode"
                    % Update plant
                    this.BodeEditor.Responses.SourceData.Model = this.Plant;
                    this.BodeEditor.Responses.NominalIndex = this.NominalPlantIndex;
                    % Update compensator
                    this.BodeEditor.Responses.Compensator = this.Compensator;
                    this.BodeEditor.Responses.Visible = true;
                case "nichols"
                    % Update plant
                    this.NicholsEditor.Responses.SourceData.Model = this.Plant;
                    this.NicholsEditor.Responses.NominalIndex = this.NominalPlantIndex;
                    % Update compensator
                    this.NicholsEditor.Responses.Compensator = this.Compensator;
                    this.NicholsEditor.Responses.Visible = true;
                case "rlocus"
                    % Update plant
                    this.RLocusEditor.Responses.SourceData.Model = this.Plant;
                    this.RLocusEditor.Responses.NominalIndex = this.NominalPlantIndex;
                    % Update compensator
                    this.RLocusEditor.Responses.Compensator = this.Compensator;
                    this.RLocusEditor.Responses.Visible = true;
            end
        end
        
        function this = saveobj(this)
            this.SavedValues = [];

            % Save editor views
            types = ["Bode";"Nichols";"RLocus"];
            for ii = 1:length(types)
                editorStr = types(ii)+"Editor";
                if isempty(this.(editorStr)) || ~isvalid(this.(editorStr))
                    continue;
                end
                viewStr = types(ii)+"View";
                props = this.(viewStr).getCopyableProperties();
                for jj = 1:length(props)
                    this.SavedValues.(editorStr).(props(jj)) = this.(viewStr).(props(jj));
                end
                labelProps = this.(viewStr).Title.getCopyableProperties();
                labels = ["Title";"Subtitle";"XLabel";"YLabel"];
                for jj = 1:length(labels)
                    for kk = 1:length(labelProps)
                        this.SavedValues.(editorStr).(labels(jj)).(labelProps(kk)) = this.(viewStr).(labels(jj)).(labelProps(kk));
                    end
                end
                axesStyleProps = this.(viewStr).AxesStyle.getCopyableProperties();
                for jj = 1:length(axesStyleProps)
                    this.SavedValues.(editorStr).AxesStyle.(axesStyleProps(jj)) = this.(viewStr).AxesStyle.(axesStyleProps(jj));
                end
                if isprop(this.(viewStr),"Characteristics")
                    chars = properties(this.(viewStr).Characteristics);
                    for jj = 1:length(chars)
                        c = this.(viewStr).Characteristics.(chars{jj});
                        cProps = properties(c);
                        for kk = 1:length(cProps)
                            this.SavedValues.(editorStr).Characteristics.(chars{jj}).(cProps{kk}) = c.(cProps{kk});
                        end
                    end
                end
            end
        end

        function upgradeToLatestVersion(thisLoaded)
            thisLoaded.Version = matlabRelease;
        end
    end

    %% Private methods
    methods (Access=private)
        function setupChart(this,chartType)
            types = ["Bode";"Nichols";"RLocus"];
            switch chartType
                case "bode"
                    % Create chart
                    if isempty(this.BodeEditor) || ~isvalid(this.BodeEditor)
                        this.BodeEditor = controllib.chart.editor.BodeEditor(HandleVisibility="off");
                        addResponse(this.BodeEditor,this.Plant,this.Compensator,Name="Design 1");
                        this.BodeEditor.Responses.SemanticColor = "--mw-graphics-colorOrder-1-primary";
                        if strcmp(controllib.chart.editor.BodeEditor.createDefaultOptions().FreqUnits,"auto")
                            this.BodeEditor.FrequencyUnit = this.BodeEditor.Responses(1).FrequencyUnit;
                        end
                        % Connect chart
                        weakThis = matlab.lang.WeakReference(this);
                        L = addlistener(this.BodeEditor,"CompensatorChanged",@(es,ed) cbUpdateCompensatorFromChart(weakThis.Handle,es,ed));
                        registerListeners(this,L,"EditorCompensatorChangedListener");
                        % Customize context menu
                        this.ViewTypeMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorViewTypeMenu')),Tag="viewtype");
                        for jj = 1:length(types)
                            msg = sprintf('Controllib:plots:str%sEditor',types(jj));
                            uimenu(Parent=this.ViewTypeMenus(end),Text=getString(message(msg)),...
                                Checked=jj==1,Enable=jj~=1,Tag=lower(types(jj))+"editor",...
                                MenuSelectedFcn=@(es,ed) set(weakThis.Handle,ViewType=lower(types(jj))));
                        end
                        addMenu(this.BodeEditor,this.ViewTypeMenus(end),Above="systems");
                        this.CompensatorEditorMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorEditCompensatorMenu')),...
                            Tag="compEdit",MenuSelectedFcn=@(es,ed) openCompensatorEditor(weakThis.Handle));
                        addMenu(this.BodeEditor,this.CompensatorEditorMenus(end),Above="grid");
                        removeMenu(this.BodeEditor,"systems");
                    end
                    % Create view
                    if isempty(this.BodeView) || ~isvalid(this.BodeView)
                        this.BodeView = controllib.chart.editor.view.BodeView(this.BodeEditor);
                    end
                case "nichols"
                    % Create chart
                    if isempty(this.NicholsEditor) || ~isvalid(this.NicholsEditor)
                        this.NicholsEditor = controllib.chart.editor.NicholsEditor(HandleVisibility="off");
                        addResponse(this.NicholsEditor,this.Plant,this.Compensator,Name="Design 1");
                        this.NicholsEditor.Responses.SemanticColor = "--mw-graphics-colorOrder-1-primary";
                        if strcmp(controllib.chart.editor.NicholsEditor.createDefaultOptions().FreqUnits,"auto")
                            this.NicholsEditor.FrequencyUnit = this.NicholsEditor.Responses(1).FrequencyUnit;
                        end
                        % Connect chart
                        weakThis = matlab.lang.WeakReference(this);
                        L = addlistener(this.NicholsEditor,"CompensatorChanged",@(es,ed) cbUpdateCompensatorFromChart(weakThis.Handle,es,ed));
                        registerListeners(this,L,"EditorCompensatorChangedListener");
                        % Customize context menu
                        this.ViewTypeMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorViewTypeMenu')),Tag="viewtype");
                        for jj = 1:length(types)
                            msg = sprintf('Controllib:plots:str%sEditor',types(jj));
                            uimenu(Parent=this.ViewTypeMenus(end),Text=getString(message(msg)),...
                                Checked=jj==2,Enable=jj~=2,Tag=lower(types(jj))+"editor",...
                                MenuSelectedFcn=@(es,ed) set(weakThis.Handle,ViewType=lower(types(jj))));
                        end
                        addMenu(this.NicholsEditor,this.ViewTypeMenus(end),Above="systems");
                        this.CompensatorEditorMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorEditCompensatorMenu')),...
                            Tag="compEdit",MenuSelectedFcn=@(es,ed) openCompensatorEditor(weakThis.Handle));
                        addMenu(this.NicholsEditor,this.CompensatorEditorMenus(end),Above="grid");
                        removeMenu(this.NicholsEditor,"systems");
                    end
                    % Create view
                    if isempty(this.NicholsView) || ~isvalid(this.NicholsView)
                        this.NicholsView = controllib.chart.editor.view.NicholsView(this.NicholsEditor);
                    end
                case "rlocus"
                    % Create chart
                    if isempty(this.RLocusEditor) || ~isvalid(this.RLocusEditor)
                        this.RLocusEditor = controllib.chart.editor.RLocusEditor(HandleVisibility="off");
                        addResponse(this.RLocusEditor,this.Plant,this.Compensator,Name="Design 1");
                        this.RLocusEditor.Responses.SemanticColor = "--mw-graphics-colorOrder-1-primary";
                        if strcmp(controllib.chart.editor.RLocusEditor.createDefaultOptions().TimeUnits,"auto")
                            this.RLocusEditor.TimeUnit = this.RLocusEditor.Responses(1).TimeUnit;
                        end
                        % Connect chart
                        weakThis = matlab.lang.WeakReference(this);
                        L = addlistener(this.RLocusEditor,"CompensatorChanged",@(es,ed) cbUpdateCompensatorFromChart(weakThis.Handle,es,ed));
                        registerListeners(this,L,"EditorCompensatorChangedListener");
                        % Customize context menu
                        this.ViewTypeMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorViewTypeMenu')),Tag="viewtype");
                        for jj = 1:length(types)
                            msg = sprintf('Controllib:plots:str%sEditor',types(jj));
                            uimenu(Parent=this.ViewTypeMenus(end),Text=getString(message(msg)),...
                                Checked=jj==3,Enable=jj~=3,Tag=lower(types(jj))+"editor",...
                                MenuSelectedFcn=@(es,ed) set(weakThis.Handle,ViewType=lower(types(jj))));
                        end
                        addMenu(this.RLocusEditor,this.ViewTypeMenus(end),Above="systems");
                        this.CompensatorEditorMenus(end+1) = uimenu(Parent=[],Text=getString(message('Control:design:loopEditorEditCompensatorMenu')),...
                            Tag="compEdit",MenuSelectedFcn=@(es,ed) openCompensatorEditor(weakThis.Handle));
                        addMenu(this.RLocusEditor,this.CompensatorEditorMenus(end),Above="grid");
                        removeMenu(this.RLocusEditor,"systems");
                    end
                    % Create view
                    if isempty(this.RLocusView) || ~isvalid(this.RLocusView)
                        this.RLocusView = controllib.chart.editor.view.RLocusView(this.RLocusEditor);
                    end
            end
        end

        function validateSetPlant(this,Plant)
            this.validatePlant(Plant);
            this.validatePlantWithView(Plant,this.ViewType);
        end

        function validateSetNominalPlantIndex(this,NominalPlantIndex)
            this.validateNominalPlantIndex(NominalPlantIndex,this.Plant);
        end

        function validateSetViewType(this,ViewType)
            this.validatePlantWithView(this.Plant,ViewType);
        end

        function cbUpdateCompensatorFromChart(this,es,ed)
            persistent oldComp
            this.Compensator = es.Responses(ed.Data.ResponseIdx).Compensator;
            status = ed.Data.Status;
            switch status
                case 'Init'
                    oldComp = this.Compensator;
                case 'InProgress'
                    ed = ctrlguis.uicomponent.loopeditor.CompensatorChangingData(this.Compensator);
                    notify(this,'CompensatorChanging',ed);
                case 'Finished'
                    ed = ctrlguis.uicomponent.loopeditor.CompensatorChangedData(this.Compensator,oldComp);
                    notify(this,'CompensatorChanged',ed);
            end
        end

        function openCompensatorEditor(this)
            % Change pointer to busy
            fig = ancestor(this,'figure');
            if ~isempty(fig)
                currentPointer = fig.Pointer;
                fig.Pointer = 'watch';
            end
            if isempty(this.CompensatorEditor) || ~isvalid(this.CompensatorEditor)
                % Build dialog if needed
                buildCompensatorEditor(this);
            end
            show(this.CompensatorEditor,ancestor(this,'figure'));
            updateUI(this.CompensatorEditor);
            % Change pointer back
            if ~isempty(fig)
                fig.Pointer = currentPointer;
            end
        end

        function buildCompensatorEditor(this)
            this.CompensatorEditor = ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorDialog(this);
            matlab.graphics.internal.drawnow.startUpdate;
        end
    end

    %% Compensator Editor methods
    methods (Access=?ctrlguis.uicomponent.loopeditor.internal.CompensatorEditorDialog)
        function cbUpdateCompensatorFromEditor(this,comp)
            oldComp = this.Compensator;
            this.Compensator = comp;
            ed = ctrlguis.uicomponent.loopeditor.CompensatorChangedData(this.Compensator,oldComp);
            notify(this,'CompensatorChanged',ed);
        end
    end

    %% Static hidden methods
    methods (Static,Hidden)
        function validatePlant(plant)
            if isempty(plant)
                error(message('Control:design:loopEditorErrorPlantEmpty'));
            elseif ~issiso(plant)
                error(message('Control:design:loopEditorErrorPlantMIMO'));
            elseif isa(plant,'idnlmodel') || isTimeVarying(plant)
                error(message('Control:design:loopEditorErrorPlantNotLTI'));
            elseif ~isreal(plant)
                error(message('Control:design:loopEditorErrorPlantComplex'));
            elseif issparse(plant)
                error(message('Control:design:loopEditorErrorPlantSparse'));
            end
        end

        function validateCompensator(comp)
            try
                comp = zpk(comp);
            catch
                error(message('Control:design:loopEditorErrorCompZPK'));
            end
            if isempty(comp)
                error(message('Control:design:loopEditorErrorCompEmpty'));
            elseif ~issiso(comp)
                error(message('Control:design:loopEditorErrorCompMIMO'));
            elseif nmodels(comp) > 1
                error(message('Control:design:loopEditorErrorCompArray'));
            elseif ~isreal(comp)
                error(message('Control:design:loopEditorErrorCompComplex'));
            elseif hasdelay(comp)
                error(message('Control:design:loopEditorErrorCompDelay'));
            end
        end

        function validatePlantWithCompensator(plant,comp)
            if comp.Ts ~= plant.Ts
                error(message('Control:design:loopEditorErrorSampleTime'));
            elseif ~strcmp(comp.TimeUnit,plant.TimeUnit)
                error(message('Control:design:loopEditorErrorTimeUnit'));
            end
        end

        function validatePlantWithView(plant,view)
            if view=="rlocus" && isa(plant,'FRDModel')
                error(message('Control:design:loopEditorErrorPlantFRD'));
            elseif view=="rlocus" && hasdelay(plant) && ~isdt(plant)
                error(message('Control:design:loopEditorErrorPlantCTDelay'));
            end
        end

        function validateNominalPlantIndex(index,plant)
            plantValue = getValue(plant,'usample');
            if index > nmodels(plantValue)
                error(message('Control:design:loopEditorErrorNominalPlantIndex'));
            end
        end
    end

    %% Hidden methods
    methods (Hidden)
        function setoptions(this,opts)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                opts (1,1) plotopts.PlotOptions
            end
            % Ensure chart is built
            setupChart(this,this.ViewType);
            switch this.ViewType
                case "bode"
                    mustBeA(opts,"plotopts.BodeOptions")
                    setoptions(this.BodeEditor,opts);
                case "nichols"
                    mustBeA(opts,"plotopts.NicholsOptions")
                    setoptions(this.NicholsEditor,opts);
                case "rlocus"
                    mustBeA(opts,"plotopts.PZOptions")
                    setoptions(this.RLocusEditor,opts);
            end
        end
        
        function qeDrag(this,type,startLoc,endLoc,optionalInputs)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                type (1,1) string {mustBeMember(type,["gain";"zero";"pole";"complexConjugateZero";"complexConjugatePole"])}
                startLoc (1,2) double
                endLoc (1,2) double
                optionalInputs.AxesType (1,1) string {mustBeMember(optionalInputs.AxesType,["Magnitude";"Phase"])} = "Magnitude"
            end
            switch this.ViewType
                case "bode"
                    qeDrag(this.BodeEditor,type,startLoc,endLoc,optionalInputs.AxesType);
                case "nichols"
                    qeDrag(this.NicholsEditor,type,startLoc,endLoc);
                case "rlocus"
                    qeDrag(this.RLocusEditor,type,startLoc,endLoc);
            end
        end

        function qeClickToolbarButton(this,btn)
            arguments
                this (1,1) ctrlguis.uicomponent.OpenLoopEditor
                btn (1,1) string {mustBeMember(btn,["addpole","addzero","addccpole","addcczero","removepz","pan","zoomin","zoomout","datacursor","none"])}
            end
            switch this.ViewType
                case "bode"
                    qeClickToolbarButton(this.BodeEditor,btn);
                case "nichols"
                    qeClickToolbarButton(this.NicholsEditor,btn);
                case "rlocus"
                    qeClickToolbarButton(this.RLocusEditor,btn);
            end
        end

        function h = qeGetActiveChart(this)
            switch this.ViewType
                case "bode"
                    h = this.BodeEditor;
                case "nichols"
                    h = this.NicholsEditor;
                case "rlocus"
                    h = this.RLocusEditor;
            end
        end

        function wdgt = qeGetWidgets(this)
            wdgt.Layout = this.GridLayout;
            wdgt.BodeEditor = this.BodeEditor;
            wdgt.NicholsEditor = this.NicholsEditor;
            wdgt.RLocusEditor = this.RLocusEditor;
            wdgt.CompensatorEditor = this.CompensatorEditor;
        end

        function qeUpdate(this)
            update(this);
            switch this.ViewType
                case "bode"
                    qeUpdate(this.BodeEditor);
                case "nichols"
                    qeUpdate(this.NicholsEditor);
                case "rlocus"
                    qeUpdate(this.RLocusEditor);
            end
        end

        function dlg = qeOpenCompensatorEditor(this)
            openCompensatorEditor(this);
            dlg = this.CompensatorEditor;
        end
    end
end