function [m,c,k,b,f,g,d,Ts] = mechssdata(sys,varargin)
%MECHSSDATA  Quick access to second-order model data.
%
%   [M,C,K,B,F,G,D] = MECHSSDATA(SYS) returns the matrices of the
%   second-order model SYS (see MECHSS). If SYS is not a MECHSS model,
%   it is first converted to MECHSS. If SYS has internal delays, the
%   matrices are obtained by first setting all internal delays to zero
%   (delay-free dynamics).
%
%   [M,C,K,B,F,G,D,TS] = MECHSSDATA(SYS) also returns the sample time TS.
%
%   [M,C,K,B,F,G,D,TS] = MECHSSDATA(SYS,J1,...,JN) extracts the data for
%   the (J1,...,JN) entry in the model array SYS.
%
%   See also SPARSS.

%   Copyright 2020 The MathWorks, Inc.
ni = nargin-1;
if ni==0 && nmodels(sys)>1
   error(message('Control:ltiobject:sparssdata1'))
end

% Get data
try
   if ni==0
      [m,c,k,b,f,g,d,Ts] = mechssdata_(sys,1);
   else
      [m,c,k,b,f,g,d,Ts] = mechssdata_(sys,varargin{:});
   end
catch ME
   ltipack.throw(ME,'command','mechssdata',class(sys))
end
