function [PID, varargout] = pidtune(G,C,varargin) 
%PIDTUNE  Tune PID controller.
%  
%   PIDTUNE designs a PID controller C for the unit feedback loop
%  
%               r --->O--->[ C ]--->[ G ]---+---> y
%                   - |                     |
%                     +---------------------+
%
%   Given a plant model G, PIDTUNE automatically tunes the PID gains to
%   balance performance (response time) and robustness (stability margins). 
%   You can select from various PID configurations and specify your own 
%   response time and phase margin targets. Note that increasing performance 
%   typically decreases robustness and vice versa.
%  
%   C = PIDTUNE(G,TYPE) designs a PID controller for the single-input,
%   single-output plant G. You can specify any type of linear system for G
%   (see LTI). The string TYPE specifies the controller type among the 
%   following:
%  
%      'P'     Proportional only control
%      'I'     Integral only control
%      'PI'    PI control
%      'PD'    PD control  
%      'PDF'   PD control with first order derivative filter 
%      'PID'   PID control
%      'PIDF'  PID control with first order derivative filter
%      'PI2'   2-dof PI control
%      'PD2'   2-dof PD control  
%      'PDF2'  2-dof PD control with first order derivative filter 
%      'PID2'  2-dof PID control
%      'PIDF2' 2-dof PID control with first order derivative filter
%      'I-PD'  2-DOF PID control with b = 0, c = 0
%      'I-PDF' 2-DOF PID control with first order derivative filter and b = 0, c = 0
%      'ID-P'  2-DOF PID control with b = 0, c = 1
%      'IDF-P' 2-DOF PID control with first order derivative filter and b = 0, c = 1
%      'PI-D'  2-DOF PID control with b = 1, c = 0
%      'PI-DF' 2-DOF PID control with first order derivative filter and b = 1, c = 0
%  
%   PIDTUNE returns a PID/PID2 object C with the same sample time as G. If G
%   is an array of LTI models, PIDTUNE designs a controller for each plant 
%   model and returns an array C of PID/PID2 objects.
%  
%   C = PIDTUNE(G,C0) constrains C to match the structure of the PID, PID2,
%   PIDSTD or PIDSTD2 object C0. The resulting C has the same type, form, and
%   integrator/derivative formulas as C0. For example, to tune a discrete-
%   time PI controller in Standard Form with the sample time of 0.1 and 
%   the Trapezoidal formula, set
%      C0 = pidstd(1,1,'Ts',0.1,'IFormula','T')
%
%   C = PIDTUNE(G,TYPE,WC) and C = PIDTUNE(G,C0,WC) specify a target value
%   WC (in rad/TimeUnit relative to the time units of G) for the 0dB gain
%   crossover frequency of the open-loop response L = G*C. Typically, WC
%   roughly sets the control bandwidth and 1/WC roughly sets the closed-loop 
%   response time. Increase WC to speed up the response and decrease WC to 
%   improve stability. When omitted, WC is picked automatically based on the 
%   plant dynamics. 
%  
%   C = PIDTUNE(G,...,OPTIONS) specifies additional tuning options such as 
%   the target phase margin. Use PIDTUNEOPTIONS command to create the option 
%   set OPTIONS.
%
%   [C,INFO] = PIDTUNE(G,...) also returns a structure INFO with information
%   about closed-loop stability, the selected gain crossover frequency, and 
%   the actual phase margin.
%  
%   Example:
%      G = tf(1,[1 3 3 1]); % plant model
%
%      % Design a PI controller in parallel form
%      [C Info] = pidtune(G,'pi') 
%
%      % Double the crossover frequency for faster response
%      wc = 2*Info.CrossoverFrequency;
%      [C Info] = pidtune(G,'pi',wc) 
%
%      % Improve stability margins by adding derivative action
%      [C Info] = pidtune(G,'pidf',wc) 
%
%      % Design a discrete-time PIDF controller in Standard Form  
%      C0 = pidstd(1,1,1,1,'Ts',0.1,'IFormula','Trapezoidal',...
%                                    'DFormula','BackwardEuler');
%      [C info] = pidtune(c2d(G,0.1),C0)
%
%      % Design a 2-dof PID controller
%      [C Info] = pidtune(G,'pidf2');
%      or
%      C0 = pid2(1,1,1,1,1,1,'Ts',0.1);
%      [C Info] = pidtune(G,C0)
%   
%   See also PIDTUNEOPTIONS, PIDTUNER, LTI.

% Author(s): Rong Chen 01-Mar-2015
%   Copyright 2009-2011 The MathWorks, Inc.

ni = nargin;
no = nargout;
narginchk(2,4)

% Convert any string to char
C = controllib.internal.util.hString2Char(C);

%% pre-process G: SISO SingleRateSystem
if ~(isa(G,'DynamicSystem') && issiso(G))
   error(message('Control:design:pidtune1','pidtune'))
end

%% pre-process Ts: -1 is not accepted
Ts = G.Ts;
if Ts<0
    error(message('Control:design:pidtune4','pidtune'))
end

%% pre-process Type and C
fixedBC = [];
fixBC = false;
if ischar(C) 
    if any(strcmpi(C,{'i-pd','id-p','pi-d','i-pdf','idf-p','pi-df'}))
        switch lower(C)
            case 'i-pd'
                C = 'pid2';
                fixedBC = [0 0];
            case 'id-p'
                C = 'pid2';
                fixedBC = [0 1];
            case 'pi-d'
                C = 'pid2';
                fixedBC = [1 0];
            case 'i-pdf'
                C = 'pidf2';
                fixedBC = [0 0];
            case 'idf-p'
                C = 'pidf2';
                fixedBC = [0 1];
            case 'pi-df'
                C = 'pidf2';
                fixedBC = [1 0];
        end
        fixBC = true;
    end
    % get type
    if any(strcmpi(C,{'p','i','pi','pd','pdf','pid','pidf','pi2','pd2','pdf2','pid2','pidf2'}))
        C = ltipack.getPIDfromType(C,'parallel',Ts,G.TimeUnit);
        if ~isempty(fixedBC)
           C.b = fixedBC(1);
           C.c = fixedBC(2);
        end
    else
        error(message('Control:design:pidtune2','pidtune','pidtune'))
    end
elseif isa(C,'pid') || isa(C,'pidstd') || isa(C,'pid2') || isa(C,'pidstd2')
   % Validate C0
   if nmodels(C)~=1
      error(message('Control:design:pidtune2','pidtune','pidtune'))
   elseif ~(C.Ts==Ts && strcmp(C.TimeUnit,G.TimeUnit))
      error(message('Control:design:pidtune10','pidtune'))
   end
   C.TimeUnit = G.TimeUnit;
else
   error(message('Control:design:pidtune2','pidtune','pidtune'))
end

% Look for option set
if ni==2 || (ni==3 && isnumeric(varargin{1}))
   Options = pidtuneOptions;  % default
else
   Options = varargin{ni-2};  ni = ni-1;
   if ~(isa(Options,'ltioptions.pidtune') && isscalar(Options))
      error(message('Control:design:pidtune3'))
   end
end
   
% Look for WC convenience input
if ni>2
   try
      % Overwrite value of corresponding (hidden) option
      Options.CrossoverFrequency = varargin{1};
   catch ME
      throw(ME)
   end
end

% For discrete time PID, if specified, WC must be smaller than pi/Ts
if Ts>0 && ~isempty(Options.CrossoverFrequency) && Options.CrossoverFrequency>=pi/Ts
   error(message('Control:design:pidtune5'))
end    

% For @frd plant, WC must be smaller than the largest frequency
if isa(G,'FRDModel') && ~isempty(Options.CrossoverFrequency) && ...
      Options.CrossoverFrequency>=(G.Frequency(end)*funitconv(G.FrequencyUnit,'rad/TimeUnit'))
   error(message('Control:design:pidtune13'))
end

% Tune PID
try
   [PID,varargout{1:no-1}] = pidtune_(getValue_(G),C,Options,fixBC);
catch ME
   throw(ME)
end

