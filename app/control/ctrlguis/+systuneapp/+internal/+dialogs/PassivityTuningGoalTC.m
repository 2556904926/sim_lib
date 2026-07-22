classdef (Hidden) PassivityTuningGoalTC < systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC
    % Tool component for Passivity Tuning Goal.
    
    % Copyright 2015 The MathWorks, Inc.
    
    
    
    properties (SetObservable)
        % MaxLoopGain Tuning Specification Parameters
        % see Parent class for additional parameters
        IFP = 0;
        OFP = 0;
        Models = NaN;
        Focus = [0 Inf];
        Type = 'Passivity'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:systunegui:SignalListInputLabelPassivity'));
        OutputSignalLabel = getString(message('Control:systunegui:SignalListOutputLabelPassivity'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelPassivity'));
    end
    
    methods(Access = public)
        function this = PassivityTuningGoalTC(CDD,varargin) % varagin = TuningGoalWrapper or empty
            this = this@systuneapp.internal.dialogs.TuningGoalInputOutputTransferTC(CDD,varargin{:});
            this.TuningGoalSpecTC = systuneapp.internal.panels.PassivitySpecTC(this);
            if this.Create % new tuning goal, give a name
                this.Name =  systuneapp.util.giveName('PassivityGoal',this.CDD.getTuningGoalName);
            end
        end
    end
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = systuneapp.internal.dialogs.TuningGoalInputOutputTransferGC(this);
        end
    end
    
    methods(Access = public)
        function setTuningGoal(this)
            % collect information on the goal and create a new one
            try
                TempMetaData = this.TuningGoalSpecTC.getMetaData;
                % capture error and return messages
                Goal = TuningGoal.Passivity(this.Input,this.Output,this.IFP,this.OFP);
                Goal.Openings = this.Openings;
                Goal.Name = this.Name;
                Goal.Models = this.Models;
                Goal.Focus = this.Focus;
                                                               
                % check the tuning goal is valid
                validateTuningGoal(this,Goal);
                                
                TempMetaData.MATLABCode = generateMATLABCode(this,TempMetaData); % create code;
                delete(this.Listener);
                this.TuningGoalWrapper.setTuningGoal(Goal,TempMetaData)
                if this.Create
                    addTuningGoal(this.CDD,this.TuningGoalWrapper);
                    this.Create = false;
                end
            catch ME
                systuneapp.throwCSTunerError(ME);
            end
        end
        function syncData(this)
            % synchronize the outside changed tuning goal information to
            % tool component
            TuningGoal = this.TuningGoalWrapper.TuningGoal;
            this.Name = TuningGoal.Name;
            this.Input = TuningGoal.Input;
            this.Output = TuningGoal.Output;
            this.Openings = TuningGoal.Openings;
            this.IFP = TuningGoal.IPX;
            this.OFP = TuningGoal.OPX;
            this.Models = reshape(TuningGoal.Models,1,[]);
            this.Focus = TuningGoal.Focus;
            if ~isempty(this.TuningGoalSpecTC)
                updateMetaData(this.TuningGoalSpecTC);
            end
            update(this);
        end
    end
    methods(Access = protected)
        function mUpdate(this)
            update(this.IOTransferTC);
            if ~isempty(this.TuningGoalSpecTC)
                update(this.TuningGoalSpecTC);
            end
        end
    end
    methods(Hidden=true) % Revisit
        function Text = generateMATLABCode(this,MetaData)
            if nargin<2 || isempty(MetaData) % No MetaData information
                MetaData = this.TuningGoalSpecTC.getMetaData;
            end
            GoalName = systuneapp.util.createVariableName(this.Name);
            Text = cell(0,1);
            Text = systuneapp.util.appendMATLABCodeForTuningGoalTitleAndSignals(Text,'IO',this.Type,this.Input,this.Output);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateIFPGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);
            MinIFPCode = ['MinIFP = ' ...
                MetaData.IFP '; % ' ...
                getString(message('Control:systunegui:CodegenMinIFP'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,MinIFPCode);
            TGCreateComment = ['% ' getString(message('Control:systunegui:CodegenCreateOFPGoal'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateComment);            
            MinOFPCode = ['MinOFP = ' ...
                MetaData.OFP '; % ' ...
                getString(message('Control:systunegui:CodegenMinOFP'))];
            Text = controllib.internal.codegen.appendMATLABCode(Text,MinOFPCode);
            TGCreateCode = sprintf('%s = TuningGoal.Passivity(Inputs,Outputs,MinIFP,MinOFP);',GoalName);
            Text = controllib.internal.codegen.appendMATLABCode(Text,TGCreateCode);
            Text = systuneapp.util.appendMATLABCodeForFieldOpenings(Text,this.Openings,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldFocus(Text,this.Focus,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldModels(Text,this.Models,GoalName);
            Text = systuneapp.util.appendMATLABCodeForFieldName(Text,this.Name,GoalName);
        end
    end
end
