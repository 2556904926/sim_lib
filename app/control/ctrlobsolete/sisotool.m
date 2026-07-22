function varargout = sisotool(varargin)
%SISOTOOL  SISO Design Tool.
%
%   SISOTOOL opens the SISO Design Tool.  This Graphical User Interface
%   lets you design single-input/single-output (SISO) compensators by
%   graphically interacting with the root locus, Bode, and Nichols plots of
%   the open-loop system.  To import the plant data into the SISO Tool,
%   select the Import item from the File menu. By default, the control
%   system configuration is
%
%             r -->[ F ]-->O--->[ C ]--->[ G ]----+---> y
%                        - |                      |
%                          +-------[ H ]----------+
%
%   where C and F are tunable compensators.
%
%   SISOTOOL(G) specifies the plant model G to be used in the SISO Tool.
%   Here G is any linear model created with TF, ZPK, or SS.
%
%   SISOTOOL(G,C) and SISOTOOL(G,C,H,F) further specify values for the
%   feedback compensator C, sensor H, and prefilter F.  By default,
%   C, H, and F are all unit gains.
%
%   SISOTOOL(VIEWS) or SISOTOOL(VIEWS,G,...) specifies the initial set of
%   views for graphically editing C and F.  You can set VIEWS to any of the
%   following strings or combination of strings:
%       'rlocus'      Root locus plot
%       'bode'        Bode diagram of the open-loop response
%       'nichols'     Nichols plot of the open-loop response
%       'filter'      Bode diagram of the prefilter F
%   For example
%       sisotool({'nichols','bode'})
%   opens a SISO Design Tool showing the Nichols plot and Bode diagrams
%   for the open loop CGH.
%
%   SISOTOOL(INITDATA) initializes the SISO Design Tool with more general
%   control system configurations.  Use SISOINIT to build the initialization
%   data structure INITDATA.
%
%   SISOTOOL(SESSIONDATA) opens the SISO Design Tool with a previously
%   saved session where SESSIONDATA is the MAT file for the saved session.
%
%   See also SISOINIT, LTIVIEW, RLOCUS, BODE, NICHOLS.

%   Author(s): Karen D. Gondoly, P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% Obsolete Syntax:  extra argument OPTIONS (structure) to specify any
% of the following options:
%   OPTIONS.Location    Location of C ('forward' for forward path,
%                       'feedback' for return path)
%   OPTIONS.Sign        Feedback sign (-1 for negative, +1 for positive)
Version = controllibutils.CSTCustomSettings.getControlSystemDesignerVersion;
if Version == 1
    % Process and pass inputnames
    ni=nargin;
    narginchk(0,6)
    InputNames = struct('FromSisotool',true);
    % Parse input list
    % a) Views
    LastInput = 0;
    if ni && (iscellstr(varargin{1}) || ischar(varargin{1}))
        % First input is a view
        LastInput = LastInput + 1;
    end
    idxG = LastInput+1; % position of G argument
    if ni>=idxG
        % System name is inherited from G
        InputNames.InitData = inputname(idxG);
    end
    
    for ct=1:min(4,ni-LastInput),
        NextArg = varargin{LastInput+1};
        isModel = isa(NextArg,'lti'); % REVISIT: should be "system" parent class
        if ~isa(NextArg,'double') && ~isModel
            % done scanning model inputs
            break
        else
            if ~isequal(NextArg,[])  % skip []'s
                VarName = inputname(LastInput+1);
                InputNames.ModelVars{ct} = VarName;
            end
        end
        LastInput = LastInput+1;
    end
    h = controlSystemDesigner(varargin{:},InputNames);
else
    h = controlSystemDesigner(varargin{:});
end
if nargout
    varargout{1} = h;
end
