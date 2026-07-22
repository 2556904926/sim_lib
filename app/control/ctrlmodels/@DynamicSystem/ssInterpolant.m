function vsys = ssInterpolant(sys,varargin)
%ssInterpolant  Build gridded LTV or LPV model from state-space data.
%
%   Given a collection of local @ss models sampled in time or parameter
%   space, this function builds an LTV or LPV model that interpolates
%   these local behaviors to approximate the global system behavior.
%   You can also use ssInterpolant to turn analytic LTV/LPV models into
%   gridded LTV/LPV models, or to resample gridded LTV/LPV models.
%
%   VSYS = ssInterpolant(SSARRAY) constructs the LTV/LPV interpolant from 
%   the array SSARRAY of state-space models. SSARRAY.SamplingGrid specifies 
%   the underlying time or parameter grid, which can be rectangular (see 
%   NDGRID) or consist of scattered samples. SSARRAY.Offsets specifies the 
%   linearization offsets dx,x,u,y. SSARRAY can be obtained by batch 
%   linearization of a Simulink model (use LINEARIZE with 'StoreOffsets' 
%   option) or by sampling an existing LTV or LPV model (see PSAMPLE). 
%   The output VSYS is an LTVSS model when 'Time' is the only field of 
%   SSARRAY.SamplingGrid and an LPVSS model otherwise.
%
%   VSYS = ssInterpolant(SSARRAY,OFFSETS) explicitly specifies the offsets
%   as a struct array. This is equivalent to 
%      ssarray.Offsets = offsets;
%      vsys = ssInterpolant(ssarray);
%
%   VSYS = ssInterpolant(VSYS,SamplingGrid) constructs the interpolant
%   by sampling an existing LTV or LPV model VSYS at the time or parameter
%   values specified in SamplingGrid. The fields of SamplingGrid must
%   consist of 'Time' and, for LPV models, the parameter names of VSYS.
%   For LPV, this is equivalent to
%      ssarray = psample(vsys,SamplingGrid)
%      vsys = ssInterpolant(ssarray)
%
%   VSYS = ssInterpolant(...,IMETHOD,EMETHOD) also specifies the
%   interpolation and extrapolation methods, see griddedInterpolant
%   and scatteredInterpolant for available options. The defaults are 
%   IMETHOD='linear' and EMETHOD='clip' which uses the nearest point 
%   on the grid boundary.
%
%   Note:
%     * In discrete time, time must be specified as a number k of sampling
%       periods Ts (actual time is k*Ts).
%
%   See also LPVSS, LTVSS, SS, griddedInterpolant, scatteredInterpolant, 
%   LINEARIZE, PSAMPLE.

%   Copyright 2022-2023 The MathWorks, Inc.

if isTimeVarying(sys)
   % Reduce LTV syntax to LTI syntax by sampling VSYS
   narginchk(2,4)
   SG = varargin{1};
   opt = varargin(2:end);
   if ~isstruct(SG)
      error(message('Control:ltiobject:ssInterpolant13'))
   elseif ~all(structfun(@isreal,SG))
      error(message('Control:ltiobject:ssInterpolant14'))
   end
   try
      sys = psample(sys,SG);
   catch ME
      throw(ME)
   end
else
   narginchk(1,4)
   if ~isa(sys,'ss')
      error(message('Control:ltiobject:ssInterpolant11'))
   end
   if nargin>1 && ~(ischar(varargin{1}) || isstring(varargin{1}))
      % ssInterpolant(sys,offsets,...)
      if hasInternalDelay(sys)
         error(message('Control:ltiobject:ssInterpolant15'))
      else
         try
            sys.Offsets = varargin{1};
         catch ME
            throw(ME)
         end
      end
      opt = varargin(2:end);
   else
      opt = varargin;
   end
end

try
   vsys = ssInterpolant_(sys,opt{:});
catch ME
   throw(ME)
end
