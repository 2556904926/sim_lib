function asys = psample(sys,varargin)
%PSAMPLE  Sample LTV or LPV dynamics.
%
%   SSARRAY = PSAMPLE(VSYS,T) samples the dynamics of the LTVSS model VSYS 
%   at time T. In continuous time, T is expressed in the time units of VSYS.
%   In discrete time, T is the number k of sampling periods (the actual 
%   time is k*Ts). 
%
%   SSARRAY = PSAMPLE(VSYS,T,P) samples the dynamics of the LPVSS model 
%   VSYS at the single point (T,P) where T is time and P is a vector
%   of parameter values. Set T=[] when the dynamics only depend on P. 
%
%   SSARRAY = PSAMPLE(VSYS,TVALS,P1VALS,...,PNVALS) samples the dynamics
%   over a grid of (T,P) values. TVALS is an array of time values, and
%   P1VALS,...,PNVALS are commensurate arrays of values for the parameters
%   P1,...,PN of LPVSS models (see VSYS.ParameterName for parameter list).
%   Omit P1VALS,... for LTVSS models, and set TVALS=[] for LPVSS models
%   whose dynamics only depend on P.
%
%   SSARRAY = PSAMPLE(VSYS,SGRID) specifies the same information as a struct
%   SGRID whose fields are the names in VSYS.ParameterName and optionally
%   "Time". For example, if VSYS has two parameters named "speed" and
%   "altitude" and no explicit time dependence, SGRID is the struct
%      SGRID = struct("speed",P1VALS,"altitude",P2VALS).
%
%   SSARRAY = PSAMPLE(VSYS) is equivalent to PSAMPLE(VSYS,VSYS.Grid) for
%   gridded LTV or LPV models (see ssInterpolant). This provides a quick
%   way to access the state-space matrices and offsets used to construct
%   such models.
%
%   PSAMPLE returns an array SSARRAY of time-invariant state-space models
%   (see SS) where
%      * SSARRAY.SamplingGrid keeps track of the dependence of each model
%        on T,P.
%      * SSARRAY.Offsets contains the offset values as a function of T,P.
%
%   See also LTVSS, LPVSS, SS, SSINTERPOLANT.

%   Copyright 2023 The MathWorks, Inc.
ni = nargin;
DF = sys.DataFunction_;
LPV = (nargin(DF)>1);
GRIDDED = isa(sys,'GriddedLTVSS');
if LPV
   pNames = sys.ParameterName;
else
   pNames = cell(0,1);
end
np = numel(pNames);

% Reduce to PSAMPLE(VSYS,SGRID)
if ni==1
   % PSAMPLE(VSYS)
   if GRIDDED
      sgrid = sys.Grid;
   else
      error(message('Control:ltiobject:SAMPLE10'))
   end
elseif ni==2 && isstruct(varargin{1})
   % PSAMPLE(VSYS,SGRID)
   sgrid = varargin{1};
   if ~(LPV || isfield(sgrid,'Time'))
      % Time must be a field of SGRID for LTV
      error(message('Control:ltiobject:SAMPLE1'))
   elseif LPV && ~all(ismember(pNames,fieldnames(sgrid)))
      % All parameters must appear as fields in SGRID for LPV
      error(message('Control:ltiobject:SAMPLE5'))
   end
   % Ignore and remove fields not related to Time and parameter names
   sgrid = rmfield(sgrid,setdiff(fieldnames(sgrid),[{'Time'};pNames]));
else
   % PSAMPLE(SYS,T,P1,...)
   t = varargin{1};
   if ni==3 && isscalar(t) && numel(varargin{2})==np
      % Sample at single point
      sgrid = cell2struct(num2cell([t;varargin{2}(:)]),[{'Time'};pNames],1);
   elseif ni==2+np
      % Sample at multiple points
      if isscalar(t) && ni>2
         % Support scalar expansion of time in PSAMPLE(VSYS,0,P1,...)
         t = repmat(t,size(varargin{2}));
      end
      pvals = varargin(2:ni-1)';
      if isempty(t)
         sgrid = cell2struct(pvals,pNames,1);
      else
         sgrid = cell2struct([{t};pvals],[{'Time'};pNames],1);
      end
   else
      error(message('Control:ltiobject:SAMPLE6'))
   end
end

% Validate sampling grid
try
   sgrid = ltipack.SamplingGrid(sgrid);
catch ME
   throw(ME)
end
SGS = getSize(sgrid);
sgrid = getData(sgrid); % convert back to struct
      
% Validate time or populate it if missing
if isfield(sgrid,'Time')
   t = sgrid.Time;
   if LPV && ~(isreal(t) && allfinite(t))
      error(message('Control:ltiobject:SAMPLE8'))
   elseif ~LPV && ~(isreal(t) && isvector(t) && allfinite(t))
      error(message('Control:ltiobject:SAMPLE3'))
   end
else
   t = repmat(sys.t0_,SGS);
   sgrid.Time = t;
end

% Create SS array
[ny,nu] = size(sys);
nx = sys.Nx_;
nfd = sys.Nfd_;
ns = prod(SGS);        % number of samples
if ns>0
   % Arrange p samples as np-ny-ns array
   p = zeros(np,ns);
   for ct=1:np
      p(ct,:) = reshape(sgrid.(pNames{ct}),[1 ns]);
   end
   % Acquire data
   Data = createArray(SGS,'ltipack.ssdata');
   Delay0 = ltipack.utDelayStruct(ny,nu,true);
   Ts = sys.Ts;
   if Ts==0 || GRIDDED
      tk = t;
   else
      tk = round(t);
      if max(abs(t-tk))>1e-3
         error(message('Control:ltiobject:SAMPLE11'))
      end
      sgrid.Time = tk;
   end
   try
      for ct=1:ns
         if LPV
            [Data(ct).a,Data(ct).b,Data(ct).c,Data(ct).d,Data(ct).e,...
               dx0,x0,u0,y0,Delay] = DF(tk(ct),p(:,ct));
         else
            [Data(ct).a,Data(ct).b,Data(ct).c,Data(ct).d,Data(ct).e,...
               dx0,x0,u0,y0,Delay] = DF(tk(ct));
         end
         [Data(ct).dx0,Data(ct).x0,Data(ct).u0,Data(ct).y0] = ...
            ltvpack.util.expandOffsets(dx0,x0,u0,y0,nx,nu+nfd,ny+nfd);
         if isempty(Delay)
            Data(ct).Delay = Delay0;
         else
            Data(ct).Delay = ltvpack.util.ltv2ltiDelay(Delay);
         end
         Data(ct).Ts = Ts;
      end
   catch ME
      error(message('Control:ltiobject:SAMPLE7',ct))
   end
   asys = ss.make(Data);
else
   asys = ss(zeros([ny,nu,SGS]));
end
asys = copyMetaData(sys,asys);
asys.StateName = sys.StateName;
asys.StatePath = sys.StatePath;
asys.StateUnit = sys.StateUnit;
asys.TimeUnit = sys.TimeUnit;
asys.SamplingGrid = sgrid;
