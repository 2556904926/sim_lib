function fb = bandwidth(sys,drop)
%BANDWIDTH  Computes the frequency response bandwidth.
%
%   FB = BANDWIDTH(SYS) returns the bandwidth FB of the SISO dynamic
%   system SYS, defined as the first frequency where the gain drops below
%   70.79 percent (-3 dB) of its DC value. The frequency FB is expressed
%   in rad/TimeUnit (relative to the time units specified in SYS.TimeUnit,
%   the default being seconds). For FRD models, BANDWIDTH uses the first
%   frequency point to approximate the DC gain.
%
%   FB = BANDWIDTH(SYS,DBDROP) further specifies the critical gain drop
%   in dB. The default value is -3 dB or a 70.79 percent drop.
%
%   If SYS is an array of dynamic systems, BANDWIDTH returns an array FB
%   of the same size where FB(k) = BANDWIDTH(SYS(:,:,k)).
%
%   See also DCGAIN, ISSISO, DYNAMICSYSTEM.

%   Copyright 1986-2011 The MathWorks, Inc.
if ~issiso(sys)
   ctrlMsgUtils.error('Control:general:FirstArgSISOModel','bandwidth');
elseif nargin==1
   drop = -3;  % -3dB by default (standard definition)
elseif ~isreal(drop) || ~isscalar(drop) || drop>=0
   ctrlMsgUtils.error('Control:analysis:bandwidth1');
end

% Compute bandwidth
try
   fb = bandwidth_(sys,drop);
catch E
   ltipack.throw(E,'command','bandwidth',class(sys))
end

if any(isnan(fb(:)))
   ctrlMsgUtils.warning('Control:analysis:BandwidthNaN')
end