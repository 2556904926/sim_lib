function h = pidtool(varargin)
%PIDTOOL
%
% The PIDTOOL command is replaced by the pidTuner command.
%
%   See also PIDTUNER

% Author(s): Rong Chen 30-Apr-2010
% Copyright 2010-2020 The MathWorks, Inc.

varargin = controllib.internal.util.hString2Char(varargin);

ni = nargin;
if ni==0
   sys = zpk(1);
   C = 'p';
elseif ni==1
   sys = varargin{1};
   C = 'pi';
elseif ni==2
   sys = varargin{1};
   C = varargin{2};
else
   ctrlMsgUtils.error('Control:general:TwoOrMoreInputsRequired','pidtool','pidtool');
end

%% pre-process sys
if isa(sys,'DynamicSystem')
   if ~issiso(sys)
      ctrlMsgUtils.error('Control:design:pidtune1','pidtool');
   end
   if issparse(sys)
      ctrlMsgUtils.error('Control:pidtool:ErrorSparseModel');
   end
   if nmodels(sys)~=1
      ctrlMsgUtils.error('Control:design:pidtune6','pidtool');
   end
   if isa(sys,'idnlmodel')
      ctrlMsgUtils.error('Control:design:pidtune1','pidtool');
   elseif isa(sys,'idfrd')
      % convert to @frd
      sys = frd(sys); % this protects against negative frequencies in sys
   end
else
   ctrlMsgUtils.error('Control:design:pidtune1','pidtool');
end

%% pre-process Ts: -1 is not accepted
Ts = sys.Ts;
if Ts<0
   ctrlMsgUtils.error('Control:design:pidtune4','pidtool');
end

%% pre-process Type and C (@ss, @tf, @zpk, @pid, @pidstd, @ltiblock.*)
if ischar(C)
   % get type
   if ~any(strcmpi(C,{'p','i','pi','pd','pdf','pid','pidf','pi2','pd2','pdf2','pid2','pidf2',...
         'i-pd','id-p','pi-d','i-pdf','idf-p','pi-df'}))
      ctrlMsgUtils.error('Control:design:pidtune2','pidtool','pidtool');
   end
   Type = C;
   Baseline = [];
elseif (isa(C,'pid') || isa(C,'pidstd'))
   % check array
   if nmodels(C)~=1
      ctrlMsgUtils.error('Control:design:pidtune2','pidtool','pidtool');
   end
   % check sample time and its unit
   if  C.Ts~=Ts || ~strcmp(C.TimeUnit,sys.TimeUnit)
      ctrlMsgUtils.error('Control:design:pidtune10','pidtool');
   end
   Type = getType(C);
   Baseline = C;
elseif isa(C,'DynamicSystem')
   % check FRD model, siso, array
   if isa(C,'FRDModel') || ~issiso(C) || nmodels(C)~=1
      ctrlMsgUtils.error('Control:design:pidtune2','pidtool','pidtool');
   end
   % check sample time
   if  C.Ts~=Ts || (Ts>0 && ~strcmp(C.TimeUnit,sys.TimeUnit))
      ctrlMsgUtils.error('Control:design:pidtune10','pidtool');
   end
   Type = 'pi';
   Baseline = C;
else
   ctrlMsgUtils.error('Control:design:pidtune2','pidtool','pidtool');
end

%% start GUI
Prefs = cstprefs.tbxprefs;
ver = Prefs.PIDTunerPreferences.Version;

if ver == 1
   if nargout>0
      h = pidtool.tunerdlg(sys,Type,Baseline);
   else
      pidtool.tunerdlg(sys,Type,Baseline);
   end
else
   sysname = '';
   if nargin >= 1
      sysname = inputname(1);
   end
   if isempty(sysname)
      sysname = 'Plant';
   end
   eval([sysname ' = sys;']);
   cmd = ['pidtool.PIDToolDesktop(' sysname ',Type,Baseline);'];
   if nargout>0
      h = eval(cmd);
   else
      eval(cmd);
   end
end
