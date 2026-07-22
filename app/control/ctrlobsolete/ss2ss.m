function [at,bt,ct,dt] = ss2ss(a,b,c,d,t)
%SS2SS  State coordinate transformation for state-space models.
%
%   SYS = SS2SS(SYS,T) performs the similarity transformation z = Tx on the
%   state vector x of the state-space model SYS. The resulting state-space 
%   model is
%
%               .       -1        
%               z = [TAT  ] z + [TB] u
%                       -1
%               y = [CT   ] z + D u 
%
%   for explicit models and
%
%           -1  .      -1        
%        [ET  ] z = [AT  ] z + B u
%                      -1
%               y = [CT  ] z + D u  .
%
%   for descriptor models.
%
%   SS2SS is applicable to both continuous- and discrete-time models. For 
%   arrays of state-space models, the transformation T is applied to each 
%   individual model in the array. For GENSS and USS models, T is applied
%   to the state vector of the interconnection model (first output argument 
%   of GETLFTMODEL).
%
%   See also SSEQUIV, BALREAL, MODALREAL, SS, SPARSS, GENSS, GETLFTMODEL.

% Old help 
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%SS2SS Similarity transform.
%	[At,Bt,Ct,Dt] = SS2SS(A,B,C,D,T) performs the similarity 
%	transform z = Tx.  The resulting state space system is:
%
%		.       -1        
%		z = [TAT  ] z + [TB] u
%		       -1
%		y = [CT   ] z + Du
%
%	See also: CANON,BALREAL and BALANCE.

%	Clay M. Thompson  7-3-90
%   Copyright 1986-2010 The MathWorks, Inc.
if nargin>0 && ~isnumeric(a)
   ctrlMsgUtils.error('Control:general:NotSupportedModelsofClass','ss2ss',class(a))
end
narginchk(5,5);
error(abcdchk(a,b,c,d));

at = t*a/t; bt = t*b; ct = c/t; dt = d;
