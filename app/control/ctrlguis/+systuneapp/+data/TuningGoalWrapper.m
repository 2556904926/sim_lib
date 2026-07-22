classdef (Hidden) TuningGoalWrapper < handle & matlab.mixin.Copyable
    % Wrapper class for Tuning Goals
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = public, SetObservable)
        TuningGoal
        MetaData
    end
    properties(Hidden, Transient)
        Editor
    end
    methods
        function this = TuningGoalWrapper(TuningGoal,MetaData)
            this.TuningGoal=zeros(0,1);
            this.MetaData=cell(0,1);
            
            if nargin>0
                this.TuningGoal=TuningGoal;
            end
            if nargin>1
                this.MetaData = MetaData;
            end
            
        end
        function delete(this)
            % closes dialogs if tuning goal is deleted
            if ~isempty(this.Editor) && isfield(this.Editor,'TC') && isvalid(this.Editor.TC)
               delete(this.Editor.TC);
            end            
        end        
        function Name = getName(this)
            Name = this.TuningGoal.Name;
        end
        
        function edit(this,cdd,hAnchor,Region)
            
            switch nargin
                case 1
                    cdd = systuneapp.data.ControlDesignData;
                    hAnchor = [];
                    Region = [];
                case 2
                    hAnchor = [];
                    Region = [];
                case 3
                    Region = [];
            end

            
            % Check Editor is created for this tuning goal
            if isempty(this.Editor)
                IsTCExist = false;
                IsGCExist = false;
            elseif isfield(this.Editor,'TC') && ~isempty(this.Editor.TC) && isvalid(this.Editor.TC) && ...
                    strcmp(this.Editor.TC.Type,'Looptune')
                % If TuningGoal was created using Quick Loop Tuning,
                % regenerate the TC and GC because the TuningGoal is split
                % into a LoopShape and a Margins TuningGoal
                IsTCExist = false;
                IsGCExist = false;
            else
                if isfield(this.Editor,'TC')
                    if isempty(this.Editor.TC) 
                        IsTCExist = false;
                    elseif isvalid(this.Editor.TC)
                        IsTCExist = true;      
                    else 
                        IsTCExist = false;
                    end
                else
                    IsTCExist = false;
                end
                if isfield(this.Editor,'GC')
                    if isempty(this.Editor.GC)
                        IsGCExist = false;
                    elseif isvalid(this.Editor.GC)
                        IsGCExist = true;  
                    else
                        IsGCExist = false;
                    end
                else
                    IsGCExist = false;
                end                
            end
            
            % Created TC and GC if not exist and show editor
            if ~IsTCExist
                this.Editor.TC = this.setTuningGoalTC(this,cdd);
            end
            if ~IsGCExist
                this.Editor.GC = createView(this.Editor.TC);
            end                
            if isempty(Region)
                this.Editor.GC.show(hAnchor)
            else
                this.Editor.GC.show(hAnchor,Region)
            end
        end
        
        function hText = getDisplayPreviewText(this)
           hText = systuneapp.util.createDisplayTuningGoal(this.TuningGoal);
        end
       
        function setTuningGoal(this, TuningGoal, MetaData)
            if nargin<3
                this.MetaData = [];
            else
                this.MetaData = MetaData;
            end
            this.TuningGoal = TuningGoal;
        end
        
    end
    methods(Access = protected)
        function TC = setTuningGoalTC(this,TuningGoalWrapper,cdd)            
            TuningGoalType = systuneapp.util.getTuningGoalType(TuningGoalWrapper.TuningGoal);
            TC = systuneapp.util.getTuningGoalTC(TuningGoalType,cdd,TuningGoalWrapper);         
        end
    end
    
end