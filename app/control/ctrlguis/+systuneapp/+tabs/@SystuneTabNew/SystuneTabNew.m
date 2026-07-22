classdef (Hidden) SystuneTabNew < handle
    % Tuning Tab of Control System Tuner App.
    
    % Copyright 2013-2023 The MathWorks, Inc.    
    
    properties(Access = public) % make private
        % Tab = [TunableBlockSection, TuningGoalSection, SystuneGUIOptions, TuneSection]
        Tool
        Tab
        Widgets
        TuningGoalTC % New TuningGoal Dialog's TC and GC
        TuningGoalGC
        SystuneGUIOptionsTC
        SystuneGUIOptionsGC
        SystuneTuningData
        TunableBlockSelectorTC
        TunableBlockSelectorGC
        TuningGoalSelectorTC
        TuningGoalSelectorGC
        TuningReport
        TuningState = systuneapp.data.TuningState(false);
        ReportListener = event.listener.empty();
        TuneButtonTuneListener;
    end
    methods
        function this = SystuneTabNew(SystuneTuningData, Tool)
            this.SystuneTuningData=SystuneTuningData;
            this.Tool = Tool;
            this.Tab = matlab.ui.internal.toolstrip.Tab(...
                getString(message('Control:systunegui:SystuneTab')));
            this.Tab.Tag = 'MySystuneTab';
            createWidgets(this);
        end
        function delete(this)
            for ct=1:length(this.ReportListener)
                delete(this.ReportListener(ct));
            end
            delete(this.TuneButtonTuneListener);
            delete(this.TunableBlockSelectorGC)
            delete(this.TuningReport);
            delete(this.SystuneGUIOptionsGC);
            delete(this.TuningGoalSelectorGC);
        end
        function Tab = getTab(this)
            Tab = this.Tab;
        end
        function Widgets = getWidgets(this)
            Widgets = this.Widgets;
        end
        function report = getTuningReport(this)
            report = this.TuningReport;
        end
        function setTuningGoalDialog(this,TuningGoalParameter)
            if ischar(TuningGoalParameter) % new tuning goal
                TuningGoalType = TuningGoalParameter;
                TuningGoalWrapper = {};
            else % editing tuning goal
                % delete TuningGoal. part and gets tuning goal type
                TuningGoalType = systuneapp.util.getTuningGoalType(TuningGoalParameter.TuningGoal);
                TuningGoalWrapper = TuningGoalParameter;
            end
            cdd = this.SystuneTuningData.ControlDesignData;
            this.TuningGoalTC = systuneapp.util.getTuningGoalTC(TuningGoalType,cdd,TuningGoalWrapper);
            this.TuningGoalGC = createView(this.TuningGoalTC);
        end
        %% Save/Load Session
        function loadSession(this,SystuneTabSessionData)
            if ~isempty(SystuneTabSessionData)                
                % Set Selected Index of TunableBlocks
                this.SystuneTuningData.TunableBlocks(:,2) = num2cell(SystuneTabSessionData.SelectedIndexOfTunableBlocks);
                % Set Selected Index of TuningGoals
                this.SystuneTuningData.TuningGoals(:,2) = num2cell(SystuneTabSessionData.SelectedIndexOfTuningGoals);
                % Set Hard/Soft Index of TuningGoals
                this.SystuneTuningData.TuningGoals(:,3) = num2cell(SystuneTabSessionData.HardSoftIndexOfTuningGoals);
                % Set SystuneGUIOptions
                this.SystuneTuningData.Options = SystuneTabSessionData.SystuneGUIOptions;
            end
        end
        function SystuneTabSessionData = saveSession(this)
            % Get selected index of tunable blocks
            SystuneTabSessionData.SelectedIndexOfTunableBlocks = ...
                this.SystuneTuningData.getSelectedIndexOfTunableBlocks;
            % Get selected index of tuning goals
            SystuneTabSessionData.SelectedIndexOfTuningGoals = ...
                this.SystuneTuningData.getSelectedIndexOfTuningGoals;
            % Get hard/soft index of tuning goals
            SystuneTabSessionData.HardSoftIndexOfTuningGoals = ...
                this.SystuneTuningData.getHardSoftIndexOfTuningGoals;
            % Get SystuneGUIOptions
            SystuneTabSessionData.SystuneGUIOptions = ...
                this.SystuneTuningData.Options;
        end
    end
    methods (Access = private)
        %% Create Sections
        function createWidgets(this)
            createTunableBlockSectionWidgets(this)
            createTuningGoalSectionWidgets(this)
            createOptionSectionWidgets(this)
            createTuneSectionWidgets(this) 
        end
        function createTunableBlockSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            % Tuned Blocks Section
            TunableBlockSection = Section(...
                getString(message('Control:systunegui:TunableBlocksSection')));
            TunableBlockSection.Tag = 'TunableBlocksSection';
            add(this.Tab,TunableBlockSection);
            
            TunableBlockButtonIcon = Icon('controlSystem');
            TunableBlockButton = Button(getString(message('Control:systunegui:TunableBlocksSelect')),TunableBlockButtonIcon);
            TunableBlockButton.Description = getString(message('Control:systunegui:TunableBlocksSelectTooltip'));
            
            % create column
            % REVIST may not be best for localization. Used to center
            % button as section label is longer than button
            column1 = Column('HorizontalAlignment','center','Width',80);
            % assemble
            add(TunableBlockSection, column1);
            add(column1,TunableBlockButton);     

            addlistener(TunableBlockButton,'ButtonPushed',@(es,ed) showTunableBlockSelector(this));
            
            this.Widgets.TunableBlockSection =  struct(...
                'TunableBlockButton',TunableBlockButton);
        end
        function createTuningGoalSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            % Tuning Goal Section
            TuningGoalSection = Section(...
                getString(message('Control:systunegui:TuningGoalsSection')));
            TuningGoalSection.Tag = 'TuningGoalsSection';
            add(this.Tab,TuningGoalSection);
            
            % NewTuningGoalButton
            NewTuningGoalDropDownIcon = Icon('add_boundedSignal');
            NewTuningGoalDropDownLabel = getString(message('Control:systunegui:NewTuningGoal'));
            NewTuningGoalTypePicker = [];
            NewTuningGoalDropDown = DropDownButton(NewTuningGoalDropDownLabel,NewTuningGoalDropDownIcon);
            NewTuningGoalDropDown.Description = getString(message('Control:systunegui:NewTuningGoalTooltip'));
            NewTuningGoalDropDown.Popup = populateAddTuningGoal(this);
                    
            % SelectTuningGoalButton
            SelectTuningGoalButtonIcon = Icon('boundedSignal');
            SelectTuningGoalButton = Button(getString(message('Control:systunegui:SelectTuningGoal')),SelectTuningGoalButtonIcon);
            SelectTuningGoalButton.Description = getString(message('Control:systunegui:SelectTuningGoalTooltip'));
            
             % create column
            column1 = Column();
            % assemble
            add(TuningGoalSection, column1);
            add(column1,NewTuningGoalDropDown);
            add(column1,SelectTuningGoalButton);
            
               
            addlistener(SelectTuningGoalButton,'ButtonPushed',@(es,ed) showTuningGoalSelector(this));
            
            this.Widgets.TuningGoalSection =  struct(...
                'NewTuningGoalDropDown',NewTuningGoalDropDown, ...
                'NewTuningGoalTypePicker',NewTuningGoalTypePicker, ...
                'SelectTuningGoalButton',SelectTuningGoalButton);
        end
        function createOptionSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            % Options Section
            OptionsSection = Section(...
                getString(message('Control:systunegui:OptionsSection')));
            OptionsSection.Tag = 'OptionsSection';
            add(this.Tab,OptionsSection);
            
            OptionsIcon =  Icon('settings');
            OptionsButton = Button(getString(message('Control:systunegui:OptionsSelect')),OptionsIcon);
            OptionsButton.Description = getString(message('Control:systunegui:OptionsSelectToolstip'));
            
            % create column
            column1 = Column();
            % assemble
            add(OptionsSection, column1);
            add(column1,OptionsButton);
                       
            addlistener(OptionsButton,'ButtonPushed',@(es,ed) showSystuneGUIOptions(this));
            
            this.Widgets.OptionsSection =  struct(...
                'OptionsButton',OptionsButton);
        end
        function createTuneSectionWidgets(this)
            import matlab.ui.internal.toolstrip.*

            % Tuning Section
            TuneSection = Section(...
                getString(message('Control:systunegui:TuneSection')));
            TuneSection.Tag = 'TuneSection';
            add(this.Tab,TuneSection);
            
            TuneButtonIcon =  Icon('playControl');
            TuneButton = SplitButton(getString(message('Control:systunegui:TuneSelect')),TuneButtonIcon);
            TuneButton.Description = getString(message('Control:systunegui:TuneSelectTooltip'));
            
            % create column
            column1 = Column();
            % assemble
            add(TuneSection, column1);
            add(column1,TuneButton);
                       
            this.TuneButtonTuneListener = addlistener(TuneButton,'ButtonPushed',@(es,ed) tuneControllers(this));
            this.TuneButtonTuneListener.Recursive = true;
             
           TuneButton.Popup =  populateSplitButtonPopup(this);
           
            this.Widgets.TuneSection =  struct(...
                'TuneButton',TuneButton);
        end        
        %% Selectors
        function showTunableBlockSelector(this)
            if isempty(this.TunableBlockSelectorTC)
                this.TunableBlockSelectorTC = systuneapp.internal.dialogs.TunableBlockSelectorTC(this.SystuneTuningData,this.Tool.TunableBlockEditorsManager,this.Tool);
            end
            if isempty(this.TunableBlockSelectorGC)
                this.TunableBlockSelectorGC = createView(this.TunableBlockSelectorTC);
                show(this.TunableBlockSelectorGC,this.Tool.AppContainer)
            else
                show(this.TunableBlockSelectorGC)
            end
        end
        function showTuningGoalSelector(this)
            if isempty(this.TuningGoalSelectorTC)
                this.TuningGoalSelectorTC = systuneapp.internal.dialogs.TuningGoalSelectorTC(this.SystuneTuningData,this);
                this.TuningGoalSelectorGC = createView(this.TuningGoalSelectorTC);
            end
            %NOTE: POSSIBLY REMOVE ANCHOR TO TOOLSTRIP WIDGET TO DISPLAY
            %ALWAYS IN CENTER OF APP
            show(this.TuningGoalSelectorGC,this.Tool.AppContainer)
            %NOTE: ADD DIALOG MANAGER LINK WHEN AVAILABLE HERE
        end
        function Popup = populateAddTuningGoal(this)
            import matlab.ui.internal.toolstrip.*
            
            Popup = PopupList;
            Popup.Tag = 'TuningGoalTypePopup';
            
           
            % Quick-start requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupQuickStart'));
            Header.Tag = 'QuickStartSection';
            add(Popup,Header);

            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('quickstart'))
            
            % Time-domain requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupTimeDomainRequirements'));
            Header.Tag = 'TimeDomainSection';
            add(Popup,Header);
          
            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('time'));
          
            % Frequency-domain requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupFrequencyDomainRequirements'));
            Header.Tag = 'FrequencyDomainSection';
            add(Popup,Header);       

            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('frequency'));
            
            % Loop requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupLoopRequirements'));
            Header.Tag = 'OpenLoopSection';
            add(Popup,Header); 
            
            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('openloop'));  
            
            % Passivity requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupPassivityRequirements'));
            Header.Tag = 'PassivitySection';
            add(Popup,Header); 

            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('passivity'));
            
            % System dynamics requirements
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningGoalTypeGroupSystemDynamicsRequirements'));
            Header.Tag = 'SystemDynamicsSection';
            add(Popup,Header); 
            
            createTuningGoalItems(this,Popup,systuneapp.util.getTuningGoalData('systemdynamics'));          
 
        end        
        function createTuningGoalItems(this,Popup,Items)
            import matlab.ui.internal.toolstrip.*
            for ct =1:length(Items)
                Text = Items(ct).Description;
                Icon = Items(ct).Icon;
                NewItem = ListItem(Text, Icon);
                addlistener(NewItem,'ItemPushed', @(hSrc,hData) showAddTuningGoal(this,Items(ct).Name));
                add(Popup,NewItem);
            end
        end
        function showAddTuningGoal(this,TuningGoalType)
            if strcmp(TuningGoalType,'StableController') && isempty(this.SystuneTuningData.TunableBlocks)
                showError(this.Tool,getString(message('Control:systunegui:StableControllerNoController')))
                return;
            else
                setTuningGoalDialog(this,TuningGoalType);
                show(this.TuningGoalGC,this.Tool.AppContainer,'center')
                this.Widgets.TuningGoalSection.TuningGoalDialog = this.TuningGoalGC;
            end
        end
        %% SystuneGUIOptions
        function showSystuneGUIOptions(this)
            if isempty(this.SystuneGUIOptionsTC)
                this.SystuneGUIOptionsTC = systuneapp.internal.dialogs.SystuneGUIOptionsTC(this.SystuneTuningData);
                this.SystuneGUIOptionsGC = createView(this.SystuneGUIOptionsTC);
            end
            show(this.SystuneGUIOptionsGC,this.Tool.AppContainer)
            pack(this.SystuneGUIOptionsGC);
        end
        %% Tuning Report
        function createTuningReport(this,SystuneGUIOptions)
            %% Tuning Report
            % report initializations
            ReportText = systuneapp.data.ReportText;
            this.ReportListener(1) = event.listener(ReportText,'NewData',@(es,ed) updateIterationInTuningReport(this.TuningReport,ed));
            this.ReportListener(2) = event.listener(ReportText,'NewWarning',@(es,ed) accumulateWarningsInTuningReport(this.TuningReport,ed));
            if isempty(this.TuningReport)
                this.TuningReport = systuneapp.internal.dialogs.TuningReport(this.Tool);
            end
            clearContent(this.TuningReport)
            
            % get active tuning goal names (hard and soft)
            [HardNames,SoftNames] = this.SystuneTuningData.getActiveTuningGoalName;
            this.SystuneTuningData.TuningInfo.Hard.Names = HardNames;
            this.SystuneTuningData.TuningInfo.Soft.Names = SoftNames;
            this.SystuneTuningData.TuningInfo.SoftTarget = SystuneGUIOptions.SoftTarget;
            this.SystuneTuningData.TuningInfo.ParallelOn = SystuneGUIOptions.UseParallel;
            
            % show initial summary
            update_Initial_Final_InfoInTuningReport(this,'initial',this.SystuneTuningData.TuningInfo);
            % set display and stop function
            SystuneGUIOptions = setDisplayAndStopFunctions(ReportText,this.TuningState,SystuneGUIOptions);
            this.SystuneTuningData.setOptions(SystuneGUIOptions);

            % update report if selected from options or already open
            if ~strcmp(SystuneGUIOptions.Display,'off')
                show(this.TuningReport,this.Tool.AppContainer);
                pack(this.TuningReport);
            end
        end

        %% Tune
        function tuneControllers(this)
            import matlab.ui.internal.toolstrip.*

            %% Verify there exist at least one tunable block and one tuning goal
            if ~any(this.SystuneTuningData.getSelectedIndexOfTunableBlocks)
                showError(this.Tool,getString(message('Control:systunegui:GeneralNoBlock')))
                return
            end
            if ~any(this.SystuneTuningData.getSelectedIndexOfTuningGoals)
                showError(this.Tool,getString(message('Control:systunegui:GeneralNoTuningGoal')))
                return
            end

            try % if systune errors, pass to an error dialog
                %% In parallel allow first run and throw warning for next runs
                SystuneGUIOptions = this.SystuneTuningData.Options;
                if this.TuningState.IsTuning
                    if SystuneGUIOptions.UseParallel
                        showWarning(this.Tool,getString(message('Control:systunegui:GeneralNoStopInParallel')))
                    else
                        setWaiting(this.Tool,false);
                        this.TuningState.IsTuning = false;
                        this.Widgets.TuneSection.TuneButton.Icon = Icon('playControl');
                    end
                else
                    %% Start Tuning
                    this.TuningState.IsTuning = true;
                    this.TuneButtonTuneListener.Enabled = false;
                    % set tune button to stop and setwaiting
                    this.Widgets.TuneSection.TuneButton.Icon = Icon('stop');
                    setWaiting(this.Tool,true,getString(message('Control:systunegui:msgForTuning')))

                    if ~matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
                        SystuneGUIOptions = setDisplayAndStopFunctions([],this.TuningState,SystuneGUIOptions);
                        this.SystuneTuningData.setOptions(SystuneGUIOptions);
                    else
                        % Tuning Report (initial) (not available in MATLAB Online)
                        createTuningReport(this,SystuneGUIOptions);
                    end

                    % set wait bar
                    postActionStatus(this.Tool.EventManager,'on',...
                        getString(message('Control:systunegui:StatusMessageTuningInProgress')));

                    % call systune
                    this.SystuneTuningData.cstAppSystune(this.SystuneTuningData);

                    % hide wait bar
                    postActionStatus(this.Tool.EventManager,'off')

                    if matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
                        update_Initial_Final_InfoInTuningReport(this,'final',this.SystuneTuningData.TuningInfo);

                        statusLabelText = getString(message('Control:systunegui:StatusMessageTuningFinished'));
                        statusButtonText = getString(message('Control:systunegui:StatusButtonText'));
                        postActionStatus(this.Tool.EventManager,@(es,ed)localShowTuningReport(this),...
                            statusLabelText,statusButtonText)
                    else
                        statusLabelText = getString(message('Control:systunegui:StatusMessageTuningFinished'));
                        postActionStatus(this.Tool.EventManager,'off',statusLabelText)
                    end
                                                            
                    setWaiting(this.Tool,false)

                    this.TuningState.IsTuning = false;
                    this.TuneButtonTuneListener.Enabled = true;
                    this.Widgets.TuneSection.TuneButton.Icon = Icon('playControl');
                end
            catch ME
                if ~strcmp(SystuneGUIOptions.Display,'off') && matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
                    % there is no report to close in Matlab Online case
                    this.TuningReport.close;
                end
                postActionStatus(this.Tool.EventManager,'off')
                setWaiting(this.Tool,false);

                this.TuningState.IsTuning = false;
                this.TuneButtonTuneListener.Enabled = true;
                this.Widgets.TuneSection.TuneButton.Icon = Icon('playControl');

                if strcmp(ME.identifier,'Control:tuning:systune7')
                    % no tunable block in genss model, probably due to zero
                    % linearization of one of the blocks
                    msg = getString(message('Control:systunegui:GeneralErrorInLinearization'));
                else
                    msg = sprintf('%s:\n%s',getString(message('Control:systunegui:GeneralErrorInTuning')),ME.message);
                end
                showError(this.Tool,msg)
            end
        end
        function Popup = populateSplitButtonPopup(this) 
            import matlab.ui.internal.toolstrip.*

            Popup = PopupList;
            Popup.Tag = 'TuneSplitButtonPopup';
            
            Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:CodegenGenerateMATLABCode'));
            Header.Tag = 'HeaderLabel';
            add(Popup,Header);

            Text = getString(message('Control:systunegui:CodegenGenerateMATLABCodeScriptTitle'));
            Desc = getString(message('Control:systunegui:CodegenGenerateMATLABCodeDescription'));
            IconCodegen =  Icon('generateScript_matlab');
            Item1 = ListItem(Text, IconCodegen);
            Item1.Description = Desc;
            add(Popup,Item1);
            addlistener(Item1,'ItemPushed', @(hSrc,hData) generateMATLABCode(this));
            
            if matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
                % do not put tuning report to dropdown in matlab online case
                Header = PopupListHeader(ctrlMsgUtils.message('Control:systunegui:TuningReportSplitButtonHeading'));
                Header.Tag = 'HeaderLabel';
                add(Popup,Header);
                
                Text = getString(message('Control:systunegui:TuningReportSplitButtonTitle'));
                Desc = getString(message('Control:systunegui:TuningReportSplitButtonDescription'));
                IconExport = Icon('export_detailsReport');
                Item2 = ListItem(Text, IconExport);
                Item2.Description = Desc;
                add(Popup,Item2);
                addlistener(Item2,'ItemPushed', @(hSrc,hData) localShowTuningReport(this));
            end
         end 

         function localShowTuningReport(this)
             %% Verify there exist tuning report
             if isempty(this.TuningReport)
                 showError(this.Tool,getString(message('Control:systunegui:TuningReportNoReport')))
                 return
             end
             show(this.TuningReport,this.Tool.AppContainer)
             pack(this.TuningReport);
         end

         function update_Initial_Final_InfoInTuningReport(this,state,TuningInfo)
             nSoft = length(TuningInfo.Soft.Names);
             nHard = length(TuningInfo.Hard.Names);

             if strcmp(state,'initial') % String at the beginning: no results, no comment
                 Running = getString(message('Control:systunegui:TuningReportRunning'));
                 Calculating = getString(message('Control:systunegui:TuningReportCalculating'));
                 ProgressStatus = Running;
                 IterationNumber = Calculating;

                 % TuningResultComment = Calculating;
                 SoftGoalComment = Calculating;
                 HardGoalComment = Calculating;

                 % TuningResultCheckMark = '';
                 SoftCheckMarkOverall = '';
                 %'<img src="file:///L:\Bcontrol\matlab\toolbox\shared\controllib\general\resources\toolstrip_icons\Confirm_16.png">'
                 SoftCheckMarks = cell(size(TuningInfo.Soft.Names));
                 HardCheckMarks = cell(size(TuningInfo.Hard.Names));

                 % 'Target for soft goals is < ' num2str(TuningInfo.SoftTarget) 'and max value 0.345 is achieved'
                 HardCheckMarkOverall = '';
                 % 'Target for soft goals is < 1 and max value 0.345 is achieved'

                 SoftGoalNames = TuningInfo.Soft.Names;
                 HardGoalNames = TuningInfo.Hard.Names;

                 % Tuning Values for Hard and Soft Goals are set to Calculating
                 for ct=1:length(TuningInfo.Soft.Names)
                     SoftValues{ct} = Calculating;
                 end
                 for ct=1:length(TuningInfo.Hard.Names)
                     HardValues{ct} = Calculating;
                 end
             elseif strcmp(state,'final')
                 if ~this.TuningState.IsTuning
                     ProgressStatus=getString(message('Control:systunegui:TuningReportTuningStopped'));
                 else
                     ProgressStatus=getString(message('Control:systunegui:TuningReportFinished'));
                 end

                 if nSoft>0
                     % Comment for Soft Goals
                     SoftMaxValue = max([TuningInfo.Soft.Values{:}]);
                     if TuningInfo.SoftTarget>0 &&  SoftMaxValue<TuningInfo.SoftTarget
                         SoftGoalComment = [ ...
                             '<td colspan="3">' ...
                             getString(message('Control:systunegui:TuningReportAchievedSoftTarget', ...
                             num2str(TuningInfo.SoftTarget),num2str(SoftMaxValue))) ...
                             '</td>'];
                     else
                         SoftGoalComment = [ ...
                             '<td>' getString(message('Control:systunegui:TuningReportWorstValue')) '</td>' ...
                             '<td>' num2str(SoftMaxValue) '</td>' ...
                             '<td>'  '</td>' ...
                             ];
                     end

                     % Names and Values for Soft Goals
                     SoftGoalNames = TuningInfo.Soft.Names;
                     SoftValues = cellfun(@(x) num2str(x),TuningInfo.Soft.Values,'UniformOutput',false);
                 end

                 if nHard>0
                     % Comment for Hard Goals
                     HardGoalComment = '';
                     NumberOfFails = sum([TuningInfo.Hard.Values{:}]>1);
                     if nHard>0
                         if NumberOfFails == 0
                             HardGoalComment = getString(message('Control:systunegui:TuningReportHardSatisfied'));
                         else
                             HardGoalComment = getString(message('Control:systunegui:TuningReportHardFailed'));
                         end
                     end

                     % Names and Values for Hard Goals (bold if it is active)
                     HardGoalNames = TuningInfo.Hard.Names;
                     HardValues = cellfun(@(x) num2str(x),TuningInfo.Hard.Values,'UniformOutput',false);

                     % Checkmarks for Hard Goals
                     %% TODO: Convert getSystuneGUIIcon to matlab.ui.internal.toolstrip.Icon once uihtml supports mw-icon-store
                     icon = 'Confirm_16.png';
                     iconPath = erase(fullfile(matlabroot,'toolbox','control','ctrlguis','+systuneapp','resources','systunegui_icons',icon),matlabroot);
                     SuccessMark = ['<img src="' iconPath '">'];
                     icon = 'Warning_16.png';
                     iconPath = erase(fullfile(matlabroot,'toolbox','control','ctrlguis','+systuneapp','resources','systunegui_icons',icon),matlabroot);
                     FailMark = ['<img src="' iconPath '">'];

                     HardCheckMarks = cell(size(TuningInfo.Hard.Names));
                     AnyFailed = false;
                     for ct=1:length(TuningInfo.Hard.Names)
                         if TuningInfo.Hard.Values{ct} <=1
                             HardCheckMarks{ct} = SuccessMark;
                         else
                             HardCheckMarks{ct} = FailMark;
                             AnyFailed = true;
                         end
                     end

                     if AnyFailed
                         HardCheckMarkOverall = FailMark;
                     else
                         HardCheckMarkOverall = SuccessMark;
                     end
                 end

                 % Checkmarks for Soft Goals and TuningResult
                 SoftCheckMarkOverall = '';
                 SoftCheckMarks = cell(size(TuningInfo.Soft.Names));

                 % Number of Iterations
                 IterationNumber = num2str(TuningInfo.Iterations);
             end

             %% Tuning Summary Title
             TuningSummaryTitle = [...
                 '<body style="font-family:Segoe UI;font-name:Segoe UI;font-style:plain;font-size:12;color:black;background-color:#F0F0F0">' ...
                 '<p>&nbsp&nbsp<b>' getString(message('Control:systunegui:TuningReportTuningSummary')) '</b></p>' ...
                 '<br/>' ...
                 '<table style="margin-left:5 px;border:1px solid gray;padding:2px 2px 2px 5px;background-color:white;width:95%">'];

             %% Tuning Progress chapter
             TuningProgressSection =  [...
                 '<tr>' ...
                 '<td width="100px">' getString(message('Control:systunegui:TuningReportTuningProgress')) '</td>' ...
                 '<td>' ProgressStatus '</td>' ...
                 '<td>'  '</td>' ...
                 '<td>'  '</td>' ...
                 '<td>'  '</td>' ...
                 '</tr>' ...
                 '<br>'];

             %% Soft Goals chapter
             if nSoft>0
                 SoftGoalHeader = [ ...
                     '<tr>' ...
                     '<td width="100px">' getString(message('Control:systunegui:TuningReportSoft')) '</td>' ...
                     SoftGoalComment ...
                     '<td>' SoftCheckMarkOverall '</td>' ...
                     '</tr>'];

                 SoftGoalBody = '';
                 for ct=1:length(TuningInfo.Soft.Names)
                     SoftGoalBody = [ SoftGoalBody ...
                         '<tr>' ...
                         '<td>'  '</td>' ...
                         '<td>' SoftGoalNames{ct} '</td>' ...
                         '<td>' SoftValues{ct} '</td>' ...
                         '<td>'  '</td>' ...
                         '<td>' SoftCheckMarks{ct} '</td>' ...
                         '</tr>' ];
                 end
                 SoftGoalsSection = [SoftGoalHeader SoftGoalBody];
             else
                 SoftGoalsSection = [ ...
                     '<tr>' ...
                     '<td width="100px">' getString(message('Control:systunegui:TuningReportSoft')) '</td>' ...
                     '<td colspan="3">' getString(message('Control:systunegui:TuningReportNone')) '</td>' ...
                     '<td>'  '</td>' ...
                     '</tr>'];
             end

             %% Hard Goals chapter
             if nHard>0
                 HardGoalHeader = [ ...
                     '<tr>' ...
                     '<td width="100px">' getString(message('Control:systunegui:TuningReportHard')) '</td>' ...
                     '<td colspan="3">' HardGoalComment '</td>' ...
                     '<td>' HardCheckMarkOverall '</td>' ...
                     '</tr>'];

                 HardGoalBody = '';
                 for ct=1:length(TuningInfo.Hard.Names)
                     HardGoalBody = [ HardGoalBody ...
                         '<tr>' ...
                         '<td>'  '</td>' ...
                         '<td>' HardGoalNames{ct} '</td>' ...
                         '<td>' HardValues{ct} '</td>' ...
                         '<td>'  '</td>' ...
                         '<td>' HardCheckMarks{ct} '</td>' ...
                         '</tr>' ];
                 end
                 HardGoalsSection = [HardGoalHeader HardGoalBody];
             else
                 HardGoalsSection = [ ...
                     '<tr>' ...
                     '<td width="100px">' getString(message('Control:systunegui:TuningReportHard')) '</td>' ...
                     '<td colspan="3">' getString(message('Control:systunegui:TuningReportNone')) '</td>' ...
                     '<td>'  '</td>' ...
                     '</tr>'];
             end


             %% Iteration chapter
             IterationsString = [
                 '<tr>' ...
                 '<td width="100px">' getString(message('Control:systunegui:TuningReportIterations')) '</td>' ...
                 '<td>' IterationNumber '</td>' ...
                 '<td>'  '</td>' ...
                 '</tr>' ...
                 ];

             %% Final Summary Section (Combine Final Summary)
             blankline = '<tr></tr>';

             FinalSummaryString = [TuningSummaryTitle ...
                 TuningProgressSection blankline ... % TuningResultSection ...
                 HardGoalsSection blankline ...
                 SoftGoalsSection blankline ...
                 IterationsString ...
                 '<tr> </tr>' ...
                 '</table>' ];

             %% Warnings Section
             if isempty(this.TuningReport.WarningText)
                 WarningsString = '';
             else
                 %% TODO: Convert getSystuneGUIIcon to matlab.ui.internal.toolstrip.Icon once uihtml supports mw-icon-store
                 icon = 'Warning_16.png';
                 iconPath = erase(fullfile(matlabroot,'toolbox','control','ctrlguis','+systuneapp','resources','systunegui_icons',icon),matlabroot);
                 FailMark = ['<img src="' iconPath '">'];
                 WarningsString = ...
                     ['<p>&nbsp&nbsp<b>' getString(message('Control:systunegui:TuningReportWarnings')) '</b></p>' ...
                     '<br/>' ...
                     '<table style="margin-left:5 px;border:1px solid gray;padding:2px 2px 2px 5px;background-color:white;width:95%">' ...
                     ];
                 for ct=1:length(this.TuningReport.WarningText)
                     WarningsString = [WarningsString ['<tr><td>' FailMark '</td><td colspan="5">' this.TuningReport.WarningText{ct} '</td></tr>']];
                 end
                 WarningsString = [WarningsString ['</tr>' '</table>']];
             end


             %% Optimization Progress Section
             OptimizationProgressTitle = ...
                 ['<p>&nbsp&nbsp<b>' getString(message('Control:systunegui:TuningReportOptimizationProgress')) '</b></p>' ...
                 '<br/>' ...
                 '<table style="margin-left:5 px;border:1px solid gray;padding:2px 2px 2px 5px;background-color:white;width:95%">'];

             FinalSummaryString = [FinalSummaryString WarningsString OptimizationProgressTitle];

             %% Update Tuning Report
             this.TuningReport.StatusText{1}=FinalSummaryString;
             updateUI(this.TuningReport);
         end
         
    end
    methods(Hidden=true) 
        function Text = generateMATLABCode(this)             
            %% Verify there exist at least one tunable block and one tuning goal
            if ~any(this.SystuneTuningData.getSelectedIndexOfTunableBlocks)
                showError(this.Tool,getString(message('Control:systunegui:CodegenNoBlock')))
                return;
            end
            if ~any(this.SystuneTuningData.getSelectedIndexOfTuningGoals)
                showError(this.Tool,getString(message('Control:systunegui:CodegenNoTuningGoal')))
                return;
            end
            
            %% add Architecture
            Text = this.SystuneTuningData.ControlDesignData.Architecture.generateMATLABCode('CL0');
            Text = vertcat(Text,{''});
            
            % add block parameterizations in slTuner case
            if this.SystuneTuningData.ControlDesignData.isSimulink
                ActiveBlockNames = this.SystuneTuningData.ControlDesignData.Architecture.TunedBlocks;
                for ct=1:length(ActiveBlockNames)
                    BlockName = ActiveBlockNames{ct};
                    BlockParam = this.SystuneTuningData.ControlDesignData.Architecture.getBlockParam(BlockName);
                    if ~isempty(BlockParam.UserData)
                        Text = vertcat(Text,BlockParam.UserData);
                        setBlockParamCode = ['setBlockParam(CL0,' '''' BlockName '''' ',' BlockParam.Name ');'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text,setBlockParamCode);
                        Text = vertcat(Text,{''});
                    end
                end
            end
            
            %% add MATLAB code for tuning goals (only active ones)                        
            % add each goal and set soft/hard            
            ActiveGoalIndex = this.SystuneTuningData.getSelectedIndexOfTuningGoals;
            ActiveGoals = this.SystuneTuningData.TuningGoals(ActiveGoalIndex,:);
            for ct=1:size(ActiveGoals,1)
                Text = vertcat(Text,ActiveGoals{ct,1}.MetaData.MATLABCode);  
                Text = vertcat(Text,{''});
            end            
            
            %% define options
            Text = systuneapp.util.appendMATLABCodeForOptions(Text,this.SystuneTuningData.Options); 
            Text = vertcat(Text,{''});
            
            %% set hard and soft goals
            GoalsComment = ['%% ' getString(message('Control:systunegui:CodegenSetGoals'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,GoalsComment); 
            [HardGoals,SoftGoals] = this.SystuneTuningData.getActiveTuningGoalName;            
            if ~isempty(SoftGoals)                
                SoftGoals = cellfun(@(x) systuneapp.util.createVariableName(x),SoftGoals,'UniformOutput',false);
                SoftGoalsText = systuneapp.util.createVariableArrayFromCellString(SoftGoals,'SoftGoals');
                Text = vertcat(Text,SoftGoalsText);
            else
                Text = controllib.internal.codegen.appendMATLABCode(Text,'SoftGoals = [];',[]);
            end            
            if ~isempty(HardGoals)
                HardGoals = cellfun(@(x) systuneapp.util.createVariableName(x),HardGoals,'UniformOutput',false);
                HardGoalsText = systuneapp.util.createVariableArrayFromCellString(HardGoals,'HardGoals');
                Text = vertcat(Text,HardGoalsText);                                                
            else
                Text = controllib.internal.codegen.appendMATLABCode(Text,'HardGoals = [];',[]);
            end
            Text = vertcat(Text,{''});
                        
            %% set inactive blocks
            
            TunableBlocksList = this.SystuneTuningData.getTunableBlock;
            TunableBlocks(:,1) = [TunableBlocksList{:,1}];
            ActiveTunableBlocksIndex = [TunableBlocksList{:,2}]';
            BlocksToFold = TunableBlocks(~ActiveTunableBlocksIndex);
            if ~isempty(BlocksToFold)
                if this.Tool.ControlDesignData.isSimulink
                    for ct = 1:numel(BlocksToFold)
                        % title
                        InactiveBlocksComment = ['%% ' getString(message('Control:systunegui:CodegenInactiveBlock', BlocksToFold(ct).BlockPath))];
                        Text = controllib.internal.codegen.appendMATLABCode(Text,InactiveBlocksComment);
                        
                        % get the block parameterization
                        getBlockParamCode = [BlocksToFold(ct).Name ' = getBlockParam(CL0,' '''' BlocksToFold(ct).BlockPath '''' ');'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text,getBlockParamCode);
                        
                        % set free to false
                        if isa(BlocksToFold(ct).getParameterization, 'genss')
                            BlockNames = fieldnames(BlocksToFold.getParameterization.Blocks);
                            for idx = 1:numel(BlockNames)
                                Text = systuneapp.util.appendMATLABCodeForFieldFree(Text, false, [BlocksToFold(ct).Name, '.Blocks.', BlockNames{idx}], class(BlocksToFold.getParameterization.Blocks.(BlockNames(idx))));
                            end
                        else
                            Text = systuneapp.util.appendMATLABCodeForFieldFree(Text, false, BlocksToFold(ct).Name, class(BlocksToFold(ct).getParameterization));
                        end
                        
                        % set the block parameterization
                        setBlockParamCode = ['setBlockParam(CL0,' '''' BlocksToFold(ct).BlockPath '''' ',' BlocksToFold(ct).Name ');'];
                        Text = controllib.internal.codegen.appendMATLABCode(Text,setBlockParamCode);
                        Text = vertcat(Text,{''});
                    end
                else
                    for ct = 1:numel(BlocksToFold)
                        % title
                        InactiveBlocksComment = ['%% ' getString(message('Control:systunegui:CodegenInactiveBlock', BlocksToFold(ct).BlockPath))];
                        Text = controllib.internal.codegen.appendMATLABCode(Text,InactiveBlocksComment);
                        
                        % set free to false
                        
                        Text = systuneapp.util.appendMATLABCodeForFieldFree(Text, false, ['CL0.Blocks.', BlocksToFold(ct).Name], class(BlocksToFold(ct).getParameterization));
                        
                        Text = vertcat(Text,{''});
                    end
                end
            end

            %% call systune command
            SystuneComment = ['%% ' getString(message('Control:systunegui:CodegenSystune'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,SystuneComment);
            SystuneCode = '[CL1,fSoft,gHard,Info] = systune(CL0,SoftGoals,HardGoals,Options);';
            Text = controllib.internal.codegen.appendMATLABCode(Text,SystuneCode);
            Text = vertcat(Text,{''});
            
            %% view tuning results
            ViewSpecComment = ['%% ' getString(message('Control:systunegui:CodegenViewSpec'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,ViewSpecComment);
            ViewSpecCode = '% viewSpec([SoftGoals;HardGoals],CL1);';
            Text = controllib.internal.codegen.appendMATLABCode(Text,ViewSpecCode);            
            
            %% generate MATLAB Code
            controllib.internal.codegen.showGeneratedMATLABCode(Text,false);            
        end
    end      
end

%% Tuning Report Local Functions
function NotifyNewReportText(ReportText,str)
if matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
    % no event fire in Matlab Online since there is no tuning report
    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(str);
    notify(ReportText,'NewData',ed)
end
end
function NotifyNewWarningText(ReportText,str)
if matlab.internal.capability.Capability.isSupported(matlab.internal.capability.Capability.ComplexSwing)
    % no event fire in Matlab Online since there is no tuning report
    ed = ctrluis.toolstrip.dataprocessing.GenericEventData(str);
    notify(ReportText,'NewWarning',ed)
end
end
function accumulateWarningsInTuningReport(Report,ed)
Report.WarningText{end+1} = ed.Data;
end
function updateIterationInTuningReport(Report,ed)
str=ed.Data;

%% Preprocess upcoming strings
% replace messages containing systuneOptions
switch str
    case getString(message('Control:tuning:systune12'))
        str = getString(message('Control:systunegui:TuningReportTuningOptions1'));
    case getString(message('Control:tuning:systune23'))
        str = getString(message('Control:systunegui:TuningReportTuningOptions2'));        
end


%%
% check whether multiple line data, do not edit, just put the data
strArray = regexp(str,'\n','split');
if numel(strArray)>1 % multiple line
    str = strArray; % current string is replaced with cell array
end

AlphaInfo = regexp(str, '(?=alp)[^"]+(?=:)', 'match');
IterInfo = regexp(str, '(?=It)[^"]+(?=:)', 'match');
FinalInfo = regexp(str, '(?=Fi)[^"]+(?=:)', 'match');
%DesignInfo = regexp(str, '(?=Des)[^"]+(?=:)', 'match');

if ~isempty(str)
    if iscell(str) % multi-line, put each lines sequentially
        strCombined = '';
        for ct=1:numel(str)
            strCombined = [strCombined '<tr><td colspan="4">' str{ct} '</td></tr>']; 
        end
        str = strCombined;
    elseif ~isempty(AlphaInfo) % this is an alpha line
        SoftInfo = regexp(str, '(?=So)[^"]+(?=, H)', 'match');
        HardInfo = regexp(str, '(?=Ha)[^"]+(?=, I)', 'match');
        IterationsInfo = regexp(str, '(?=It)[^"]+(?=)', 'match');
        
        str = [...
            '<tr>' ...
            '<td>' AlphaInfo{1} '</td>' ...
            '<td>' SoftInfo{1} '</td>' ...
            '<td>' HardInfo{1} '</td>' ...
            '<td>' IterationsInfo{1} '</td>' ...
            '</tr>' ...
            ];
    elseif ~isempty(IterInfo) % this is an iter line
        ObjectiveInfo = regexp(str, '(?=Ob)[^"]+(?=, P)', 'match');
        ProgressInfo = regexp(str, '(?=Pr)[^"]+(?<=%)', 'match');
        
        str = [...
            '<tr>' ...
            '<td>'  '</td>' ...
            '<td>' IterInfo{1} '</td>' ...
            '<td>' ObjectiveInfo{1} '</td>' ...
            '<td>' ProgressInfo{1} '</td>' ...
            '</tr>' ...
            ];
    elseif ~isempty(FinalInfo) % this is a final line
        SoftInfo = regexp(str, '(?=So)[^"]+(?=, H)', 'match');
        HardInfo = regexp(str, '(?=Ha)[^"]+(?=, I)', 'match');
        IterationsInfo = regexp(str, '(?=It)[^"]+(?=)', 'match');
        
        str = [...
            '<tr>' ...
            '<td>' FinalInfo{1} '</td>' ...
            '<td>' SoftInfo{1} '</td>' ...
            '<td>' HardInfo{1} '</td>' ...
            '<td>' IterationsInfo{1} '</td>' ...
            '</tr>' ...
            ];
    else % multiple column line other than alpha, iter or final lines
        str = ['<tr><td colspan="4">' str '</td></tr>'];
    end
    
    Report.StatusText{end+1} = str;
    updateUI(Report);
end
end

function stop = stopOptimization(TuningState)
drawnow; % Flush the event queue
stop = ~TuningState.IsTuning;
end

function SystuneGUIOptions = setDisplayAndStopFunctions(ReportText,TuningState,SystuneGUIOptions)
% Set Display and Stop Functions
    SystuneGUIOptions.Hidden.StopFcn = @() stopOptimization(TuningState);
    SystuneGUIOptions.Hidden.Trace.DisplayFcn = @(str) NotifyNewReportText(ReportText,str);
    SystuneGUIOptions.Hidden.Trace.WarnFcn = @(ME) NotifyNewWarningText(ReportText,getString(ME));
end

