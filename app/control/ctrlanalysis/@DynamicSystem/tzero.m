function [z,nrk] = tzero(sys,varargin)
%TZERO  Invariant zeros of linear systems.
%
%   Z = TZERO(SYS) computes the invariant zeros of the dynamic system SYS.
%   For state-space models with matrices A,B,C,D,E, the invariant zeros
%   are the complex values s for which the rank of the matrix
%
%             [ A - s E   B]
%             [    C      D]
%
%   drops below its normal value. For minimal realizations, this coincides
%   with the transmission zeros of SYS (values of s for which its transfer
%   function drops rank).
%
%   Z = TZERO(SYS,TOL) specifies the relative tolerance TOL controlling
%   rank decisions. Increasing TOL helps detect non-minimal modes and
%   eliminate zeros near infinity but may artificially increase the number
%   of transmission zeros. The default tolerance is EPS^(3/4).
%
%   Z = TZERO(A,B,C,D,E,TOL) computes the invariant zeros directly from the
%   state-space matrices A,B,C,D,E. When omitted or set to [], E defaults
%   to the identity matrix. The default tolerance TOL is EPS^(3/4). No 
%   scaling of A,B,C,E is performed when using this syntax.
%
%   [Z,NRK] = TZERO(...) also returns the normal rank of the transfer
%   function D + C * inv(s*E-A) * B. The matrix s*E-A should be invertible
%   for almost all s.
%
%   Note: When C and D are empty or zero, TZERO computes the uncontrollable
%   modes of (A-s*E,B). Similarly, TZERO computes the unobservable modes of
%   (C,A-s*E) when B and D are empty or zero.
%
%   See also ZERO, PZMAP, POLE, LTI, DYNAMICSYSTEM.

%   Copyright 1986-2012 The MathWorks, Inc.
if nmodels(sys)~=1
   error(message('Control:foundation:tzero4'))
end
try
   [z,nrk] = tzero_(sys,varargin{:});
catch ME
   ltipack.throw(ME,'command','tzero',class(sys))
end
