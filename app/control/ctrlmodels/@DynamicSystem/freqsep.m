function [G1,G2,varargout] = freqsep(G,fRange,opt,optArgs)
%FREQSEP  Slow-fast decomposition.
%
%   [G1,G2] = FREQSEP(G,FCUT) decomposes the LTI system G into
%      G = G1 + G2
%   where G1 contains all modes with natural frequency wn<=FCUT and G2
%   contains the remaining modes.
%
%   [G1,G2] = FREQSEP(G,[FMIN,FMAX]) computes the decomposition G=G1+G2 
%   where G1 contains all modes with natural frequency FMIN<=wn<=FMAX 
%   and G2 contains the remaining modes.
%
%   [G1,G2] = FREQSEP(G,...,Name1=Value1,Name2=Value2,...) specifies 
%   additional options for controlling accuracy, see FREQSEPOPTIONS for 
%   details.
%
%   [G1,G2,INFO] = FREQSEP(G,...) returns an INFO structure containing
%   the block diagonalizing state transformation TL and TR (the state
%   matrices A,A1,A2 of G,G1,G2 are related by TL*A*TR = [A1 0;0 A2]).
%
%   Example:
%      % Three poles near s=-2
%      G = zpk(-.5,[-1.9999 -2+1e-4i -2-1e-4i],10);
%      % Force split for FCUT=2 (with some loss of accuracy)
%      [G1,G2] = freqsep(G,2,SepTol=1e9)
%
%   See also FREQSEPOPTIONS, DAMP, STABSEP, MODALSEP, LTI.

%	 Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   G
   fRange {mustBeNonnegative,mustBeFinite}; 
   opt = [];  % obsolete, option object
   optArgs.?ltioptions.freqsep;
end

% Validate range
if isscalar(fRange)
   % FREQSEP(SYS,FCUT)
   if fRange>0
      fRange = [0 fRange];
   else
      error(message('Control:transformation:freqsep1'))
   end
elseif ~(numel(fRange)==2 && fRange(1)<fRange(2))
   error(message('Control:transformation:freqsep3'))
end

% Collect options
try
   if isempty(opt)
      opt = initOptions(ltioptions.freqsep,namedargs2cell(optArgs));
   elseif ~isa(opt,'ltioptions.freqsep')
      error(message('Control:general:InvalidNameValue'))
   end
catch ME
   throw(ME)
end

try
   [G1,G2,varargout{1:nargout-2}] = freqsep_(G,fRange,opt);
catch E
   ltipack.throw(E,'command','freqsep',class(G))
end

% Clear notes, userdata, etc
G1.Name = '';  G1.Notes = {};  G1.UserData = [];
G2.Name = '';  G2.Notes = {};  G2.UserData = [];
