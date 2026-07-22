function [a,b,c,d,e,Ts] = sparssdata(sys,varargin)
%SPARSSDATA  Quick access to sparse state-space data.
%
%   [A,B,C,D,E] = SPARSSDATA(SYS) returns the A,B,C,D,E matrices of the 
%   sparse state-space (SPARSS) model SYS.  If SYS is not a SPARSS model, 
%   it is first converted to SPARSS. If SYS has internal delays, A,B,C,D,E 
%   are obtained by first setting all internal delays to zero (delay-free 
%   dynamics).
%
%   [A,B,C,D,E,TS] = SPARSSDATA(SYS) also returns the sample time TS. Other 
%   properties of SYS can be accessed using struct-like dot syntax (for
%   example, SYS.StateInfo).
%
%   [A,B,C,D,E,TS] = SPARSSDATA(SYS,J1,...,JN) extracts the data for the 
%   (J1,...,JN) entry in the model array SYS.
%
%   See also SPARSS, SSDATA.

%   Copyright 2020 The MathWorks, Inc.
ni = nargin-1;
if ni==0 && nmodels(sys)>1
   error(message('Control:ltiobject:sparssdata1'))
end

% Get data
try
   if ni==0
      [a,b,c,d,e,Ts] = sparssdata_(sys,1);
   else
      [a,b,c,d,e,Ts] = sparssdata_(sys,varargin{:});
   end
catch ME
   ltipack.throw(ME,'command','sparssdata',class(sys))
end
