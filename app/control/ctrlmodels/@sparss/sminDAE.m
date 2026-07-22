function sys = sminDAE(sys,MAXFILL)
%SMINDAE  Reduce DAE while preserving sparsity.
%
%   RSYS = SMINDAE(SYS) finds the subset of algebraic states that can be
%   eliminated without destroying sparsity. The sparsity of the dynamic 
%   portion of (A,E) or (M,C,K) is unchanged and fill-in in the remaining
%   matrices is kept in check. RSYS is an equivalent reduced model with 
%   fewer algebraic states.
% 
%   RSYS = SMINDAE(SYS,FILLFACTOR) specifies the acceptable amount of 
%   fill-in. By default, FILLFACTOR=0.25 (25% additional nonzero entries).
%   Increasing FILLFACTOR trades fewer states for less sparsity.
%
%   See also SMINREAL, SPARSS, MECHSS.

%   Copyright 2020 The MathWorks, Inc.
arguments
   sys
   MAXFILL = 0.25;
end
Data = sys.Data_;
for ct=1:numel(Data)
   Data(ct) = sminDAE(Data(ct),MAXFILL);
end
sys.Data_ = Data;