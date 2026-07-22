function [G1,G2,varargout] = stabsep(G,Offset,old3,old4,optArgs)
%STABSEP  Stable/unstable decomposition.
%
%   [G1,G2] = STABSEP(G) decomposes the LTI system G into its stable and
%   unstable parts:
%      G = G1 + G2
%   G1 contains all stable modes (poles) that can be separated from unstable
%   modes in a numerically stable way, and G2 contains the remaining modes.
%   G1 is always proper.
%
%   [G1,G2] = STABSEP(G,OFFSET) shifts the stability boundary so that G1
%   includes all modes satisfying:
%       Continuous time:  Re(s) < -OFFSET * max(1,|Im(s)|)
%       Discrete time:      |z| < 1 - OFFSET
%   The default is OFFSET=0. Increase this value to exclude modes close to
%   the stability boundary from G1.
%
%   [G1,G2] = STABSEP(G,...,Name1=Value1,Name2=Value2,...) specifies
%   additional options for controlling accuracy or focusing on unstable
%   modes (see stabsepOptions for details).
%
%   [G1,G2,INFO] = STABSEP(G,...) returns an INFO structure containing
%   the block diagonalizing state transformation TL and TR (the state
%   matrices A,A1,A2 of G,G1,G2 are related by TL*A*TR = [A2 0;0 A1]).
%
%   Example: Compute stable/unstable decomposition with offset 0.1 and 
%   a maximum loss of accuracy of two digits:
%      h = zpk(1,[-2 -1 1 -0.001],0.1)
%      [hs,hns] = stabsep(h,0.1,SepTol=100)
%
%   See also STABSEPOPTIONS, FREQSEP, MODALSEP, LTI.

%   Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc.
arguments
   G
   Offset = 0; 
   old3 = [];  % obsolete
   old4 = [];  % obsolete
   optArgs.?ltioptions.stabsep;
end

% Resolve OFFSET and options and support obsolete syntax
try
   if isa(Offset,'ltioptions.StableUnstableSplit')
      % Pre-R2023b: stabsep(G,stabsepOptions(...))
      opt = Offset;
   else
      opt = ltioptions.stabsep;
      if isnumeric(Offset) && isnumeric(old3) && isnumeric(old4)
         if isempty(old3) && isempty(old4)
            opt.Offset = Offset;
         else
            % Pre-R14sp2 syntax: stabsep(G,condmax,mode,offset)
            % Note: CONDMAX mapped to RelTol which is now ignored.
            if ~isempty(old3)
               opt.Mode = old3;
            end
            if ~isempty(old4)
               opt.Offset = old4;
            end
         end
      else
         error(message('Control:general:InvalidNameValue'))
      end
   end
   % Apply Name/Value pairs
   opt = initOptions(opt,namedargs2cell(optArgs));
catch ME
   throw(ME)
end

% Perform split
try
   [G1,G2,varargout{1:nargout-2}] = stabsep_(G,opt);
catch E
   ltipack.throw(E,'command','stabsep',class(G))
end

% Clear notes, userdata, etc
G1.Name = '';  G1.Notes = {};  G1.UserData = [];
G2.Name = '';  G2.Notes = {};  G2.UserData = [];
