function sys = xsort(sys)
%XSORT  Sort states based on state partition.
%
%   Signal-based connections and physical couplings between model
%   components gives rise to DAE models where internal signals and
%   forces become extra states. The StateInfo property of SPARSS and
%   MECHSS keeps track of the state partition into sub-components,
%   interface variables, and signal variables.
%
%   XSYS = XSORT(SYS) sorts the x or q vector based on this state
%   partition. The input SYS is a SPARSS or MECHSS model. In the sorted
%   XSYS, all components appear first, followed by the interfaces,
%   followed by a single group of all internal signals. The matrices
%   s*E-A and M*s^2+C*s+K have the block arrow structure
%
%          X       X
%            X     X
%              X   X
%                X X
%          X X X X X
%
%   where each diagonal block is a sub-component of SYS, and the last
%   row and column combine the Interface and Signal groups to capture
%   all couplings and connections between components.
%
%   See also SHOWSTATEINFO, MECHSS, SPARSS.

%   Copyright 2020 The MathWorks, Inc.
Data = sys.Data_;
for ct=1:numel(Data)
   Data(ct) = xsort(Data(ct));
end
sys.Data_ = Data;