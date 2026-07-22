function varargout = controlSystemDesigner(varargin)
%controlSystemDesigner Control System Designer App.
%
%   controlSystemDesigner opens the Control System Designer app.  This User
%   Interface lets you design single-input/single-output (SISO)
%   compensators by graphically interacting with the root locus, Bode, and
%   Nichols plots of the open-loop system.  To import the plant data into
%   the app, select the Import item from the File menu. By default, the
%   control system configuration is
%
%             r -->[ F ]-->O--->[ C ]--->[ G ]----+---> y
%                        - |                      |
%                          +-------[ H ]----------+
%
%   where C and F are tunable compensators.
%
%   controlSystemDesigner(G) specifies the plant model G to be used in the
%   app. Here G is any linear model created with TF, ZPK, or SS.
%
%   controlSystemDesigner(G,C) and controlSystemDesigner(G,C,H,F) further
%   specify values for the feedback compensator C, sensor H, and prefilter
%   F.  By default, C, H, and F are all unit gains.
%
%   controlSystemDesigner(VIEWS) or controlSystemDesigner(VIEWS,G,...)
%   specifies the initial set of views for graphically editing C and F.
%   You can set VIEWS to any of the following strings or combination of
%   strings:
%       'rlocus'      Root locus plot
%       'bode'        Bode diagram of the open-loop response
%       'nichols'     Nichols plot of the open-loop response
%       'filter'      Bode diagram of the prefilter F
%   For example
%       controlSystemDesigner({'nichols','bode'})
%   opens a Control System Designer app showing the Nichols plot and Bode
%   diagrams for the open loop CGH.
%
%   controlSystemDesigner(INITDATA) initializes the Control System Designer
%   app with more general control system configurations.  Use SISOINIT to
%   build the initialization data structure INITDATA.
%
%   controlSystemDesigner(SESSIONDATA) opens the Control System Designer
%   app with a previously saved session where SESSIONDATA is the MAT file
%   for the saved session.
%
%   See also SISOINIT, LINEARSYSTEMANALYZER, RLOCUS, BODE, NICHOLS.

%   Copyright 1986-2020 The MathWorks, Inc.

% Obsolete Syntax:  extra argument OPTIONS (structure) to specify any
% of the following options:
%   OPTIONS.Location    Location of C ('forward' for forward path,
%                       'feedback' for return path)
%   OPTIONS.Sign        Feedback sign (-1 for negative, +1 for positive)

varargin = controllib.internal.util.hString2Char(varargin);

Version = controllibutils.CSTCustomSettings.getControlSystemDesignerVersion;
switch Version
    case {2,3}
        ni=nargin;
        narginchk(0,6)
        try
            isLoading = false;
            h = [];
            if ni==0
                % Open GUI w/o data
                for ct = 1:4
                    Models{ct} = tf(1);
                end
                Arch = ctrlguis.csdesignerapp.data.architectures.internal.Config1Architecture(Models{2},Models{4},Models{1},Models{3});
                h = ctrlguis.csdesignerapp.internal.ControlSystemDesignerApp(Arch);
                DesignViews = {'rlocus','bode'};
                AnalysisView = true;
            elseif isequal(length(varargin),1) && isa(varargin{1},'slTuner')
                Arch = ctrlguis.csdesignerapp.data.architectures.internal.SimulinkArchitecture(varargin{1});
                h = ctrlguis.csdesignerapp.internal.ControlSystemDesignerApp(Arch);
                DesignViews = {};
                AnalysisView = false;
            elseif isequal(length(varargin),1) && isa(varargin{1},'char') && ...
                    ~any(strcmpi(varargin{1},{'rlocus','bode','nichols','filter'}))
                DesignViews = {};
                AnalysisView = false;
                % load project (Version 3,2)
                sw = ctrlMsgUtils.SuspendWarnings('Slcontrol:sllinearizer:AddPointOpening','Control:ltiobject:UpdatePreviousVersion',...
                                                  'Simulink:Commands:InvSimulinkObjectName','Slcontrol:controldesign:InvalidParam2',...
                                                  'Slcontrol:sllinearizer:NonExistentModel');

                % check if the file has invalid/stale data (e.g. from CETM
                % project)
                fname = varargin{1};
                filevars = who('-file',fname);
                if ismember("Projects",filevars)
                    error(message('Control:designerapp:ErrorCETMSession'));
                end
                S = load(fname);
                delete(sw);
                if ~isempty(S) && ((isfield(S,getString(message('Control:designerapp:CSDSessionName'))) && isa(S.ControlSystemDesignerSession,'ctrlguis.csdesignerapp.data.internal.SessionData')))
                    % Open GUI w/o data
                    for ct = 1:4
                        Models{ct} = tf(1);
                    end
                    Arch = ctrlguis.csdesignerapp.data.architectures.internal.Config1Architecture(Models{2},Models{4},Models{1},Models{3});
                    h = ctrlguis.csdesignerapp.internal.ControlSystemDesignerApp(Arch);
                    isLoading = true;
                    h.loadSession(S);
                    isLoading = false;
                end
            elseif isa(varargin{1},'sisodata.design') || isa(varargin{1}, 'sisogui.session')||...
                    isa(varargin{1},'ctrlguis.csdesignerapp.data.internal.SessionData')
                DesignViews = {};
                AnalysisView = false;
                % From sisoinit
                for ct = 1:4
                    Models{ct} = tf(1);
                end
                Arch = ctrlguis.csdesignerapp.data.architectures.internal.Config1Architecture(Models{2},Models{4},Models{1},Models{3});
                h = ctrlguis.csdesignerapp.internal.ControlSystemDesignerApp(Arch);
                isLoading = true;
                h.loadSession(varargin{1});
                isLoading = false;
            else
                AnalysisView = true;
                % Parse input list
                % a) Views
                LastInput = 0;
                ValidViews = {'rlocus','bode','nichols','filter'};
                if ni && (iscellstr(varargin{1}) || ischar(varargin{1}))
                    DesignViews = varargin{1};
                    if ~iscell(DesignViews)
                        DesignViews = {DesignViews};
                    end
                    AllValid = all(ismember(DesignViews,ValidViews));
                    if ~AllValid,
                        error(message('Control:compDesignTask:SISOTool2'))
                    end
                    LastInput = LastInput + 1;
                    UseDefaultDesignViews = false;
                else
                    UseDefaultDesignViews = true;
                    DesignViews = {'rlocus','bode'};
                end
                
                % Models G,C,H,F
                Models = cell(4,1);
                for ct=1:min(4,ni-LastInput),
                    NextArg = varargin{LastInput+1};
                    isModel = isa(NextArg,'lti'); % REVISIT: should be "system" parent class
                    if ~isa(NextArg,'double') && ~isModel
                        % done scanning model inputs
                        break
                    elseif issparse(NextArg)
                        error(message('Control:designerapp:ErrorSparseModel'));
                    else
                        if ~isequal(NextArg,[])  % skip []'s
                            Models{ct} = NextArg;
                        end
                    end
                    LastInput = LastInput+1;
                end
                
                % Options (last arg)
                if ni>LastInput && isa(varargin{LastInput+1},'struct')
                    Options = varargin{LastInput+1};
                    LastInput = LastInput+1;
                else
                    Options = [];
                end
                
                % There should be no more input argument
                if ni>LastInput,
                    error(message('Control:general:InvalidSyntaxForCommand','sisotool','sisotool'))
                end
                
                % Read options
                if isfield(Options,'Location')
                    LoopConfig = Options.Location;
                    if ~isa(LoopConfig,'char')
                        error(message('Control:compDesignTask:SISOTool3'))
                    else
                        switch lower(LoopConfig(1:min(2,end))),
                            case 'fo',
                                LoopConfig = 1;
                            case 'fe',
                                LoopConfig = 2;
                            otherwise,
                                error(message('Control:compDesignTask:SISOTool3'))
                        end
                    end
                else
                    LoopConfig = 1;
                end
                
                if isfield(Options,'Sign')
                    LoopSign = Options.Sign;
                    if ~ismember(LoopSign,[1,-1]),
                        error(message('Control:compDesignTask:SISOTool4'))
                    end
                else
                    LoopSign = -1;
                end
                
                % Build init structure
                for ct=1:4
                    if isempty(Models{ct})
                        Models{ct} = tf(1);
                    end
                end
                
                if UseDefaultDesignViews
                    if any(cellfun(@(x)isa(x,'frd'),Models))
                        DesignViews = {'bode'};
                    else
                        DesignViews = {'rlocus','bode'};
                    end
                end
                
                % At this point, we have models, design views, loop sign,
                % configuration
                ArchClass = sprintf('Config%dArchitecture',LoopConfig);
                Arch = ctrlguis.csdesignerapp.data.architectures.internal.(ArchClass)(Models{2},Models{4},Models{1},Models{3});
                LS = Arch.getLoopSignWithID;
                setLoopSignWithID(Arch, LS{1},LoopSign);
                h = ctrlguis.csdesignerapp.internal.ControlSystemDesignerApp(Arch);
            end
            createPlots(h,AnalysisView,DesignViews);
            if nargout
                varargout{1} = h;
            end
        catch ME
            if isLoading && isvalid(h)
                % Error during loading. Close the invalid control system
                % designer session
                delete(h);
            end
            throw(ME);
        end
end