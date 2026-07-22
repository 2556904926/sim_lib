function [ViewFig,ltiViewer] = linearSystemAnalyzer(varargin)
%linearSystemAnalyzer  Opens the Linear System Analyzer App.
%
%   linearSystemAnalyzer opens the Linear System Analyzer.  The Linear
%   System Analyzer is an interactive user interface for analyzing the time
%   and frequency responses of linear systems and comparing such systems.
%   See LTIMODELS for details on how to model linear systems in the Control
%   System Toolbox.
%
%   linearSystemAnalyzer(SYS1,SYS2,...,SYSN) opens a Linear System Analyzer
%   containing the step response of the LTI models SYS1,SYS2,...,SYSN.  You
%   can specify a distinctive color, line style, and marker for each
%   system, as in
%      sys1 = rss(3,2,2);
%      sys2 = rss(4,2,2);
%      linearSystemAnalyzer(sys1,'r-*',sys2,'m--');
%
%   linearSystemAnalyzer(PLOTTYPE,SYS1,SYS2,...,SYSN) further specifies
%   which responses to plot in the Linear System Analyzer.  PLOTTYPE may be
%   any of the following strings (or a combination thereof):
%        1) 'step'           Step response
%        2) 'impulse'        Impulse response
%        3) 'lsim'           Linear simulation plot
%        4) 'initial'        Initial condition plot
%        5) 'bode'           Bode diagram
%        6) 'bodemag'        Bode Magnitude diagram
%        7) 'nyquist'        Nyquist plot
%        8) 'nichols'        Nichols plot
%        9) 'sigma'          Singular value plot
%       10) 'pzmap'          Pole/Zero map
%       11) 'iopzmap'        I/O Pole/Zero map
%   For example,
%      linearSystemAnalyzer({'step';'bode'},sys1,sys2)
%   shows the step and Bode responses of the LTI models SYS1 and SYS2.
%
%   linearSystemAnalyzer(PLOTTYPE,SYS,EXTRAS) allows you to specify the
%   additional input arguments supported by the various response types. See
%   the HELP text for each response type for more details on the format of
%   these extra arguments. Note that specifying plot or data options is not
%   supported. Use the Preferences dialog to modify plots after launching
%   the Linear System Analyzer. If an LSIM plot is specified without
%   additional input arguments, the Linear Simulation Tool automatically
%   opens so that initial states and/or driving inputs can be assigned
%   interactively.
%
%   H = linearSystemAnalyzer(...) opens a Linear System Analyzer and
%   returns the handle to the Linear System Analyzer figure.
%
%   Two additional options are available for manipulating previously
%   opened Linear System Analyzers:
%
%   linearSystemAnalyzer('clear',VIEWERS) clears the plots and data from
%   the Linear System Analyzers with handles VIEWERS.
%
%   linearSystemAnalyzer('current',SYS1,SYS2,...,SYSN,VIEWERS) adds the
%   responses of the systems SYS1,SYS2,... to the Linear System Analyzers
%   with handles VIEWERS.
%
%   See also STEP, IMPULSE, LSIM, INITIAL, LTI/IOPZMAP, PZMAP,
%            BODE, LTI/BODEMAG, NYQUIST, NICHOLS, SIGMA.

%   Copyright 1986-2021 The MathWorks, Inc.

varargin = controllib.internal.util.hString2Char(varargin);

ni = nargin;
plottype = string.empty;
currentflag = false;
argoffset = 0;
if ni > 0 && ischar(varargin{1})
    varargin{1} = varargin(1);  % convert first char argument to cellstr
end

% Process first string argument
if ni > 0 && iscellstr(varargin{1})
    FirstArg = varargin{1};
    switch FirstArg{1}
        case 'current'
            currentflag = true;
            ViewerHandles = varargin{end};
            varargin = varargin(2:end-1);
            plottype = string.empty;
        case 'clear'
            LocalClearViewer(varargin{2});
            return
        otherwise
            try %#ok<TRYNC>
                plottype = string(FirstArg);
            end
            varargin = varargin(2:end);
    end
    argoffset = 1;
end

% Plot Types checking
ValidTypes = string(ltiplottypes('Alias'));
if ~isstring(plottype) || ~isempty(setdiff(plottype,ValidTypes))
    error(message('Control:analysis:ltiview1'))
elseif length(plottype)>6
    error(message('Control:analysis:ltiview2'))
end
if isempty(plottype)
    plottype = "step";
end
SINGLEPLOT = isscalar(plottype);

% Get Systems from Input List
try
    InNames = cell(length(varargin),1);
    nUntitled = 1;
    for xx=1:length(varargin)
        InNames{xx} = inputname(argoffset + xx);
        if isempty(InNames{xx})
            InNames{xx} = ['untitled' num2str(nUntitled)];
            nUntitled = nUntitled + 1;
        end
    end
    [sysList,ExtraArg,plotOptions] = DynamicSystem.parseRespFcnInputs(varargin,InNames);
    % Throw error if plot options or data options are used in input
    % arguments, or if extra arguments are used with multiple plot types.
    if ~(isempty(ExtraArg) || SINGLEPLOT) || ~isempty(plotOptions)
        error(message('Control:analysis:ltiview3'))
    end
catch E
    throw(E);
end

for ii = 1:length(sysList)
    sysList(ii).System.Name = sysList(ii).Name;
end

% Current option
if currentflag
    LocalCurrentViewer({sysList.System},{sysList.Name},ViewerHandles);
    return
end

% Check compatibility and create LTI sources
if SINGLEPLOT
    try
        plotVersion = controllibutils.CSTCustomSettings.setCSTPlotsVersion(2);
        [sysList,Settings] = localSinglePlotCheck(plottype,sysList,ExtraArg);
        [responses,modelSources] = localSinglePlotCreateResponses(plottype,sysList,Settings);
        controllibutils.CSTCustomSettings.setCSTPlotsVersion(plotVersion);
    catch ME
        controllibutils.CSTCustomSettings.setCSTPlotsVersion(plotVersion);
        throw(ME)
    end
end

try
    % Create an instance of the Viewer
    ltiViewer = viewgui.ltiviewer;
    show(ltiViewer);
    d = uiprogressdlg(getWidget(ltiViewer),Title=getString(message('Controllib:gui:strLTIViewer')),...
        Message=getString(message('Control:viewer:msgLTIViewerWaitBar')),Indeterminate="on");

    % Set current views
    if SINGLEPLOT
        if ~isempty(Settings)
            localSinglePlotSettings(ltiViewer,plottype,sysList,Settings);
        end
        createSinglePlot(ltiViewer,plottype,responses,modelSources);
    else
        % Set systems
        for ii = 1:length(sysList)
            addSystem(ltiViewer,sysList(ii).System);
        end
        setCurrentPlots(ltiViewer,plottype);
    end

    % Set PlotStyles if any
    for ct = 1:length(sysList)
        if ~isempty(sysList(ct).Style)
            setStyle(ltiViewer,ct,sysList(ct).Style);
        end
    end
    close(d);
catch ME
    throw(ME);
end

% Call the start-up message box
h = cstprefs.tbxprefs();
if strcmp(h.StartUpMsgBox.LTIviewer,'on')
    openStartupDialog(ltiViewer);
end

% Output args
if nargout
    ViewFig = getWidget(ltiViewer);
end
end


%--------------- LOCAL FUNCTIONS ----------------------------------
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% localSinglePlotCheck %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [sysList,Settings] = localSinglePlotCheck(plottype,sysList,ExtraArg)
% Checks system compatibility with plot type and validates extra settings.
Settings = {};
switch plottype
    case {'step','impulse'}
        [sysList,t,p,Config] = DynamicSystem.checkStepInputs(sysList,ExtraArg);
        Settings = {t,p,Config};
    case 'initial'
        if ~isempty(sysList)
            [sysList,t,p,Config] = DynamicSystem.checkInitialInputs(sysList,ExtraArg,true);
            Settings = {t,p,Config};
        end
    case 'lsim'
        if ~isempty(sysList)
            [sysList,t,x0,u,p,InterpRule] = DynamicSystem.checkLsimInputs(sysList,ExtraArg,true);
            if ~(isempty(t) && max(size(u))==0)
                % Watch for linearSystemAnalyzer('lsim',sys) (opens LSIM UI)
                Settings = {t,p,x0,u,InterpRule};
            end
        end
    case {'bode','bodemag','nyquist','nichols'}
        [sysList,f] = DynamicSystem.checkBodeInputs(sysList,ExtraArg);
        if ~isempty(f)
            if iscell(f)
                fc = [f{:}];
                f = {fc(1) fc(end)};
            end
        end
        Settings = {f};
    case 'sigma'
        [sysList,f,type] = DynamicSystem.checkSigmaInputs(sysList,ExtraArg);
        if ~isempty(f)
            if iscell(f)
                fc = [f{:}];
                f = {fc(1) fc(end)};
            end
        end
        Settings = {f,type};
    case {'pzmap','iopzmap'}
        sysList = DynamicSystem.checkPZInputs(sysList,ExtraArg);
end
end


function localSinglePlotSettings(ltiViewer,plottype,sysList,Settings)
% Applies extra settings in single plot case.
switch plottype
    case {'step','impulse','initial','lsim'}
        if ~isempty(Settings)
            t = Settings{1};
            ltiViewer.Preferences.TimeVector = t;
        end
        if ~isempty(sysList)
            ltiViewer.Preferences.TimeVectorUnits = sysList(1).System.TimeUnit;
        end
    case {'bode','bodemag','sigma','nyquist','nichols'}
        f = Settings{1};
        ltiViewer.Preferences.FrequencyVector = f;
        if ~isempty(sysList)
            TimeUnits = sysList(1).System.TimeUnit;
            if strcmpi(TimeUnits,'seconds')
                FreqUnits = 'rad/s';
            else
                FreqUnits = ['rad/',TimeUnits(1:end-1)];
            end
            ltiViewer.Preferences.FrequencyVectorUnits = FreqUnits;
        end
end
end

function [responses,modelSources] = localSinglePlotCreateResponses(plottype,sysList,Settings)
responses = controllib.chart.internal.foundation.BaseResponse.empty;
modelSources = cell(size(sysList));
for ii = 1:length(sysList)
    modelSources{ii} = controllib.chart.internal.utils.ModelSource(sysList(ii).System);
end
switch plottype
    case 'step'
        t = Settings{1};  p = Settings{2};  Config = Settings{3};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.StepResponse(modelSources{ii},Name=sysList(ii).Name,Time=t,Parameter=p,Config=Config);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'impulse'
        t = Settings{1};  p = Settings{2};  Config = Settings{3};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.ImpulseResponse(modelSources{ii},Name=sysList(ii).Name,Time=t,Parameter=p,Config=Config);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'initial'
        if ~isempty(Settings)
            t = Settings{1};  p = Settings{2};  Config = Settings{3};
            for ii = 1:length(sysList)
                responses(ii) = controllib.chart.response.InitialResponse(modelSources{ii},Name=sysList(ii).Name,Time=t,Parameter=p,Config=Config);
                if ~isempty(responses(ii).DataException)
                    throw(responses(ii).DataException);
                end
            end
        end
    case 'lsim'
        if isempty(Settings)
            for ii = 1:length(sysList)
                responses(ii) = controllib.chart.response.LinearSimulationResponse(modelSources{ii},Name=sysList(ii).Name);
                if ~isempty(responses(ii).DataException)
                    throw(responses(ii).DataException);
                end
            end
        else
            t = Settings{1}; p = Settings{2}; Config = Settings{3}; u = Settings{4}; InterpRule = Settings{5};
            for ii = 1:length(sysList)
                responses(ii) = controllib.chart.response.LinearSimulationResponse(modelSources{ii},Name=sysList(ii).Name,Time=t,Parameter=p,Config=Config,InputSignal=u,InterpolationMethod=InterpRule);
                if ~isempty(responses(ii).DataException)
                    throw(responses(ii).DataException);
                end
            end
        end
    case {'bode','bodemag'}
        f = Settings{1};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.BodeResponse(modelSources{ii},Name=sysList(ii).Name,Frequency=f);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'sigma'
        f = Settings{1}; type = Settings{2};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.SigmaResponse(modelSources{ii},Name=sysList(ii).Name,Frequency=f,SingularValueType=type);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'nyquist'
        f = Settings{1};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.NyquistResponse(modelSources{ii},Name=sysList(ii).Name,Frequency=f);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'nichols'
        f = Settings{1};
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.NicholsResponse(modelSources{ii},Name=sysList(ii).Name,Frequency=f);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'pzmap'
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.PZResponse(modelSources{ii},Name=sysList(ii).Name);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
    case 'iopzmap'
        for ii = 1:length(sysList)
            responses(ii) = controllib.chart.response.IOPZResponse(modelSources{ii},Name=sysList(ii).Name);
            if ~isempty(responses(ii).DataException)
                throw(responses(ii).DataException);
            end
        end
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalCurrentViewer %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalCurrentViewer(Systems,Names,Viewers)
% Adds systems in specified viewers
for ii = 1:length(Systems)
    Systems{ii}.Name = Names{ii};
end
%----Update the specified LTI Viewers with the new systems
for ct=1:length(Viewers)
    if isa(Viewers(ct),'matlab.ui.Figure') && isvalid(Viewers(ct)) &&...
            isa(Viewers(ct).UserData,'viewgui.ltiviewer')
        viewer = Viewers(ct).UserData;
        importSystems(viewer,Systems,false);
    elseif isa(Viewers(ct),'viewgui.ltiviewer')
        viewer = Viewers(ct);
        importSystems(viewer,Systems,false);
    else
        error(message('Control:analysis:ltiview4'))
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalClearViewer %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalClearViewer(varargin)
% Clears systems in specified viewers
Viewers = varargin{end};
for ct=1:length(Viewers)
    if isa(Viewers(ct),'matlab.ui.Figure') && isvalid(Viewers(ct)) &&...
            isa(Viewers(ct).UserData,'viewgui.ltiviewer')
        viewer = Viewers(ct).UserData;
        for ii = 1:length(viewer.Systems)
            removeSystem(viewer,1);
        end
    elseif isa(Viewers(ct),'viewgui.ltiviewer')
        viewer = Viewers(ct);
        for ii = 1:length(viewer.Systems)
            removeSystem(viewer,1);
        end
    else
        error(message('Control:analysis:ltiview4'))
    end
end
end