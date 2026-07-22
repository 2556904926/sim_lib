function [M,SingularFlag] = feedback(M1,M2,varargin)
%FEEDBACK  Feedback connection of two input/output systems. 
%
%   M = FEEDBACK(M1,M2) computes a closed-loop model M for the feedback loop: 
%
%          u --->O---->[ M1 ]----+---> y
%                |               |           y = M * u
%                +-----[ M2 ]<---+
%
%   Negative feedback is assumed and the model M maps u to y. To apply 
%   positive feedback, use the syntax M = FEEDBACK(M1,M2,+1).
%
%   M = FEEDBACK(M1,M2,FEEDIN,FEEDOUT,SIGN) builds the more general feedback 
%   interconnection:
%
%                      +------+
%          v --------->|      |--------> z
%                      |  M1  |
%          u --->O---->|      |----+---> y
%                |     +------+    |
%                |                 |
%                +-----[  M2  ]<---+
%
%   The vector FEEDIN contains indices into the input vector of M1 and
%   specifies which inputs u are involved in the feedback loop. Similarly, 
%   FEEDOUT specifies which outputs y of M1 are used for feedback. If SIGN=1 
%   then positive feedback is used. If SIGN=-1 or SIGN is omitted, then 
%   negative feedback is used. In all cases, the resulting model M has the 
%   same inputs and outputs as M1 (with their order preserved).
%
%   If M1 and M2 are arrays of models, FEEDBACK returns a model array M of 
%   the same dimensions where 
%      M(:,:,k) = FEEDBACK(M1(:,:,k),M2(:,:,k)) .
%
%   For dynamic systems SYS1 and SYS2, 
%      SYS = FEEDBACK(SYS1,SYS2,'name') 
%   connects SYS1 and SYS2 by matching their I/O names. The I/O names of 
%   SYS1 and SYS2 must be fully defined.
%
%   See also LFT, PARALLEL, SERIES, CONNECT, INPUTOUTPUTMODEL, DYNAMICSYSTEM.

%   P. Gahinet  6-26-96
%   Copyright 1986-2012 The MathWorks, Inc.
ni = nargin;
no = nargout;
narginchk(2,5);

try
   % Harmonize types
   if ~ltipack.hasMatchingType('feedback',M1,M2)
      [M1,M2] = ltipack.matchType('feedback',M1,M2);
   end      
      
   % Both operands are now of the same type
   % Detect 'name' keyword
   idxn = find(strncmpi(varargin,'name',4));
   NameMatching = ~isempty(idxn);
   if NameMatching
      varargin(:,idxn) = [];
      ni = ni-1;
   end
   
   % Parse input list
   switch ni
      case 2
         sign = -1;
      case 3
         sign = varargin{1};
      case 4
         sign = -1;
         indu = varargin{1};
         indy = varargin{2};
      case 5
         indu = varargin{1};
         indy = varargin{2};
         sign = varargin{3};
   end
   
   % Determine indexes for v/u and z/y
   sizes1 = iosize(M1);
   sizes2 = iosize(M2);
   if NameMatching
      % Name-based matching
      try
         [InputName1,OutputName1] = getIOName(M1);
         [InputName2,OutputName2] = getIOName(M2);
      catch ME
         error(message('Control:lftmodel:nameIC','feedback'))
      end
      [indy,indu2] = InputOutputModel.matchChannelNames(OutputName1,InputName2);
      [indy2,indu] = InputOutputModel.matchChannelNames(OutputName2,InputName1);
      if length(indu2)<sizes2(2) || length(indy2)<sizes2(1)
         error(message('Control:combination:feedback1'))
      end
      % Sort index vectors so that indu2=1:nu2 and indy2=1:ny2
      [~,is] = sort(indu2);  indy = indy(is);
      [~,is] = sort(indy2);  indu = indu(is);
   elseif ni<4
      indu = 1:sizes1(2);
      indy = 1:sizes1(1);
   elseif ~isvector(indu) || ~isvector(indy)
      error(message('Control:combination:feedback2'))
   elseif any(indu<1 | indu>sizes1(2))
      error(message('Control:combination:feedback3'))
   elseif any(indy<1 | indy>sizes1(1))
      error(message('Control:combination:feedback4'))
   end
   
   % I/O size compatibility
   if length(indu)~=sizes2(1) || length(indy)~=sizes2(2)
      if ni<4
         error(message('Control:combination:feedback5'))
      elseif length(indu)~=sizes2(1)
         error(message('Control:combination:feedback6'))
      else
         error(message('Control:combination:feedback7'))
      end
   end
   
   % Check sign
   if ~(isequal(sign,1) || isequal(sign,-1))
      error(message('Control:combination:feedback9'))
   else
      sign = double(sign);
   end
   
   % Combine data and metadata
   [M,SingularFlag] = feedback_(M1,M2,indu,indy,sign);
   M = feedbackMetaData(M,M1,M2);
   % Consistency checks (e.g., consistent block definition in LFT arrays)
   checkModelArray_(M)
   % Diagnostics
   if no<2 && SingularFlag
      warning(message('Control:combination:SingularAlgebraicLoop'))
   end
catch ME
   throw(ME)
end
   
