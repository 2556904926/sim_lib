function [Kp,Ki,Kd,Tf,b,c,Ts] = piddata2(sys,varargin)
%PIDDATA2  Quick access to 2-DOF PID parameters.
%
%   [Kp,Ki,Kd,Tf,b,c] = PIDDATA2(SYS) returns the Kp, Ki, Kd, Tf, b, c
%   parameters of a 2-DOF PID controller in parallel form represented by
%   the two-input-one-output dynamic system SYS. If SYS is a PID2 object,
%   Kp, Ki, Kd, Tf, b, c are the corresponding properties of SYS. If SYS is
%   not a PID2 object, Kp, Ki, Kd, Tf, b, c are the parameters of a 2-DOF
%   PID controller equivalent to SYS. In that case SYS must represent a
%   valid 2-DOF PID controller.
%
%   [Kp,Ki,Kd,Tf,b,c,Ts] = PIDDATA2(SYS) also returns the sample time Ts.
%   Other properties of SYS can be accessed with GET or by direct
%   structure-like referencing (e.g. SYS.InputName).
%
%   When SYS is an array of dynamic systems, Kp, Ki, Kd, Tf, b, c are
%   arrays of the same size as SYS where Kp(m), Ki(m), Kd(m), Tf(m), b(m)
%   and c(m) give the 2-DOF PID parameters of SYS(:,:,m).
%
%   [Kp,Ki,Kd,Tf,b,c,Ts] = PIDDATA2(SYS,J1,...,JN) extracts the data for
%   the (J1,...,JN) entry in the array of dynamic systems SYS where
%   J1,...,JN are indices in N dimensions.
%
%   See also PIDSTDDATA2, PIDDATA, PIDSTDDATA.

% Author(s): B Singh Mar-2015 Copyright 2015 The MathWorks, Inc.
s = size(sys);
nd = length(s);
try
    if isempty(varargin) && nd>2
        % multiple models
        ArraySize = s(3:end);
        Kp = zeros(ArraySize);
        Ki = zeros(ArraySize);
        Kd = zeros(ArraySize);
        Tf = zeros(ArraySize);
        b = zeros(ArraySize);
        c = zeros(ArraySize);
        Ts = 0;
        for ct=1:numel(Kp)
            [Kp(ct),Ki(ct),Kd(ct),Tf(ct),b(ct),c(ct),Ts] = piddata2_(sys,ct);
        end
    else
        % single model
        [Kp,Ki,Kd,Tf,b,c,Ts] = piddata2_(sys,varargin{:});
    end
catch ME
    ltipack.throw(ME,'command','piddata2',class(sys))
end
