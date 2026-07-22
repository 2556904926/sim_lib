function Locs = getPoints(sys)
%GETPOINTS  Get analysis point locations.
%
%   When building a model of your control system, you can use AnalysisPoint
%   blocks to mark points of interest for open-loop analysis, disturbance
%   injection, signal measurement, etc. Use getPoints to query the list of
%   available analysis points.
%
%   POINTS = getPoints(T) returns the locations of the analysis points in 
%   the generalized model T (see GENLTI). These locations are obtained by 
%   concatenating the "Location" properties of all AnalysisPoint blocks in T.
%   You can refer to these locations by name to create tuning goals (see 
%   TuningGoal) or compute open- and closed-loop transfer functions using 
%   getLoopTransfer and getIOTransfer.
%
%   Example: Build a closed-loop model T of the cascaded feedback loops
%   below where C1,C2 are tunable compensators and X1,X2 are two analysis
%   points:
%
%       r -->O-->[C1]-->O--->[C2]-->[G2]---+--[G1]--+--> y
%          - |        - |                  |        |
%            |          +--------[X2]------+        |
%            +---------------[X1]-------------------+
%
%        G1 = tf(10,[1 10]);
%        G2 = tf([1 2],[1 0.2 10])
%        C1 = tunablePID('C','pi')
%        C2 = tunableGain('G',1)
%        X1 = AnalysisPoint('X1')
%        X2 = AnalysisPoint('X2')
%        T = feedback(G1*feedback(G2*C2,X2)*C1,X1)
%
%   For this model, getPoints(T) returns the two locations {'X1';'X2'}. You
%   can refer to these locations by name to compute the open-loop response
%   of the inner loop at X2 with the outer loop open at X1:
%        L = getLoopTransfer(T,'X2',-1,'X1')
%        bode(L)
%
%   See also AnalysisPoint, genlti, slTuner/getPoints, getLoopTransfer,
%   getIOTransfer, TuningGoal, systune.

%   Copyright 1986-2014 The MathWorks, Inc.
BV = struct2cell(sys.Blocks);
LS = BV(cellfun(@(x) isa(x,'AnalysisPoint'),BV),:);
for ct=1:numel(LS)
   LS{ct} = LS{ct}.Location;
end
Locs = cat(1,cell(0,1),LS{:});

