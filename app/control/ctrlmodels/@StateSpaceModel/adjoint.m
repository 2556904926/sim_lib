function asys = adjoint(sys)
%ADJOINT  Forms adjoint model.
%
%   ASYS = ADJOINT(SYS) returns the adjoint ASYS of SYS. This is the model
%   with data (A',C',B',D',E') when (A,B,C,D,E) is the data of SYS.
%
%   See also SS, DSS, SPARSS, MECHSS.

%   Copyright 2024 The MathWorks, Inc.
try
   asys = adjoint_(sys);
   asys.IOSize_ = sys.IOSize_(:,[2 1]);
   asys.InputName_  = sys.OutputName_;
   asys.InputUnit_  = sys.OutputUnit_;
   asys.InputGroup_  = sys.OutputGroup_;
   asys.OutputName_  = sys.InputName_;
   asys.OutputUnit_  = sys.InputUnit_;
   asys.OutputGroup_  = sys.InputGroup_;
catch E
   ltipack.throw(E,'command','adjoint',class(sys))
end