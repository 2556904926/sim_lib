function Mout = genfrd(varargin)
%GENFRD  Generalized FRD models.
%
%  Construction:
%    Generalized FRD models (GENFRD) arise when combining ordinary FRD models
%    (see FRD) with tunable compensator blocks or parameterized components
%    (see TUNABLEBLOCK). GENFRD models keep track of how the tunable blocks
%    interact with the fixed dynamics.
%
%  Conversion:
%    M = GENFRD(M,FREQS,FREQUNITS) converts the input/output model M to a
%    generalized FRD model of class @genfrd.  For non-FRD models, GENFRD computes
%    the frequency response at each frequency point in the vector FREQS. The
%    frequencies FREQS are expressed in the units specified by FREQUNITS (see
%    "help genfrd.FrequencyUnit" for a list of valid frequency units). The
%    default is 'rad/TimeUnit' when FREQUNITS is omitted.
%
%    M = GENFRD(M,FREQS,FREQUNITS,TIMEUNITS) further specifies the time units
%    when converting a static model M to GENFRD.
%
%  See also FRD, GETVALUE, CHGFREQUNIT, GENLTI, CONTROLDESIGNBLOCK.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.
ni = nargin;
try
   if ni==1 && isa(varargin{1},'FRDModel')
      % GENFRD(SYS) where SYS is FRD/UFRD/IDFRD
      M = varargin{1};
      funit = M.FrequencyUnit;
      Mout = copyMetaData(M,genfrd_(M)); % frequnit = rad/TimeUnit
   else
      [M,w,funit] = FRDModel.parseFRDInputs('genfrd',varargin(1:min(3,end)));
      % Resolve time units
      if ni>3
         % Fourth argument specified
         if isa(M,'DynamicSystem')
            error(message('Control:lftmodel:genfrd12'))
         else
            tunit = ltipack.matchKey(varargin{4},ltipack.getValidTimeUnits());
            if isempty(tunit)
               error(message('Control:ltiobject:setTimeUnit'))
            end
         end
      else
         if isa(M,'DynamicSystem')
            tunit = M.TimeUnit;
         else
            tunit = 'seconds';  % default for static models
         end
      end
      w = funitconv(funit,'rad/TimeUnit',tunit) * w;  % now in rad/TimeUnit
      Mout = copyMetaData(M,genfrd_(M,w)); % frequnit = rad/TimeUnit
      Mout.TimeUnit = tunit;  % for static M
   end
   % Enforce correct frequency units
   Mout = chgFreqUnit(Mout,funit);
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:frd4',class(M)))
   else
      throw(E)
   end
end
