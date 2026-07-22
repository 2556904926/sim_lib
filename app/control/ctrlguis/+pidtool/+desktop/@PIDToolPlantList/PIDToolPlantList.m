classdef PIDToolPlantList < handle
    %PIDTOOLPLANTLIST
    
    % Author(s): A. Zimmerman April 2020
    % Copyright 2020-2021 The MathWorks, Inc.
    
    properties (SetObservable = true, AbortSet = true)
        LocalWorkspace = struct
        SampleTime % if specified, overrides selected plant sample time (e.g. Simulink case)
        TimeUnit   % if specified, overrides selected plant time unit
    end
    properties (SetObservable = true, Dependent = true)
        SelectedPlantIndex
    end
    properties
        PlantNames = {}
        StatusBar
    end
    properties (Dependent = true)
        Plants
        NumPlants
        SampledPlants
        SelectedPlant
        SelectedPlantName
        SelectedPlantSampleTime
        SelectedPlantTimeUnit
        SelectedPlantNUP
        SelectedPlantInspectorData
    end
    properties (Access = private)
        NUPData
        InspectorData
        SelectedPlantIndex_ = 0
        SelectedPlant_
        enabledWSListener = true
        LocalWorkspaceView
    end
    properties (SetAccess = private)
        isSelectedPlantAdded
    end
    events
        OpenLoopRelinearizationRequested
        ClosedLoopRelinearizationRequested
        PlantIdentificationRequested
        PlantsEvent
        ImportRequested
    end
    methods
        function this = PIDToolPlantList(varargin)
            %PIDTOOLPLANTLIST
            if nargin > 0
                for i = 1:nargin
                    G = varargin{i};
                    if ~isempty(inputname(i))
                        name = inputname(i);
                    elseif ~isempty(G.Name)
                        name = G.Name;
                    else
                        name = 'Plant';
                    end
                    this.addPlant(G, 0,[], name);
                end
            end
        end
%         function set.LocalWorkspace(this, val)
            %SET
%             this.LocalWorkspace = val;
%             addlistener(this.LocalWorkspace, 'ComponentChanged', @(~, evnt) localWorkspaceChangeCallback(this, evnt));
%         end
        function setPlantListBrowser(this, val)
            %SET
%             this.LocalWorkspace = val.LocalWorkspace;
%             this.LocalWorkspaceView = val.LocalWorkspaceView;
        end
        function addPlant(this, val, NUP, inspectordata, plantname)
            %ADDPLANT
            if val.Ts < 0
                ctrlMsgUtils.error('Control:design:pidtune4','pidtool');
            end
            if nargin == 5 && ~isempty(plantname)
                name = plantname;
            elseif ~isempty(inputname(2))
                name = inputname(2);
            else
                name = 'Plant';
            end
            allnames = this.PlantNames;
            k = 1;
            while ismember(name, allnames)
                name = sprintf('%s%d','Plant',k);
                k = k+1;
            end
            if ~isempty(this.StatusBar)
                this.StatusBar.reset;
                this.StatusBar.showWaitBar(ctrlMsgUtils.message('Control:pidtool:strAddingPlantInfo',name));
                this.StatusBar.ParentTool = 'pidtuner';
            end
            this.PlantNames = [this.PlantNames; name];
            this.LocalWorkspace.(name) = val;
            if nargin >= 3
                this.NUPData = setfield(this.NUPData, name, NUP);
            else
                this.NUPData = setfield(this.NUPData, name, 0);
            end
            if nargin < 4
                inspectordata = [];
            end
            this.InspectorData = setfield(this.InspectorData, name, inspectordata); %#ok<*SFLD>
            notify(this, 'PlantsEvent', pidtool.desktop.pidtuner.tc.PlantsEventData(true, false, false));
            this.isSelectedPlantAdded = true;
            this.SelectedPlantIndex = this.NumPlants;
        end
        function success = removePlant(this, plantname)
            %REMOVEPLANT
            success = false;
            id = find(strcmp(this.PlantNames, plantname));
            if id == this.SelectedPlantIndex
                this.LocalWorkspace.(this.SelectedPlantName) = this.SelectedPlant;
                return
            elseif id < this.SelectedPlantIndex
                this.SelectedPlantIndex_ = this.SelectedPlantIndex_ - 1;
            end
            this.LocalWorkspace = rmfield(this.LocalWorkspace,plantname);
            this.PlantNames(id) = [];
            this.NUPData = rmfield(this.NUPData, plantname);
            this.InspectorData = rmfield(this.InspectorData, plantname);
            notify(this, 'PlantsEvent', pidtool.desktop.pidtuner.tc.PlantsEventData(false, id, false));
            success = true;
        end
        function renamePlant(this, oldname, newname)
            %RENAMEPLANT
            
            if ismember(newname,this.PlantNames)
                NUP = getfield(this.NUPData, oldname); %#ok<*GFLD>
                this.NUPData = setfield(this.NUPData, newname, NUP);
                iData = getfield(this.InspectorData, oldname); %#ok<*GFLD>
                this.InspectorData = setfield(this.InspectorData, newname, iData);
                if any(strcmp(oldname,fieldnames(this.LocalWorkspace))) % this is to support renaming through API
                    % Rename variable
                    if ~strcmp(oldname, newname)
                        this.LocalWorkspace.(newname) = this.LocalWorkspace.(oldname);
                        % this.LocalWorkspace = rmfield(this.LocalWorkspace, oldname);
                    end
                end
                if strcmp(oldname,this.SelectedPlantName)
                    id = find(strcmp(this.PlantNames, newname));
                    this.SelectedPlantIndex_ = id; % this is to enable deleting of oldplant
                end
                
                if ~strcmp(oldname, newname)
                    this.removePlant(oldname);
                end
                id = find(strcmp(this.PlantNames, newname));
                notify(this, 'PlantsEvent', pidtool.desktop.pidtuner.tc.PlantsEventData(false, false, id));
                this.SelectedPlantIndex = this.SelectedPlantIndex; % this is to refresh all plants data in GUI
            else
                id = find(strcmp(this.PlantNames, oldname));
                this.PlantNames{id} = newname;
                NUP = getfield(this.NUPData, oldname); %#ok<*GFLD>
                this.NUPData = rmfield(this.NUPData, oldname);
                this.NUPData = setfield(this.NUPData, newname, NUP);
                iData = getfield(this.InspectorData, oldname); %#ok<*GFLD>
                this.InspectorData = rmfield(this.InspectorData, oldname);
                this.InspectorData = setfield(this.InspectorData, newname, iData);
                if any(strcmp(oldname,fieldnames(this.LocalWorkspace))) % this is to support renaming through API
                    % Rename variable
                    this.LocalWorkspace.(newname) = this.LocalWorkspace.(oldname);
                    this.LocalWorkspace = rmfield(this.LocalWorkspace, oldname);
                end
                notify(this, 'PlantsEvent', pidtool.desktop.pidtuner.tc.PlantsEventData(false, false, id));
            end
        end
        function val = get.Plants(this)
            %GET
            
            n = this.NumPlants;
            val = cell(n,1);
            for i = 1:n
                plantname = this.PlantNames{i};
                G = this.LocalWorkspace.(plantname);
                val{i} = G;
            end
        end
        function set.SelectedPlantIndex(this, val)
            %SET
            
            if val <= this.NumPlants
                this.SelectedPlantIndex_ = val;
                if val > 0
                    G = this.LocalWorkspace.(this.SelectedPlantName);
                else
                    G = tf([]);
                end
                G.InputName = 'u';
                G.OutputName = 'y';
                this.SelectedPlant_ = G;
                if ~((this.isSelectedPlantAdded) && (val == this.NumPlants))
                    this.isSelectedPlantAdded = false;
                end
            else
                error('Index exceeds number of Plants');
            end
        end
        function val = get.SelectedPlant(this)
            %GET
            
            if isempty(this.SelectedPlant_)
                if this.SelectedPlantIndex > 0
                    val = this.LocalWorkspace.(this.SelectedPlantName);
                else
                    val = tf(nan);
                end
            else
                val = this.SelectedPlant_;
            end
            if ~isempty(this.TimeUnit) && ~strcmp(val.TimeUnit,this.TimeUnit)
                TU = this.TimeUnit;
                val = localSamplePlantsForTimeUnit({val}, TU);
                val = val{1};
            end
            if ~isempty(this.SampleTime) && val.Ts ~= this.SampleTime
                TS = this.SampleTime;
                val = localSamplePlantsForSampleTime({val}, TS);
                val = val{1};
            end
        end
        function set.SelectedPlant(this, val)
            %SET
            
            id = find(strcmp(this.PlantNames, val));
            if isempty(id)
                error('Specified plant does not exist in the plant-list');
            else
                this.SelectedPlantIndex = id;
            end
        end
        function val = get.SelectedPlantIndex(this)
            %GET
            
            val = this.SelectedPlantIndex_;
        end
        function val = get.SelectedPlantName(this)
            %GET
            if this.SelectedPlantIndex > 0
                val = this.PlantNames{this.SelectedPlantIndex};
            else
                val = '';
            end
        end
        function val = get.NumPlants(this)
            %GET
            val = length(this.PlantNames);
        end
        function val = get.SelectedPlantSampleTime(this)
            %GET
            val = this.SelectedPlant.Ts;
        end
        function val = get.SelectedPlantTimeUnit(this)
            %GET
            val = this.SelectedPlant.TimeUnit;
        end
        function val = get.SelectedPlantNUP(this)
            %GET
            val = getfield(this.NUPData, this.SelectedPlantName);
        end
        function val = get.SelectedPlantInspectorData(this)
            %GET
            val = getfield(this.InspectorData, this.SelectedPlantName);
        end
        function val = get.SampledPlants(this)
            %GET
            plants = this.Plants;
            if ~isempty(this.SampleTime)
                TS = this.SampleTime;
            else
                TS = this.SelectedPlant.Ts;
            end
            if ~isempty(this.TimeUnit)
                TU = this.TimeUnit;
            else
                TU = this.SelectedPlantTimeUnit;
            end
            plants = localSamplePlantsForTimeUnit(plants, TU);
            val = localSamplePlantsForSampleTime(plants, TS);
        end
        function [dupplants, dupids] = exportPlants(this, plantids, force)
            %EXPORTPLANTS
            
            if isempty(plantids)
                return
            end
            if isnumeric(plantids)
                idx = plantids;
            else
                idx = [];
                for i = 1:length(plantids)
                    idx = [idx;find(strcmp(this.PlantNames, plantids{i}))]; %#ok<AGROW>
                end
            end
            plants = this.Plants(idx);
            dupids = [];
            for i = 1:length(plants)
                plant = plants{i};
                plantname = this.PlantNames{idx(i)};
                if (evalin('base',['exist(''', plantname,''', ''var'');']) == 0)
                    assignin('base', plantname, plant);
                else
                    if force
                        assignin('base', plantname, plant);
                    else
                        dupids = [dupids; idx(i)]; %#ok<AGROW>
                    end
                end
            end
            dupplants = this.PlantNames(dupids);
        end
        function out = isSelectedPlantZero(this)
            %ISSELECTEDPLANTZERO
            
            G = this.SelectedPlant;
            try
                out = (isstatic(G) && dcgain(G)==0);
            catch
                out = false;
            end
        end
        function out = isSelectedPlantLinearized(this)
            out = ~isempty(getfield(this.InspectorData, this.SelectedPlantName));
        end
    end
end
function localWorkspaceChangeCallback(this, evnt)
%LOCALWORKSPACECHANGECALLBACK

% if this.enabledWSListener
%     plantnames = this.PlantNames;
%     WSplantnames = this.LocalWorkspace.getWho;
%     if evnt.WSRename
%         renamedplant = this.LocalWorkspace.getDatabase.Data.OUT{1};
%         newname = this.LocalWorkspace.getDatabase.Data.IN{1};
%         this.renamePlant(renamedplant, newname);
%     elseif evnt.WSDelete || evnt.WSClear
%         removedplants = setdiff(plantnames, WSplantnames);
%         for i = 1:length(removedplants)
%             this.removePlant(removedplants{i});
%         end
%     end
% end
end

function val = localSamplePlantsForSampleTime(plants, TS)
WarningState = warning('off');
n = length(plants);
val = cell(n,1);
if TS == 0
    for i = 1:n
        if plants{i}.Ts <= 0
            val{i} =  plants{i};
        else
            if isa(plants{i}, 'frd')
                val{i} = tf(nan);
            elseif isa(plants{i}, 'idproc')
                val{i} = d2c(zpk(plants{i}));
            else
                val{i} = d2c(plants{i});
            end
        end
        val{i}.InputName = 'u';
        val{i}.OutputName = 'y';
    end
else
    for i = 1:n
        if plants{i}.Ts == TS || plants{i}.Ts == -1
            val{i} =  plants{i};
        elseif plants{i}.Ts == 0
            if isa(plants{i}, 'frd')
                val{i} = tf(nan);
            elseif isa(plants{i}, 'idproc')
                val{i} = c2d(zpk(plants{i}),TS);
            else
                val{i} = c2d(plants{i},TS);
            end
        else
            if isa(plants{i}, 'frd')
                val{i} = tf(nan);
            elseif isa(plants{i}, 'idproc')
                val{i} = d2d(zpk(plants{i}),TS);
            else
                val{i} = d2d(plants{i},TS);
            end
        end
        val{i}.InputName = 'u';
        val{i}.OutputName = 'y';
    end
end
warning(WarningState);
end

function val = localSamplePlantsForTimeUnit(plants, TU)
n = length(plants);
val = cell(n,1);

for i = 1:n
    if ~strcmp(plants{i}.TimeUnit,TU)
        val{i} = chgTimeUnit(plants{i}, TU);
    else
        val{i} = plants{i};
    end
end
end
