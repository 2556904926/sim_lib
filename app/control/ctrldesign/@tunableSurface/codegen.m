function Code = codegen(GS)
% Code generation for tunable gain surfaces.
%
%   CODE = CODEGEN(GS) generates Embedded MATLAB code for the tunable 
%   surface GS. The generated function 
%      G = fcn(x1,x2,...,xN)
%   computes the gain G as a function of the scheduling variables
%   x1,x2,...,xN. This function takes scalar values of x1,x2,...,xN
%   and returns a scalar- or matrix-valued gain depending on GS.
%
%   Note: The value G matches evalSurf(GS,x1,x2,...,xN) up to rounding
%   errors.
%
%   See also tunableSurface, evalSurf.

%   Copyright 1986-2017 The MathWorks, Inc.
ios = iosize(GS);
if all(ios==1)
   Code = genScalarCode(GS);
else
   Code = genMatrixCode(GS);
end