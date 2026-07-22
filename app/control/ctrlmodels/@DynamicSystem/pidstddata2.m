function [Kp,Ti,Td,N,b,c,Ts] = pidstddata2(sys,varargin)
%PIDSTDDATA2  Quick access to 2-DOF PID parameters.
%
%   [Kp,Ti,Td,N,b,c] = PIDSTDDATA2(SYS) returns the Kp, Ti, Td, N, b, c
%   parameters of a 2-DOF PID controller in standard form represented by
%   the two-input-one-output dynamic system SYS. If SYS is a PIDSTD2
%   object, Kp, Ti, Td, N, b, c are the corresponding properties of SYS. If
%   SYS is not a PIDSTD2 object, Kp,Ti,Td,N,b,c are the parameters of a
%   2-DOF PID controller equivalent to SYS. In that case SYS must represent
%   a valid 2-DOF PID controller.
%
%   [Kp,Ti,Td,N,b,c,Ts] = PIDSTDDATA2(SYS) also returns the sample time Ts.
%   Other properties of SYS can be accessed with GET or by direct
%   structure-like referencing (e.g. SYS.InputName).
%
%   When SYS is an array of dynamic systems, Kp,Ti,Td,N,b,c are arrays of
%   the same size as SYS where Kp(m), Ti(m), Td(m), N(m), b(m) and c(m)
%   give the 2-DOF PID parameters of SYS(:,:,m).
%
%   [Kp,Ti,Td,N,b,c,Ts] = PIDSTDDATA2(SYS,J1,...,JN) extracts the data for
%   the (J1,...,JN) entry in the array of dynamic systems SYS where
%   J1,...,JN are indices in N dimensions.
%
%   See also PIDDATA2, PIDSTDDATA, PIDDATA.

% Author(s): B. Singh Mar-2015 Copyright 2015 The MathWorks, Inc.
s = size(sys);
nd = length(s);
try
   if isempty(varargin) && nd>2
      % multiple models
      ArraySize = s(3:end);
      Kp = zeros(ArraySize);
      Ti = zeros(ArraySize);
      Td = zeros(ArraySize);
      N = zeros(ArraySize);
      Ts = 0;
      for ct=1:numel(Kp)
         [Kp(ct),Ti(ct),Td(ct),N(ct),b(ct),c(ct),Ts] = pidstddata2_(sys,ct);
      end
   else
      % single model
      [Kp,Ti,Td,N,b,c,Ts] = pidstddata2_(sys,varargin{:});
   end
catch ME
   ltipack.throw(ME,'command','pidstddata2',class(sys))
end
