function sysOut = frd(varargin)
%FRD  Constructs or converts to Frequency Response Data model.
%
%   Frequency Response Data (FRD) models store the frequency response of linear
%   systems, for example, experimental data collected with a frequency analyzer.
%
%  Construction:
%    SYS = FRD(RESPONSE,FREQS) creates an FRD model SYS with response data
%    RESPONSE specified at the frequency points in FREQS. The output SYS
%    is an object of class @frd.
%
%    SYS = FRD(RESPONSE,FREQS,TS) creates a discrete-time FRD model with
%    sample time TS (a positive value).
%
%    SYS = FRD creates an empty FRD model.
%
%    You can set additional model properties by using name/value pairs.
%    For example,
%       sys = frd(1:10,1:10,'FrequencyUnit','Hz')
%    further stipulates that the frequency vector is given in Hz. Type
%    "properties(frd)" for a complete list of model properties, and type
%       help frd.<PropertyName>
%    for help on a particular property. For example, "help frd.ioDelay"
%    provides information about the "ioDelay" property.
%
%  Data format:
%    For SISO models, FREQS is a vector of real frequencies, and RESPONSE
%    is a vector of frequency response values at these frequencies.
%
%    For MIMO FRD models with NY outputs, NU inputs, and NF frequency points,
%    RESPONSE is a double array of size [NY NU NF] where RESPONSE(i,j,k)
%    specifies the frequency response from input j to output i at the
%    frequency point FREQS(k).
%
%    By default, the frequency points FREQS are assumed to be in radians/second. 
%    If FREQS is expressed in other units, set the "FrequencyUnit" and 
%    "TimeUnit" properties accordingly. For example, if FREQS is expressed  
%    in Hz, set FrequencyUnit='Hz'. If FREQS is expressed in radians/minute,
%    set FrequencyUnit='rad/TimeUnit' and TimeUnit='minutes'.
%
%  Arrays of FRD models:
%    You can create arrays of FRD models by using an ND array for RESPONSE.
%    For example, if RESPONSE is an array of size [NY NU NF 3 4], then
%       SYS = FRD(RESPONSE,FREQS)
%    creates the 3-by-4 array of FRD models, where
%       SYS(:,:,k,m) = FRD(RESPONSE(:,:,:,k,m),FREQS),  k=1:3,  m=1:4.
%    Each of these FRD models has NY outputs, NU inputs, and data at
%    the frequencies FREQS.
%
%  Conversion:
%    SYS = FRD(SYS,FREQS,UNIT) converts any dynamic system SYS to the FRD
%    representation by computing the system response at each frequency
%    point in the vector FREQS.  The frequencies FREQS are expressed in
%    the unit specified by the string UNIT (see "help frd.FrequencyUnit" for
%    a list of frequency units). When UNIT is omitted, the default is
%    'rad/TimeUnit' (relative to the time units specified in SYS.TimeUnit).
%    The resulting SYS is of class @frd.
%
%  See also FRDATA, CHGFREQUNIT, TF, ZPK, SS, DYNAMICSYSTEM.

%   Author(s): S. Almy
%   Copyright 1986-2011 The MathWorks, Inc.
try
   if nargin==1 && isa(varargin{1},'FRDModel')
      % FRD(SYS) where SYS is GENFRD/UFRD/IDFRD
      sys = varargin{1};
      sysOut = copyMetaData(sys,frd_(sys));  % frequnit = rad/TimeUnit
      sysOut = chgFreqUnit(sysOut,sys.FrequencyUnit);
   else
      [ConstructFlag,InputList] = lti.isContructorCall('frd',varargin);
      if ConstructFlag
         % FRD(R,W,LTISYS): Try again with LTI system replaced by struct
         sysOut = frd(InputList{:});
      else
         % FRD(SYS,FREQ,UNIT)
         [sys,w,funit] = FRDModel.parseFRDInputs('frd',InputList);
         % Express frequencies in rad/TimeUnit
         w = funitconv(funit,'rad/TimeUnit',sys.TimeUnit) * w;
         sysOut = copyMetaData(sys,frd_(sys,w));  % frequnit = rad/TimeUnit
         sysOut = chgFreqUnit(sysOut,funit);
         if isa(sys,'uss')
            % Warn about backward incompatible change in R2011b (frd(uss,w)
            % used to return UFRD)
            warning(message('Control:transformation:frd3'))
         end
      end
   end
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:frd4',class(sys)))
   else
      throw(E)
   end
end
