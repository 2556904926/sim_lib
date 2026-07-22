function varargout = controlSystemTuner(varargin)
% controlSystemTuner  Control Sytem Tuner App.
%
%   controlSystemTuner opens the Control System Tuner App.  This Graphical
%   User Interface lets you to tune fixed-structure control systems subject
%   to both soft and hard design requirements. You can tune multiple
%   fixed-order, fixed-structure control elements distributed over one
%   or more feedback loops.
%
%   controlSystemTuner(GENSS) opens the App to tune the model a generalized
%   state-space (GENSS) models. A GENSS model arises when combining
%   ordinary LTI models (see LTI) with tunable blocks (see
%   TUNABLEBLOCK).
%
%   The Control System Tuner App can also be used to tune blocks in
%   Simulink models. This functionality requires the Simulink Control
%   Design product.
%
%   controlSystemTuner(MODELNAME) opens the App to tune blocks in the
%   Simulink model MODELNAME.
%
%   controlSystemTuner(SLTUNER) opens the App for the Simulink model
%   using the information provided by the SLTUNER object(see SLTUNER).
%
%   controlSystemTuner(SESSIONFILE) opens the App and loads a previously
%   saved session SESSIONFILE.

%   Copyright 2014-2021 The MathWorks, Inc.

varargin = controllib.internal.util.hString2Char(varargin);

Tool = [];
switch nargin
    case 0
        % No input, MATLAB Standard Feedback Configuration
        system = systuneapp.data.MatlabConfigData.Config1();
        Tool = openToolWithMATLABVersion(system);
    case 1
        % Name of Simulink Model or Session File
        if ischar(varargin{1})             
            try
                % open Simulink model named "Model" and tool
                open_system(varargin{1});
                Tool = openToolWithSimulinkVersion(varargin{1});
            catch ME
                % not Simulink System, check session file
                FileName = appendMATExtension(varargin{1});
                if exist(FileName,'file')
                    SessionFile = systuneapp.util.loadValidateSessionFile(FileName);
                    Tool = openToolWithSessionFile(SessionFile);
                    preLoadSession(Tool,SessionFile.ControlSystemTunerSession,FileName);
                else
                    % no session file or simulink system, rethrow simulink
                    % model error as before
                    rethrow(ME);
                end
            end
        elseif isa(varargin{1},'slTuner') || isa(varargin{1},'slTunable') 
            % Objects of slTuner and slTunable
            if license('test','Simulink_Control_Design') && ~isempty(ver('slcontrol'))
                Model = varargin{1};
                switch class(Model)
                    case 'slTuner'
                        ModelName = Model.Model;
                    case 'slTunable'
                        ModelName = Model.ModelName;
                        w = warning('off','Slcontrol:sllinearizer:AddPointOpening');
                        Model = slTuner(Model);
                        warning(w);                        
                end
                open_system(ModelName);
                try
                    Tool = openToolWithSimulinkVersion(ModelName);
                catch ME
                    throwAsCaller(ME)
                end
                % if not same architecture, construct and load as a session file
                if ~isequal(Tool.ControlDesignData.Architecture,Model)
                    SessionData = systuneapp.data.SessionData;
                    SessionData.ControlDesignData = systuneapp.data.ControlDesignData(Model);                    
                    preLoadSession(Tool,SessionData,'');
                end
                
            else
                error(message('Control:systunegui:SCDRequired'))
            end
        elseif isa(varargin{1},'genss')            
            % Genss Object, Generalized Feedback Configuration
            try 
                system = systuneapp.data.MatlabConfigData.ConfigGenSS(varargin{1}, inputname(1));
            catch ME
                throwAsCaller(ME)
            end
            Tool = openToolWithMATLABVersion(system);
        end
end
if isempty(Tool)
    error(message('Control:systunegui:InvalidSyntaxForCommand'))
end
if nargout
    varargout{1} = Tool;
end
end
%% Local functions --------------------------------------------------------
function Tool = openToolWithSessionFile(SessionFile)
    % open the tool for this architecture
    Architecture = SessionFile.ControlSystemTunerSession.ControlDesignData.Architecture;
    switch class(Architecture)
        case 'slTuner'
            Tool = controlSystemTuner(Architecture.Model);
        case 'slTunable'
            Tool = controlSystemTuner(Architecture.ModelName);
        case 'systuneapp.data.MatlabConfigData.ConfigGenSS'
            Tool = controlSystemTuner(SessionFile.ControlSystemTunerSession.ControlDesignData.Architecture.System);
        case 'systuneapp.data.MatlabConfigData.Config1'
            Tool = controlSystemTuner;
    end
end

function Tool = openToolWithSimulinkVersion(Model)

    Tool = systuneapp.SystuneToolManager.getSystuneTool(Model);
    if systuneapp.util.openJavaApp
        Tool.show;
    end
end
function tool = openToolWithMATLABVersion(system)
if systuneapp.util.openJavaApp
    tool = systuneapp.SystuneTool(system);
    internal.setJavaCustomData(tool.ToolGroup.Peer,tool)
else
    tool = systuneapp.SystuneApp(system);
end
end
function FileName = appendMATExtension(Param)
FileName = Param;
if ~contains(FileName,'.mat')
    FileName = [FileName '.mat'];
end
end
