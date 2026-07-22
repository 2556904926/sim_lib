classdef DataSourcePlot < handle
    %DATASOURCEPLOT
    
    % Author(s): Baljeet Singh 13-Nov-2013
    % Copyright 2013-2024 The MathWorks, Inc.
    
    properties
        Sources
        HeaderStrings
        MetricTableSize = [7 3]
        isSimulink
        showBaselineString
        ViewedPlants
        ViewedPlants_
        TunerTC
    end
    properties (SetObservable = true)
       MetricTableModel
       ParameterTableModel 
    end
    properties (Dependent = true)
        NumPlants
        ValidResponses
        SelectedPlantName
    end
    properties (Dependent = true, SetObservable = true)
        QuickRefreshMode
        showBaseline
    end
    properties (Dependent = true, SetObservable = true, AbortSet)
        hasBaseline
    end
    properties (SetObservable = true, AbortSet = true)
        TimeUnit = 'seconds'
    end
    properties (Dependent = true)
        FreqUnit
        ViewDOF
    end
    properties (Access = private)
        PlantNames
        SelectedPlantIndex
        SampledPlants
        StabilityContents
        TimeUnitString = 'sec'
        FreqUnitString = 'rad/s'
        BaselineLabel = pidtool.utPIDgetStrings('cst','plotpanel_baseresp')
        QuickRefreshMode_ = false
        showBaseline_ = true
        hasBaseline_ = true
        ParameterLabels
    end
    events
        processedPlantsEvent
    end
    properties (SetAccess = private)
        ActiveFigure
        ActiveFigureType
    end
    methods
        function this = DataSourcePlot(tunertc)
            %DATASOURCEPLOT
            this.TunerTC = tunertc;
            
            this.updateBaselineValidity();
            if strcmp(this.TunerTC.ToolType,'MATLAB')
                this.isSimulink = false;
                this.BaselineLabel = pidtool.utPIDgetStrings('cst','plotpanel_baseresp');
                str1 = pidtool.utPIDgetStrings('cst','plotpanel_tunedtitle');
                str2 = pidtool.utPIDgetStrings('cst','plotpanel_basetitle');
                this.showBaselineString = pidtool.utPIDgetStrings('cst','strShowBaseline');
            else
                this.isSimulink = true;
                this.BaselineLabel = pidtool.utPIDgetStrings('scd','plotpanel_baseresp');
                str1 = pidtool.utPIDgetStrings('scd','plotpanel_tunedtitle');
                str2 = pidtool.utPIDgetStrings('scd','plotpanel_basetitle');
                this.showBaselineString = pidtool.utPIDgetStrings('scd','strShowBaseline');
            end
            
            if this.TunerTC.IsBaselineStable == 1
                this.showBaseline_ = true;
            else
                this.showBaseline_ = false;
            end
            %=========================================================================================(Parameter Table Model)
            ParameterData = cell([6 3]);
            ParameterData(:)={blanks(6)};
            this.HeaderStrings = {'' str1 str2};
            this.ParameterTableModel = ParameterData;
            %============================================================================================(Metric Table Model)
            tmp = blanks(4);
            MetricData = {pidtool.utPIDgetStrings('cst','plotpanel_metric1'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric2'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric3'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric4'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric5'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric6'),tmp,tmp;...
                pidtool.utPIDgetStrings('cst','plotpanel_metric7'),tmp,tmp};
            this.MetricTableModel = MetricData;
            StableStr = pidtool.utPIDgetStrings('cst','tunerdlg_stable');
            UnstableStr = pidtool.utPIDgetStrings('cst','tunerdlg_unstable');
            this.StabilityContents = {UnstableStr,StableStr,'Undefined'};
            %======================================================================================(Build and Update Sources)
            this.updatePlantsInfo();
            this.ViewedPlants = true(1,this.NumPlants);
            this.ViewedPlants_ = struct(this.PlantNames{end},0);
            this.build();
            this.updateDesiredCharacteristics([],[]);
            this.update(true, true);
        end
        %=================================================================================================(TunerTC Listeners)
        function set.TunerTC(this, val)
            %SET_TUNERTC
            this.TunerTC = val;
            addlistener(this.TunerTC.ControllerList,'TunedController','PostSet', @(~,~)update(this, true, false));
            addlistener(this.TunerTC.ControllerList,'BaselineController','PostSet', @(~,~)cbBaselineControllerPostSet(this));
            addlistener(this.TunerTC.ControllerList,'DesiredController','PostSet', @this.updateDesiredCharacteristics);
        end
        %=========================================================================================(Update Plants Information)
        function updatePlantsInfo(this)
            %UPDATEPLANTSINFO
            this.PlantNames = this.TunerTC.PlantList.PlantNames;
            this.SelectedPlantIndex = this.TunerTC.PlantList.SelectedPlantIndex;
            this.TimeUnit = this.TunerTC.PlantList.SelectedPlantTimeUnit;
            this.SampledPlants = this.TunerTC.PlantList.SampledPlants;
            [this.TimeUnitString, this.FreqUnitString] = pidtool.utPIDgetUnitString(this.TimeUnit);
        end
        %=======================================================================================================(Add sources)
        function build(this)
            %BUILD
            numPlants = this.NumPlants;
            this.Sources = createArray(numPlants,2,6,"pidtool.LTIDataSource",FillValue=tf(nan));
            for i = 1:numPlants
                for j = 1:6
                    this.Sources(i,1,j) = pidtool.LTIDataSource(tf(nan));
                    this.Sources(i,2,j) = pidtool.LTIDataSource(tf(nan));
                end
            end
            this.updateSourceNames();
            this.updateSelectedSource();
        end
        %=====================================================================================================(Update Models)
        function update(this, tuned, baseline)
            %UPDATE
            numPlant = this.NumPlants;
            WarningState = warning('off'); %#ok<WNOFF>
            if tuned
                C = this.TunerTC.ControllerList.TunedController;
                cdata = this.TunerTC.ControllerList.getTunedPIDData(this.isSimulink);
                for i = 1:numPlant
                    if this.ViewedPlants(i)
                        G = this.SampledPlants{i};
                        [olsys, r2y, r2u, id2y, od2y] = pidtool.utPIDgetLoopfromC(C,G);
                        this.Sources(i,1,1).Model = olsys;
                        this.Sources(i,1,2).Model = r2y;
                        this.Sources(i,1,3).Model = r2u;
                        this.Sources(i,1,4).Model = id2y;
                        this.Sources(i,1,5).Model = od2y;
                        this.Sources(i,1,6).Model = G;
                        if i == this.TunerTC.PlantList.SelectedPlantIndex
                            s = pidtool.utPIDgetmetrics(olsys, r2y);
                            this.updateMetricsTable(s, 2, this.TunerTC.IsTunedStable);
                            this.updateParameterValues(2, cdata.Type,cdata.DOF,cdata.P,cdata.I,cdata.D,cdata.FC,cdata.b,cdata.c);
                        end
                    end
                end
            end
            if baseline
                C = this.TunerTC.ControllerList.SampledBaselineController;
                if ~isempty(C)
                    cdata = this.TunerTC.ControllerList.getBaselinePIDData(this.isSimulink);
                    for i = 1:numPlant
                        G = this.SampledPlants{i};
                        [olsys,r2y,r2u,id2y,od2y] = pidtool.utPIDgetLoopfromC(C,G);
                        this.Sources(i,2,1).Model = olsys;
                        this.Sources(i,2,2).Model = r2y;
                        this.Sources(i,2,3).Model = r2u;
                        this.Sources(i,2,4).Model = id2y;
                        this.Sources(i,2,5).Model = od2y;
                        this.Sources(i,2,6).Model = G;
                        if i == this.TunerTC.PlantList.SelectedPlantIndex
                            s = pidtool.utPIDgetmetrics(olsys,r2y);
                            this.updateMetricsTable(s,3,this.TunerTC.IsBaselineStable);
                            this.updateParameterValues(3,cdata.Type,cdata.DOF,cdata.P,cdata.I,cdata.D,cdata.FC,cdata.b,cdata.c);
                        end
                    end
                end
            end
            if ~this.QuickRefreshMode_
                QRM = this.QuickRefreshMode_;
                this.QuickRefreshMode = QRM;
            end
            warning(WarningState);
        end
        %=====================================================================================================(Update Tables)
        function updateMetricsTable(this, s, col, isstable)
            %UPDATEMETRICSTABLE
            Data = this.MetricTableModel;
            Data{1,col} = sprintf('%0.3g %s',s.RiseTime,this.TimeUnitString);
            Data{2,col} = sprintf('%0.3g %s',s.SettlingTime,this.TimeUnitString);
            Data{3,col} = sprintf('%0.3g %s',s.Overshoot,'%');
            Data{4,col} = sprintf('%0.3g',s.Peak);
            Data{5,col} = sprintf('%0.3g dB @ %0.3g %s',20*log10(s.GainMargin),s.GainMarginAt,this.FreqUnitString);
            Data{6,col} = sprintf('%0.3g deg @ %0.3g %s',s.PhaseMargin,s.PhaseMarginAt,this.FreqUnitString);
            Data{7,col} = this.StabilityContents{isstable+1};
            this.MetricTableModel = Data;
        end
        function updateParameterLabels(this)
            %UPDATEPARAMETERLABELS
            Data = this.ParameterTableModel;
            ctype = this.TunerTC.ControllerList.DesiredType;
            if this.isSimulink
                Data(1,1) = {'P'};
                Data(2,1) = {'I'};
                Data(3,1) = {'D'};
                Data(4,1) = {'N'};
            else
                if strcmp(this.TunerTC.ControllerList.DesiredForm,'parallel')
                    Data(1,1) = {'Kp'};
                    Data(2,1) = {'Ki'};
                    Data(3,1) = {'Kd'};
                    Data(4,1) = {'Tf'};
                else
                    Data(1,1) = {'Kp'};
                    Data(2,1) = {'Ti'};
                    Data(3,1) = {'Td'};
                    Data(4,1) = {'N'};
                end
            end
            if this.ViewDOF == 1
                Data(5,1) = {' '};
                Data(6,1) = {' '};
            else
                Data(5,1) = {'b'};
                Data(6,1) = {'c'};
                if this.TunerTC.ControllerList.fixBC
                    if any(ctype == 'p')
                        Data(5,1) = {'b (fixed)'};
                    end
                    if any(ctype == 'd')
                        Data(6,1) = {'c (fixed)'};
                    end
                end
            end
            this.ParameterTableModel = Data;
            this.ParameterLabels = Data(:,1);
        end
        function updateParameterValues(this, col, Type, DOF, P, I, D, N, b, c)
            %UPDATEPARAMETERVALUES
            Data = this.ParameterTableModel;
            switch Type
                case 'p'
                    Data{1,col} = num2str(P);
                    Data{2,col} = 'n/a';
                    Data{3,col} = 'n/a';
                    Data{4,col} = 'n/a';
                case 'i'
                    Data{1,col} = 'n/a';
                    Data{2,col} = num2str(I);
                    Data{3,col} = 'n/a';
                    Data{4,col} = 'n/a';
                case 'pi'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = 'n/a';
                    Data{4,col} = 'n/a';
                case 'pd'
                    Data{1,col} = num2str(P);
                    Data{2,col} = 'n/a';
                    Data{3,col} = num2str(D);
                    Data{4,col} = 'n/a';
                case 'pdf'
                    Data{1,col} = num2str(P);
                    Data{2,col} = 'n/a';
                    Data{3,col} = num2str(D);
                    Data{4,col} = num2str(N);
                case 'pid'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = num2str(D);
                    Data{4,col} = 'n/a';
                case 'pidf'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = num2str(D);
                    Data{4,col} = num2str(N);
                case 'pi2'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = 'n/a';
                    Data{4,col} = 'n/a';
                    Data{5,col} = num2str(b);
                    Data{6,col} = 'n/a';
                case 'pd2'
                    Data{1,col} = num2str(P);
                    Data{2,col} = 'n/a';
                    Data{3,col} = num2str(D);
                    Data{4,col} = 'n/a';
                    Data{5,col} = num2str(b);
                    Data{6,col} = num2str(c);
                case 'pdf2'
                    Data{1,col} = num2str(P);
                    Data{2,col} = 'n/a';
                    Data{3,col} = num2str(D);
                    Data{4,col} = num2str(N);
                    Data{5,col} = num2str(b);
                    Data{6,col} = num2str(c);
                case 'pid2'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = num2str(D);
                    Data{4,col} = 'n/a';
                    Data{5,col} = num2str(b);
                    Data{6,col} = num2str(c);
                case 'pidf2'
                    Data{1,col} = num2str(P);
                    Data{2,col} = num2str(I);
                    Data{3,col} = num2str(D);
                    Data{4,col} = num2str(N);
                    Data{5,col} = num2str(b);
                    Data{6,col} = num2str(c);
            end
            if this.ViewDOF==2
                if DOF == 1
                    Data{5,col} = 'n/a';
                    Data{6,col} = 'n/a';
                end
            else
                Data{5,col} = ' ';
                Data{6,col} = ' ';
            end
            
            this.ParameterTableModel = Data;
            this.showPIDGains();
        end
        %===================================================================================(Update Source names for legends)
        function updateSourceNames(this)
            %UPDATESOURCENAMES
            numPlants = this.NumPlants;
            for i = 1:numPlants
                [lbl1, lbl2, plantname] = this.getSourceName(i);
                for j = 1:5
                    this.Sources(i,1,j).Name = lbl1;
                    this.Sources(i,2,j).Name = lbl2;
                    this.Sources(i,1,j).PlantName = plantname;
                end
                this.Sources(i,1,6).Name = plantname;
                this.Sources(i,2,6).Name = '';
                this.Sources(i,1,6).PlantName = plantname;
            end
        end
        %========================================================================(Set Desired Controller Type for Tabel Data)
        function updateDesiredCharacteristics(this,~,~)
            %UPDATEDESIREDCHARACTERISTICS
            this.updateParameterLabels();
        end
        %===================================================================================================(Plants callback)
        function handlePlantsEvent(this, evnt)
            %PLANTLISTCALLBACK
            this.QuickRefreshMode = true;
            if evnt.RenamedAt
                this.renameSourceAt(evnt.RenamedAt);
            elseif evnt.Added
                this.addSource();
            elseif evnt.RemovedAt
                this.removeSourceAt(evnt.RemovedAt);
            end
            notify(this,'processedPlantsEvent',...
                pidtool.desktop.pidtuner.tc.PlantsEventData(evnt.Added, evnt.RemovedAt, evnt.RenamedAt));
        end
        function addSource(this)
            %ADDSOURCE
            N = size(this.Sources, 1);
            tmpSrcs = createArray(N+1,2,6,"pidtool.LTIDataSource",FillValue=tf(nan));
            tmpSrcs(1:N,:,:) = this.Sources(1:N,:,:);
            this.Sources = tmpSrcs;
            for j = 1:6
                this.Sources(N+1,1,j) = pidtool.LTIDataSource(tf(1,1));
                this.Sources(N+1,2,j) = pidtool.LTIDataSource(tf(1,1));
            end
            this.updatePlantsInfo();
            this.ViewedPlants = [this.ViewedPlants; false];
            this.ViewedPlants_.(this.PlantNames{end}) =  0;
            this.updateSourceNames();
        end
        function renameSourceAt(this, id)
            %RENAMESOURCEAT
            this.PlantNames = this.TunerTC.PlantList.PlantNames;
            this.renameViewedPlant();
            [lbl1, lbl2, plantname] = this.getSourceName(id);
            for j = 1:5
                this.Sources(id,1,j).Name = lbl1;
                this.Sources(id,2,j).Name = lbl2;
                this.Sources(id,1,j).PlantName = plantname;
            end
            this.Sources(id,1,6).Name = plantname;
            this.Sources(id,2,6).Name = '';
            this.Sources(id,1,6).PlantName = plantname;
        end
        function removeSourceAt(this, id)
            %REMOVESOURCEAT
            removedplant = this.PlantNames{id};
            this.PlantNames = this.TunerTC.PlantList.PlantNames;
            this.SampledPlants(id) = [];
            this.SelectedPlantIndex = this.TunerTC.PlantList.SelectedPlantIndex;
            this.ViewedPlants(id) = [];
            this.ViewedPlants_ = rmfield(this.ViewedPlants_, removedplant);
            this.Sources(id,:,:) = [];
            this.updateSourceNames();
            this.updateSelectedSource();
        end
        %===========================================================================================(Selected Plant callback)
        function handleSelectedPlantIndexEvent(this)
            %SELECTEDPLANTCALLBACK
            if ~this.QuickRefreshMode
                this.QuickRefreshMode = true;
            end
            this.updatePlantsInfo();
            this.updateSelectedSource();
            %             this.QuickRefreshMode = false;
        end
        function updateSelectedSource(this)
            %UPDATESELECTEDSOURCE
            id = this.SelectedPlantIndex;
            for i = 1:this.NumPlants
                if i == id
                    for j = 1:6
                        this.Sources(i,1,j).isSelectedPlant = true;
                        this.Sources(i,2,j).isSelectedPlant = true;
                    end
                elseif this.Sources(i,1,1).isSelectedPlant
                    for j = 1:6
                        this.Sources(i,1,j).isSelectedPlant = false;
                        this.Sources(i,2,j).isSelectedPlant = false;
                    end
                end
            end
        end
        %================================================================================================(Quick Refresh Mode)
        function val = get.QuickRefreshMode(this)
            %GET_QUICKREFRESHMODE
            val = this.QuickRefreshMode_;
        end
        function set.QuickRefreshMode(this, val)
            %SET_QUICKREFRESHMODE
            this.QuickRefreshMode_ = val;
        end
        %=(Baseline settings)
        function val = get.hasBaseline(this)
            val = this.hasBaseline_;
        end
        function set.hasBaseline(this, val)
            this.hasBaseline_ = val;
            this.showBaseline_ = val;
        end
        function val = get.showBaseline(this)
            val = this.showBaseline_;
        end
        function set.showBaseline(this, val)
            if ~this.hasBaseline
                this.showBaseline_ = false;
            else
                this.showBaseline_ = val;
                this.updateParameterLabels();
            end
        end
        function val = getStepXlimNeeded(this,looptype)
            RT = 2/this.TunerTC.InputVariables.WC; % rise-time
            if strcmp(looptype,'id2y')
                val = [RT 1000*RT 4000*RT];
            else
                val = [RT/2 10*RT 40*RT];
            end
        end
        %==================================================================================================(Helper functions)
        function addViewedPlant(this, plantname)
            this.ViewedPlants_.(plantname) = this.ViewedPlants_.(plantname)+1;
            for i = 1:this.NumPlants
                this.ViewedPlants(i) =  (this.ViewedPlants_.(this.PlantNames{i}) > 0);
            end
        end
        function removeViewedPlant(this, plantname)
            this.ViewedPlants_.(plantname) = this.ViewedPlants_.(plantname)-1;
            for i = 1:this.NumPlants
                this.ViewedPlants(i) =  (this.ViewedPlants_.(this.PlantNames{i}) > 0);
            end
        end
        function renameViewedPlant(this)
            plantnames = this.PlantNames;
            viewedplantnames = fieldnames(this.ViewedPlants_);
            removedplant = setdiff(viewedplantnames, plantnames);
            newplant = setdiff(plantnames, viewedplantnames);
            if ~isempty(removedplant)
                this.ViewedPlants_.(newplant{1}) = this.ViewedPlants_.(removedplant{1});
                this.ViewedPlants_ = rmfield(this.ViewedPlants_, removedplant{1});
                for i = 1:this.NumPlants
                    this.ViewedPlants(i) =  (this.ViewedPlants_.(this.PlantNames{i}) > 0);
                end
            end
        end
        function updateBaselineValidity(this)
            C = this.TunerTC.ControllerList.BaselineController;
            if isempty(C)
                this.hasBaseline = false;
            else
                this.hasBaseline = true;
            end
        end
        function val = get.NumPlants(this)
            %GET_NUMPLANTS
            val = length(this.PlantNames);
        end
        function srcs = getLoopSources(this, LoopType)
            %GETLOOPSOURCES
            switch LoopType
                case 'olsys'
                    srcs = this.Sources(:,:,1);
                case 'r2y'
                    srcs = this.Sources(:,:,2);
                case 'r2u'
                    srcs = this.Sources(:,:,3);
                case 'id2y'
                    srcs = this.Sources(:,:,4);
                case 'od2y'
                    srcs = this.Sources(:,:,5);
                case 'p'
                    srcs = this.Sources(:,:,6);
                otherwise
                    error('Invalid loop type specified.');
            end
        end
        function val = get.ValidResponses(this)
            %GET_VALIDRESPONSES
            numPlants = this.NumPlants;
            Cb = this.TunerTC.ControllerList.BaselineController;
            val = true(numPlants,2);
            for i = 1:numPlants
                G = this.SampledPlants{i};
                if isfinite(G)
                    val(i,1) = true;
                else
                    val(i,1) = false;
                end
                if ~isempty(Cb)
                    if Cb.Ts == G.Ts
                        val(i,2) = true;
                    else
                        val(i,2) = false;
                    end
                else
                    val(i,2) = false;
                end
            end
        end
        function [lbl1, lbl2, plantname] = getSourceName(this, i)
            %GETSOURCENAME
            plantname = this.PlantNames{i};
            if this.NumPlants > 1
                lbl1 = [pidtool.utPIDgetStrings('cst','plotpanel_tunedresp') ',' plantname];
                lbl2 = [this.BaselineLabel ',' plantname];
            else
                lbl1 = pidtool.utPIDgetStrings('cst','plotpanel_tunedresp');
                lbl2 = [this.BaselineLabel];
            end
        end
        function val = get.FreqUnit(this)
            %GET_FREQUNIT
            if strcmp(this.TimeUnit,'seconds')
                val = 'rad/s';
            else
                val = ['rad/' this.TimeUnit(1:end-1)];
            end
        end
        function val = get.SelectedPlantName(this)
            val = this.TunerTC.PlantList.SelectedPlantName;
        end
        
        function showPIDGains(this, cdata)
            if nargin<2
                cdata = this.TunerTC.ControllerList.getTunedPIDData(this.isSimulink);
            end
            Names = this.ParameterLabels;
            switch cdata.Type
                case 'p'
                    str = sprintf('%s = %2.4g',Names{1}, cdata.P);
                case 'i'
                    str = sprintf('%s = %2.4g',Names{2},cdata.I);
                case 'pi'
                    str = sprintf('%s = %2.4g, %s = %2.4g',Names{1}, cdata.P, Names{2}, cdata.I);
                case 'pd'
                    str = sprintf('%s = %2.4g, %s = %2.4g',Names{1}, cdata.P, Names{3}, cdata.D);
                case 'pid'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{2}, cdata.I, Names{3}, cdata.D);
                case 'pdf'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{3}, cdata.D, Names{4}, cdata.FC);
                case 'pidf'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{2}, cdata.I, Names{3}, cdata.D, Names{4}, cdata.FC);
                case 'pi2'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{2}, cdata.I,Names{5}, cdata.b);
                case 'pd2'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{3}, cdata.D,Names{5}, cdata.b, Names{6}, cdata.c);
                case 'pid2'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{2}, cdata.I, Names{3}, cdata.D,Names{5}, cdata.b, Names{6}, cdata.c);
                case 'pdf2'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{3}, cdata.D, Names{4}, cdata.FC,Names{5}, cdata.b, Names{6}, cdata.c);
                case 'pidf2'
                    str = sprintf('%s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g, %s = %2.4g',...
                        Names{1}, cdata.P, Names{2}, cdata.I, Names{3}, cdata.D, Names{4}, cdata.FC,Names{5}, cdata.b, Names{6}, cdata.c);
            end
            
            if ~isempty(this.TunerTC.StatusBar)
                msg = getString(message('Control:pidtool:plotpanel_parametertablebox'));
                msg = ['  ',msg, ': ',str];
                this.TunerTC.StatusBar.setText(msg,[],'east');
            end
        end
        
        function setActiveFigure(this, fig)
            figname = get(fig, 'Name');
            if isequal(this.ActiveFigure,fig) && ~isempty(strfind(figname,this.ActiveFigureType))
                return;
            end
            this.ActiveFigure = fig;
            if ~isempty(strfind(figname,'Bode'))
                this.ActiveFigureType = 'Bode';
            else
                this.ActiveFigureType = 'Step';
            end
            if isa(this.TunerTC.PlantList.SelectedPlant,'frd') && strcmp(this.ActiveFigureType,'Step')
                this.TunerTC.setStatusText(pidtool.utPIDgetStrings('cst', 'strUseBodeWarn'), 'warn');
            else
                this.TunerTC.clearStatusText({pidtool.utPIDgetStrings('cst', 'strUseBodeWarn')});
            end
        end
        function val = get.ViewDOF(this)
            baseDOF = this.TunerTC.ControllerList.BaselineDOF;
            if isempty(baseDOF)
                baseDOF = 0;
            end
            tunedDOF = this.TunerTC.ControllerList.TunedDOF;
            
            val = max(tunedDOF,this.showBaseline*baseDOF);
        end
    end
end
function cbBaselineControllerPostSet(this)
updateBaselineValidity(this);
update(this, false, true);
end
