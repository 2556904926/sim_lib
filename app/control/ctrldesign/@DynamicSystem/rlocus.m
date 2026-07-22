function [rout,kout] = rlocus(varargin)
%RLOCUS  Evans root locus.
%
%   RLOCUS(SYS) computes and plots the root locus of the single-input,
%   single-output LTI model SYS. The root locus plot is used to analyze 
%   the negative feedback loop
%
%                     +-----+
%         ---->O----->| SYS |----+---->
%             -|      +-----+    |
%              |                 |
%              |       +---+     |
%              +-------| K |<----+
%                      +---+
%
%   and shows the trajectories of the closed-loop poles when the feedback 
%   gain K varies from 0 to Inf.  RLOCUS automatically generates a set of 
%   positive gain values that produce a smooth plot.  
%
%   RLOCUS(SYS,K) uses a user-specified vector K of gain values.
%
%   RLOCUS(SYS1,SYS2,...) draws the root loci of several models SYS1,SYS2,... 
%   on a single plot. You can specify a color, line style, and marker for 
%   each model, for example:
%      rlocus(sys1,'r',sys2,'y:',sys3,'gx').
%
%   [R,K] = RLOCUS(SYS) or R = RLOCUS(SYS,K) returns the matrix R of
%   complex root locations for the gains K.  R has LENGTH(K) columns
%   and its j-th column lists the closed-loop roots for the gain K(j).  
% 
%   See RLOCUSPLOT for additional graphical options for root locus plots.
%
%   See also RLOCUSPLOT, SISOTOOL, POLE, ISSISO, LTI.

%   Author(s): J.N. Little, A.C.W.Grace, P. Gahinet, A. DiVergilio
%   Copyright 1986-2010 The MathWorks, Inc.

% Handle various calling sequences
if nargout>0
   try
      % Parse input list
      [sysList,Extras] = DynamicSystem.parseRespFcnInputs(varargin);
      [sysList,GainVector] = DynamicSystem.checkRootLocusInputs(sysList,Extras);
      sys = sysList(1).System;
      if (numel(sysList)>1 || numsys(sys)~=1)
         error(message('Control:analysis:RequiresSingleModelWithOutputArgs','rlocus'))
      end
      % Compute locus
      [rout,kout] = rlocus_(sys,GainVector);
   catch E
      throw(E)
   end
   
else
   % Root locus plot
   ni = nargin;
   ArgNames = cell(ni,1);
   for ct=1:ni
      ArgNames(ct) = {inputname(ct)};
   end
   varargin = argname2sysname(varargin,ArgNames);
   try
      rlocusplot(varargin{:});
   catch E
      throw(E)
   end
end

