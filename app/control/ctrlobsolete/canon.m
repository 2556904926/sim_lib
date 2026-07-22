function [ab,bb,cb,db,T] = canon(a,b,c,d,varargin)
%CANON  Canonical state-space realizations.
%
%   CSYS = CANON(SYS,'companion') computes the companion form where the 
%   characteristic polynomial appears in the rightmost column of A. This
%   form involves an ill-conditioned state transformation and should be 
%   avoided when possible.
%
%   CSYS = CANON(SYS,'modal') is not recommended. Use MODALREAL or MODALSEP
%   instead to compute modal forms and decompositions. 
%
%   [CSYS,T] = CANON(SYS,...) also returns the state transformation 
%   matrix T relating the canonical state vector z to the original state 
%   vector x by z = Tx. This syntax is only meaningful when SYS is a 
%   state-space model.
%
%   See also MODALREAL, MODALSEP, SS, POLE, SS2SS, CTRB, CTRBF.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%CANON  State-space to canonical form transformation.
%   [Ab,Bb,Cb,Db] = CANON(A,B,C,D,'type') transforms the continuous 
%   state-space system (A,B,C,D) into the canonical form specified by
%   `type': 'modal' transforms the state-space system into modal form 
%                   where the system eigenvalues appear on the 
%                   diagonal.  The system must be diagonalizable.
%
%       'companion' transforms the state-space system into 
%                   companion canonical form where the characteristic
%                   polynomial appears in the right column.
%
%   With an additional left hand argument, the transformation matrix,
%   T, is returned where z = Tx:
%       [Ab,Bb,Cb,Db,T] = CANON(A,B,C,D,'type')
%
%   The modal form is useful for determining the relative controll-
%   ability of the system modes.  Note: the companion form is ill-
%   conditioned and should be avoided if possible.
%
%   See also: SS2SS, CTRB, and CTRBF.

%   Clay M. Thompson  7-3-90
%   Copyright 1986-2005 The MathWorks, Inc.

narginchk(4,5);
[sys,T] = canon(ss(a,b,c,d),varargin{:});
[ab,bb,cb,db] = ssdata(sys);

% end canon
