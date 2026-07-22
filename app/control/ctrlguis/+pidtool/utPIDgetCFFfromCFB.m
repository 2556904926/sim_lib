function [Cff, r2y, r2u] = utPIDgetCFFfromCFB(G,Cfb,P,I,D,N,b,c,Ts,CtrlStruct)
% UTPIDGETCFFFROMCFB  computes feed-forward term of the 2DOF PID controller
% from the feedback term and b and c parameters.
%
 
% Author(s): Rong Chen 21-Sep-2010
% Copyright 2010 The MathWorks, Inc.

if ~isfinite(G)
    r2y = tf(nan);
    r2u = tf(nan);
    Cff = tf(nan);
    return
end

% Set N to inf if controller type is "pid" (g1522700, revisit)
if strcmpi(CtrlStruct.Controller,'pid')
    N = inf;
end

% Compute Cff where r*Cff - y*Cfb = u
[~,~,Cff] = utPID1dof_getCfreeCfixedfromPIDN(P*b,I,D*c,N,Ts,CtrlStruct);
Cff.TimeUnit = Cfb.TimeUnit;
Cff.InputName = 'r';  
Cff.OutputName = 'uff';
% Closed loop
Cfb.InputName = 'y';
Sum = sumblk('u','uff','ufb','+-');
r2y = connect(G,Cfb,Cff,Sum,'r','y');
r2u = connect(G,Cfb,Cff,Sum,'r','u');
