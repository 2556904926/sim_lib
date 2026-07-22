function sys = exp(sys)
%EXP  Create pure continuous-time delay.
%
%   The transfer function of a pure delay TAU (in seconds) is 
%      d(s) = exp(-tau*s)
%   You can specify this transfer function using EXP:
%      s = zpk('s')
%      d = exp(-tau*s)
%   If TAU is expressed in other time units than seconds, set the TimeUnit 
%   property accordingly:
%      d.TimeUnit = 'min'   % for tau expressed in minutes
%
%   More generally, given a 2D array M,
%      s = zpk('s')
%      D = exp(-M*s)
%   creates an array D of pure delays where 
%      D(i,j) = exp(-M(i,j)*s) .
%   All entries of M should be non negative for causality.
%
%   See also TF, ZPK.

%   Author(s):  P. Gahinet
%   Copyright 1986-2009 The MathWorks, Inc.
if ~isct(sys)
    ctrlMsgUtils.error('Control:transformation:exp4')
end
D = sys.Data_;
try
   for ct=1:numel(D)
      D(ct) = exp(D(ct));
   end
catch E
   throw(E)
end
sys.Data_ = D;
