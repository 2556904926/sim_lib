function sysOut = full(sys)
%FULL  Converts sparse models to dense storage.
%
%  FSYS = FULL(SYS) converts the SPARSS or MECHSS model SYS to dense
%  state-space representation (see SS). For other model types, FULL 
%  leaves SYS unchanged.
%
%  Note: This operation is not recommended for large sparse models as
%  going to dense storage may saturate available memory and cause severe
%  performance degradation.
%
%  See also SPARSS, MECHSS, SS.

%   Copyright 2020 The MathWorks, Inc.
if issparse(sys)
   sysOut = full_(sys);
   sysOut = copyMetaData(sys,sysOut);
else
   sysOut = sys;
end