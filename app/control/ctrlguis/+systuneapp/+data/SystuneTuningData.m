classdef (Hidden) SystuneTuningData < handle
    % Data Class for Tuning of Control System Tuner App.
    
    % Copyright 2013 The MathWorks, Inc.        
    
    properties(Access = public, SetObservable)
        % Parent Data
        ControlDesignData
        % Tunable blocks list, cell array: 
        % each row is {[TunableBlock],[isActive(true/false)],BlockPath}
        TunableBlocks
        % Tuning goals list, cell array
        % each row is {[TuningGoalWrapper],[isActive(true/false)],[isHard(true/false)]}
        TuningGoals
        Options
        TuningInfo
    end
    
    methods (Access = public)
        
        %% Constructor 
        function this = SystuneTuningData(ControlDesignData)
            this.ControlDesignData=ControlDesignData;
            updateTunableBlock(this);
            updateTuningGoal(this);
            setOptions(this,systuneOptions('Display','off'));            
            installListeners(this);
        end
        
        %% TunableBlocks
        function TunableBlock = getTunableBlock(this)
            TunableBlock = this.TunableBlocks;
        end        
        function updateTunableBlock(this)
            % get tunable blocks list from control design data            
            TunableBlocksFromCDD = this.ControlDesignData.getTunableBlock;
            % get current list of tunable blocks
            CurrentTunableBlocksList = this.getTunableBlock;
            
            
            if isempty(CurrentTunableBlocksList)
                % no blocks in the list, create tunable blocks table                                                
                
                % number of tunable blocks
                nTB = length(TunableBlocksFromCDD);
                
                % create tunable blocks cell structure
                CurrentTunableBlocksList = cell(nTB,3);                
                
                % set tunable blocks to first column
                CurrentTunableBlocksList(:,1) = num2cell(TunableBlocksFromCDD);
                
                % set tunable blocks active as default
                CurrentTunableBlocksList(:,2) = num2cell(true(nTB,1));
                
                % set tunable blocks paths
                if isempty(TunableBlocksFromCDD)
                    CurrentTunableBlocksList(:,3) = num2cell(TunableBlocksFromCDD);
                else
                    CurrentTunableBlocksList(:,3) = {TunableBlocksFromCDD.BlockPath}';
                end
                NewTunableBlocksList = CurrentTunableBlocksList;
            else     
                % for each element of TunableBlocksFromCDD
                %   there is not one in tunable blocks table -> add to table and set active 1
                % for each element of tunable blocks table not in TunableBlocksFromCDD 
                %   remove it from tunable blocks table
                CurrentTunableBlocks = CurrentTunableBlocksList(:,3); 
                CurrentTunableBlocks = CurrentTunableBlocks(cellfun(@(x) ~isempty(x), CurrentTunableBlocks));
                if isempty(TunableBlocksFromCDD)
                    NewTunableBlocksList = cell(0,3);
                else
                    NewTunableBlocksList = [num2cell(TunableBlocksFromCDD(:)) num2cell(true(size(TunableBlocksFromCDD(:)))) {TunableBlocksFromCDD.BlockPath}'];
                    [~,idxa,idxb] = intersect(CurrentTunableBlocks,NewTunableBlocksList(:,3));
                    NewTunableBlocksList(idxb,2) = CurrentTunableBlocksList(idxa,2);
                end

            end
                               
            this.TunableBlocks = NewTunableBlocksList;
        end
        function setTunableBlockActive(this,TunableBlocksToSetActive,flag)
            CurrentTunableBlocksList = this.getTunableBlock;
            CurrentTunableBlocks = cat(1,CurrentTunableBlocksList{:,1});
            [~,CommonItems,CommonItemIndexInAllTunableBlocks,CommonItemIndexInTunableBlocksSetToActive] = ...
                systuneapp.util.newOrCommonItemsInList(TunableBlocksToSetActive,CurrentTunableBlocks);
                        
            if ~isempty(CommonItems)
                isActive = CurrentTunableBlocksList(:,2);
                isActive(CommonItemIndexInAllTunableBlocks) = num2cell(flag(CommonItemIndexInTunableBlocksSetToActive));
                this.TunableBlocks(:,2)=isActive;
            end  
%             systuneapp.util.setToolDirty(this.ControlDesignData);
        end
        function Index = getSelectedIndexOfTunableBlocks(this)
            Blocks = this.getTunableBlock;
            if ~isempty(Blocks)
                Index = [Blocks{:,2}]';
            else
                Index = [];
            end                        
        end
        
        %% TuningGoals
        function TuningGoal = getTuningGoal(this)
            TuningGoal = this.TuningGoals;
        end
        function updateTuningGoal(this)
            % get tuning goal list from control design data
            TuningGoalWrappersFromCDD = this.ControlDesignData.getTuningGoal;
            % get current list of tuning goals
            CurrentTuningGoalWrappersList = this.getTuningGoal;
            
            if isempty(CurrentTuningGoalWrappersList)
                % no tuning goal in the list, create tuning goal list
                
                % number of tuning goals
                nTG = length(TuningGoalWrappersFromCDD);
                
                % create tuning goals cell structure
                CurrentTuningGoalWrappersList = cell(nTG,3);
                
                % set tuning goals to first column
                CurrentTuningGoalWrappersList(:,1) = num2cell(TuningGoalWrappersFromCDD);
                
                % set tuning goals active as default
                CurrentTuningGoalWrappersList(:,2) = num2cell(true(nTG,1));
                
                % set tuning goals soft as default
                CurrentTuningGoalWrappersList(:,3) = num2cell(false(nTG,1));
                this.TuningGoals = CurrentTuningGoalWrappersList;
            else                
              % for each element of TuningGoalsFromCDD
                %   there is not one in tuning goals table -> add to table and set active 1
                % for each element of tuning goalstable not in TuningGoalsFromCDD 
                %   remove it from tuning goals table
                CurrentTuningGoalWrappers = CurrentTuningGoalWrappersList(:,1);
                TuningGoalsFromCDD = systuneapp.util.wrapperToData('TuningGoal',TuningGoalWrappersFromCDD);
                CurrentTuningGoals(:,1) = systuneapp.util.wrapperToData('TuningGoal',[CurrentTuningGoalWrappers{:}]);
                [NewTuningGoals,CommonTuningGoals,CommonTuningGoalsIndex,~,NewItemIndexinItems] = ...
                    systuneapp.util.newOrCommonItemsInList(TuningGoalsFromCDD,CurrentTuningGoals);            
                
                if isempty(CommonTuningGoals)
                    % Delete all Tuning Goals
                    cellfun(@(X) delete(X),CurrentTuningGoalWrappersList(:,1));
                    CurrentTuningGoalWrappersList = cell(0,1);
                else
                    TuningGoalsToDeleteIndex = setdiff(1:size(CurrentTuningGoalWrappersList,1),CommonTuningGoalsIndex);
                    % Delete Tuning Goals
                    cellfun(@(X) delete(X),CurrentTuningGoalWrappersList(TuningGoalsToDeleteIndex,1));
                    CurrentTuningGoalWrappersList(TuningGoalsToDeleteIndex,:) = [];
                end
                    
                if ~isempty(NewTuningGoals)
                    NewTuningGoalWrappers = TuningGoalWrappersFromCDD(NewItemIndexinItems);
                    NewTuningGoalWrappersList = ... % tuning goals / active / soft
                        [num2cell(NewTuningGoalWrappers) num2cell(true(size(NewTuningGoalWrappers))) num2cell(false(size(NewTuningGoalWrappers)))];                    
                    CurrentTuningGoalWrappersList(size(CurrentTuningGoalWrappersList,1)+(1:size(NewTuningGoalWrappersList,1)),:)=NewTuningGoalWrappersList;
                end                                               
                 
            end  
            this.TuningGoals = CurrentTuningGoalWrappersList;
            notify(this,'SystuneTuningDataTuningGoalsChanged');
        end
        function setTuningGoalActive(this,TuningGoalWrappersToSetActive,flag)
            CurrentTuningGoalsList = this.getTuningGoal;            
            CurrentTuningGoals = systuneapp.util.wrapperToData('TuningGoal',[CurrentTuningGoalsList{:,1}]);
            TuningGoalsToSetActive = systuneapp.util.wrapperToData('TuningGoal',TuningGoalWrappersToSetActive);
            
            [~,CommonItems,CommonItemIndexInAllTuningGoals,CommonItemIndexInTuningGoalsSetToActive] = ...
                systuneapp.util.newOrCommonItemsInList(TuningGoalsToSetActive,CurrentTuningGoals);            
            
            if ~isempty(CommonItems)
                isActive = CurrentTuningGoalsList(:,2);
                isActive(CommonItemIndexInAllTuningGoals) = num2cell(flag(CommonItemIndexInTuningGoalsSetToActive));
                this.TuningGoals(:,2)=isActive;
            end
        end
        function setTuningGoalAsHardConstraint(this,TuningGoalWrappersToSetAsHardConstraint,flag)
            CurrentTuningGoalsList = this.getTuningGoal;
            CurrentTuningGoals = systuneapp.util.wrapperToData('TuningGoal',[CurrentTuningGoalsList{:,1}]);
            TuningGoalsToSetAsHardConstraint = systuneapp.util.wrapperToData('TuningGoal',TuningGoalWrappersToSetAsHardConstraint);
            
            [~,CommonItems,CommonItemIndexInAllTuningGoals,CommonItemIndexInTuningGoalsToSetAsHardConstraint] = ...
                systuneapp.util.newOrCommonItemsInList(TuningGoalsToSetAsHardConstraint,CurrentTuningGoals);            
            
            if ~isempty(CommonItems)
                isHard = CurrentTuningGoalsList(:,3);
                isHard(CommonItemIndexInAllTuningGoals) = num2cell(flag(CommonItemIndexInTuningGoalsToSetAsHardConstraint));
                this.TuningGoals(:,3)=isHard;
            end
        end
        function [HardNames,SoftNames] = getActiveTuningGoalName(this)
            TuningGoalsList = this.getTuningGoal;
            ActiveTuningGoalsIndex = [TuningGoalsList{:,2}]';
            ActiveTuningGoalsList = TuningGoalsList(ActiveTuningGoalsIndex,:);
            ActiveHardTuningGoalsIndex = [ActiveTuningGoalsList{:,3}]';
            ActiveHardTuningGoals = systuneapp.util.wrapperToData('TuningGoal',reshape([ActiveTuningGoalsList{ActiveHardTuningGoalsIndex,1}],[],1));
            ActiveSoftTuningGoals = systuneapp.util.wrapperToData('TuningGoal',reshape([ActiveTuningGoalsList{~ActiveHardTuningGoalsIndex,1}],[],1));
            
            if ~isempty(ActiveHardTuningGoals)
                HardNames = arrayfun(@(x) x.Name,ActiveHardTuningGoals,'UniformOutput',false);
            else
                HardNames = [];
            end
            if ~isempty(ActiveSoftTuningGoals)
                SoftNames = arrayfun(@(x) x.Name,ActiveSoftTuningGoals,'UniformOutput',false);
            else
                SoftNames = [];
            end
        end   
        function Index = getSelectedIndexOfTuningGoals(this)
            Goals = this.getTuningGoal;
            if ~isempty(Goals)
                Index = [Goals{:,2}]';
            else
                Index = [];
            end
        end
        function Index = getHardSoftIndexOfTuningGoals(this)
            Goals = this.getTuningGoal;
            if ~isempty(Goals)
                Index = [Goals{:,3}]';
            else
                Index = [];
            end
        end        
        
        %% SystuneGUIOptions functions
        function Options = getOptions(this)
            Options = this.Options;
        end                
        function setOptions(this,Options)
            this.Options = Options;
        end         
        
        %% Systune function
        function cstAppSystune(this,SystuneTuningData)
            this.ControlDesignData.cstAppSystune(SystuneTuningData);
        end
        
        %% Listeners
        function installListeners(this)
            % updates tunable blocks list from control design data if
            % changed
            weakThis = matlab.lang.WeakReference(this);
            addlistener(this.ControlDesignData,'TunableBlocksListChanged',...
                @(es,ed) updateTunableBlock(weakThis.Handle));
            addlistener(this.ControlDesignData,'ArchitectureChanged',...
                @(es,ed) updateTunableBlock(weakThis.Handle));                        
            % updates tuning goals list from control design data if
            % changed
            addlistener(this.ControlDesignData,'TuningGoalsListChanged',...
                @(es,ed) updateTuningGoal(this));            
        end
    end
    events
        SystuneTuningDataTuningGoalsChanged
    end        
end