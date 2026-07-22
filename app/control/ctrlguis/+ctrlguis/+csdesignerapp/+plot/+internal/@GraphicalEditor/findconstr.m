function Constraints = findconstr(Editor)
%

%FINDCONSTR   Finds all active design constraints objects attached to an Editor.

%   Copyright 1986-2023 The MathWorks, Inc. 

Constraints = plotconstr.findConstrOnAxis(Editor.Axes.getAxes);

