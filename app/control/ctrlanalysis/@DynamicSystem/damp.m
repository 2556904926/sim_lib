function [wnout,z,r] = damp(sys,varargin)
%DAMP  Natural frequency and damping of linear system dynamics.
%
%    [Wn,Z] = DAMP(SYS) returns vectors Wn and Z containing the natural
%    frequencies and damping factors of the linear system SYS. For
%    discrete-time models, the equivalent s-plane natural frequency and
%    damping ratio of an eigenvalue lambda are:
%
%       Wn = abs(log(lambda))/Ts ,   Z = -cos(angle(log(lambda))) .
%
%    If the sample time, Ts, is undefined, the software assumes Ts = 1.
%
%    [Wn,Z,P] = DAMP(SYS) also returns the poles P of SYS.
%
%    When invoked without left-hand arguments, DAMP prints the poles with
%    their natural frequencies, damping factors, and time constants in a
%    tabular format on the screen. The poles are sorted by increasing
%    frequency. Both Wn and P are expressed in the reciprocal of the time
%    units of SYS. For example, 1/minute if SYS.TimeUnit = 'minutes'.
%
%    See also POLE, ESORT, DSORT, PZMAP, ZERO, LTI, DYNAMICSYSTEM.

%   J.N. Little, Clay M. Thompson, Pascal Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% Compute the poles and their characteristics
try
   r = pole(sys,varargin{:});
catch E
   % Recast message from DAMP perspective
   if strcmp(E.identifier,'Control:general:NotSupportedModelsofClass')
      error(E.identifier,strrep(E.message,'pole','damp'))
   else
      throw(E)
   end
end
Ts = abs(sys.Ts);
[wn,z] = damp(r,Ts);

% Sort by increasing natural frequency
sr = size(r);

for k=1:prod(sr(3:end))
   [wn(:,k),perm] = sort(wn(:,k));
   r(:,k) = r(perm,k);
   z(:,k) = z(perm,k);
end

% Output 
if nargout
   wnout = wn;
elseif length(sr)>2
   error(message('Control:analysis:damp1'))
else
   ltipack.printdamp(r,wn,z,Ts,sys.TimeUnit)
end
