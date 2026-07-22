function S = getSensitivity(CL,LocID,Openings,Models)
%getSensitivity  Computes sensitivity function.
%
%   getSensitivity computes the sensitivity function of feedback loops
%   given a generalized model of the overall control system (for example,
%   in the context of tuning the control system parameters with SYSTUNE).
%   The sensitivity function at a location v is the closed-loop transfer
%   function from dv to v+dv in the diagram below. It measures how the
%   control system rejects a disturbance dv entering at v.
%
%           dv --->+         +--> v+dv
%                  |         |
%            v --->O---------+------>
%                  +
%
%   S = getSensitivity(CL,LOC) computes the sensitivity function S measured
%   at the location LOC. CL is a generalized model of the closed-loop
%   system and the string LOC refers to one of the locations marked by
%   analysis points (see AnalysisPoint and use getPoints(CL) to get the list
%   of such locations). Use a cell array of strings LOC to specify multiple
%   locations and compute MIMO sensitivity functions.
%
%   S = getSensitivity(CL,LOC,OPENINGS) further specifies which feedback
%   loops to open when evaluating the sensitivity function S. For example,
%   you can ask for the sensitivity of the inner loop when the outer loop
%   is open in a cascaded loop configuration. The string or cell array of
%   strings OPENINGS must contain a subset of the loop opening locations
%   marked by analysis points (use getPoints(T) to get a list of such
%   locations). If LOC and OPENINGS list the same locations, the loops are
%   open after the output v+dv in the diagram above.
%
%   The output S is a generalized GENSS/GENFRD model of the sensitivity
%   function. Use SS/FRD or GETVALUE to get its current/nominal value.
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
%   Compute the sensitivity function S = 1/(1+CG) at the location "x":
%        S = getSensitivity(CL,'x')
%
%   See also AnalysisPoint, getPoints, getCompSensitivity, getLoopTransfer,
%   getIOTransfer, genss, genfrd, getValue, slTuner/getSensitivity, systune.

%   Author(s): P. Gahinet
%   Copyright 2009-2014 The MathWorks, Inc.
narginchk(2,4)
ni = nargin;
if ni<3 || isempty(Openings)
   Openings = cell(0,1);
end
if ni<4
   Models = NaN;   % all models
end
try
   % Compute open-loop transfer at specified locations
   [L,iX] = getLoopTransfer(CL,LocID,+1,Openings,Models);
catch ME
   throw(ME)
end
% Note: S is the transfer function from In to Out in
% 
%     In ---+   +---> Out
%           |   |
%      +--->o---+--->[ X ]----+
%      |                      |
%      +-------[ L ]----------+
%
% where X keeps track of sensitivity points that are also permanent openings.
nL = size(L,1);
if isempty(iX)
   S = feedback(eye(nL),L,+1);
else
   % LOC and OPENINGS overlap. Interpretation is as shown above
   X = ones(nL,1);
   X(iX) = 0;
   S = feedback(eye(nL),L*diag(X),+1);
end
% Pass on location names
LocNames = L.InputName;
S.InputName = LocNames;
S.OutputName = LocNames;