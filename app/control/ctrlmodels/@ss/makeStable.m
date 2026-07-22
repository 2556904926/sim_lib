function sys = makeStable(sys)
%MAKESTABLE  Reflects unstable modes.
%
%   SYS2 = MAKESTABLE(SYS) returns the stable model SYS2 obtained by 
%   reflecting the unstable modes of SYS about the stability boundary.
%
%   See also POLE, ISSTABLE, MODALSEP.

%   Copyright 2024
sys = makeStable_(sys);