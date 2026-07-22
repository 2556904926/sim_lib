function showStateInfo(sys)
%SHOWSTATEINFO  State vector map.
%
%   For SPARSS models, SHOWSTATEINFO(SYS) maps the content of the state
%   vector x back to individual components and internal signals. Here
%   "component" refers to the sub-components or sub-structures that were
%   combined into SYS. The "Signal" group includes all signals flowing
%   between components, e.g., in series or feedback connections.
%
%   For MECHSS models, SHOWSTATEINFO(SYS) maps the content of the vector q
%   of generalized degrees of freedom in terms of components, interfaces,
%   and signals. The meaning of "component" and "signal" is the same and
%   the "Interface" group includes all DAE variables arising from physical
%   couplings between components (see INTERFACE).
%
%   See also XSORT, SERIES, FEEDBACK, mechss/interface, MECHSS, SPARSS.

%   Copyright 2020 The MathWorks, Inc.
if nmodels(sys)>1
   error(message('Control:ltiobject:showStateInfo1'))
end
S = sys.StateInfo;
ltipack.util.showStateInfo(S)
