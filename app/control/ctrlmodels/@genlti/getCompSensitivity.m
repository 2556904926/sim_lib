function T = getCompSensitivity(CL,varargin)
%getCompSensitivity  Computes complementary sensitivity function.
%
%   getCompSensitivity computes the complementary sensitivity function
%   given a generalized model of the overall control system (for example,
%   in the context of tuning the control system parameters with SYSTUNE).
%   The complementary sensitivity T at a location v is the closed-loop
%   transfer from dv to v in the diagram below.
%
%            ... --------------+------> v
%                              |
%                              |
%            ... <------------>O<----- dv
%                   v+dv        +
%
%   It measures return effects in feedback loops and is related to the
%   sensitivity S at the same location (see getSensitivity) by S-T = I.
%
%   T = getCompSensitivity(CL,LOC) computes the complementary sensitivity
%   function T measured at the location LOC. CL is a generalized model of
%   the closed-loop system and the string LOC refers to one of the locations
%   marked by analysis points (see AnalysisPoint and use getPoints(CL) to
%   get the list of such locations). Use a cell array of strings LOC to
%   specify multiple locations and compute MIMO complementary sensitivity
%   functions.
%
%   T = getCompSensitivity(CL,LOC,OPENINGS) further specifies which feedback
%   loops to open when evaluating the complementary sensitivity function T.
%   The string or cell array of strings OPENINGS must contain a subset of
%   the loop opening locations marked by analysis points (use getPoints(T)
%   to get a list of such locations). If LOC and OPENINGS list the same
%   locations, the loops are open after the input dv in the diagram above.
%
%   The output T is a generalized GENSS/GENFRD model of the complementary
%   sensitivity function. Use SS/FRD or GETVALUE to get its current/nominal
%   value.
%
%   Example: Build a closed-loop model CL of the following SISO loop with a
%   tunable PI controller C:
%
%              r --->O--->[ C ]--[x]-->[ G ]---+---> y
%                  - |                         |
%                    +-------------------------+
%
%        G = tf([1 2],[1 0.2 10])
%        C = tunablePID('C','pi')
%        X = AnalysisPoint('x')  % loop opening location
%        CL = feedback(G*X*C,1)
%   Compute the complementary sensitivity function T = -CG/(1+CG) at the
%   location "x":
%        T = getCompSensitivity(CL,'x')
%
%   See also AnalysisPoint, getPoints, getSensitivity, getLoopTransfer,
%   getIOTransfer, genss, genfrd, getValue, slTuner/getCompSensitivity,
%   systune.

%   Author(s): P. Gahinet
%   Copyright 2009-2014 The MathWorks, Inc.
narginchk(2,4)
try
   S = getSensitivity(CL,varargin{:});
catch ME
   throw(ME)
end
T = S - eye(size(S,1));