classdef (Hidden) IOTransfer < ctrlguis.csdesignerapp.data.responses.internal.ResponseConfiguration
    % Class for input output transfer responses
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    properties
        % Input signal names (string or string vector).
        %
        % In MATLAB, you can refer to any input of the control system model.
        % In Simulink, you can refer to any signal listed in the slTunable
        % interface as "Controls", "Measurements", or "IOs" of type 'in',
        % 'inout', or 'outin' (see slTunable for details).
        Input
        
        % Output signal names (string or string vector).
        %
        % In MATLAB, you can refer to any output of the control system model.
        % In Simulink, you can refer to any signal listed in the slTunable
        % interface as "Controls", "Measurements", or "IOs" of type 'out',
        % 'inout', or 'outin' (see slTunable for details).
        Output
        
    end
    %% Public Methods
    methods
        % Constructor
        function this = IOTransfer(InputName,OutputName)
            narginchk(2,2)
            try
                this.Input = InputName;
                this.Output = OutputName;
            catch ME
                throw(ME)
            end
        end
        
    end
    
    %% Set/Get methods
    methods
        
        function this = set.Input(this,Value)
            % SET function for Input
            [ok,this.Input] = ltipack.isNameList(Value);
            if ~ok
               error(message('Controllib:general:UnexpectedError','Invalid input channel name specified.'));
            end
        end
        
        function this = set.Output(this,Value)
            % SET function for Output
            [ok,this.Output] = ltipack.isNameList(Value);
            if ~ok
                error(message('Controllib:general:UnexpectedError','Invalid output channel name specified.'));
            end
        end
        
    end
    
    %% Implementation of abstract methods
    methods (Access = protected)    
        
        function T = getResponse_(this,CL)
            % Computes scaled closed-loop transfer from inputs to outputs
            T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
        end
        
        function DisplayText = getDisplayPreviewText_(this)
            % I/O Transfer Function
            TypeSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('type', ...
                getString(message('Control:designerapp:ResponseTypeIOTransferFunction')));
            % Name Label, Response Name
            NameSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayName')), this.Name);
            % Input Label, Inputs
            InputSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('section', ...
                getString(message('Control:designerapp:DisplayInput')),this.Input);
            % Output Label, Outputs
            OutputSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('section', ...
                getString(message('Control:designerapp:DisplayOutput')),this.Output);
            % If exist, Opening Label, Openings
            OpeningsSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('section', ...
                getString(message('Control:designerapp:DisplayOpening')),this.Openings);
            % Construct Display Text
            DisplayText = [  TypeSection, ...
                NameSection, ...
                InputSection, ...
                OutputSection, ...
                OpeningsSection ];
        end
    end
    
    %% LOAD/SAVE
    methods 
        function S = saveSession(this)
            S.Name = this.Name;
            S.Input = this.Input;
            S.Output = this.Output;
            S.Models = this.Models;
            S.Openings = this.Openings;
            S.Type = 'IOTransfer';
        end
    end
end
