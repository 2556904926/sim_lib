function sysOut = ss(varargin)
%SS  State-space models.
%
%  Construction:
%    SYS = SS(A,B,C,D) creates an object SYS representing the continuous-
%    time state-space model
%         dx/dt = Ax(t) + Bu(t)
%          y(t) = Cx(t) + Du(t)
%    You can set D=0 to mean the zero matrix of appropriate size. SYS is
%    of type SS when A,B,C,D are dense numeric arrays, of type GENSS when
%    A,B,C,D depend on tunable parameters (see REALP and GENMAT), and
%    of type USS when A,B,C,D are uncertain matrices (requires Robust
%    Control Toolbox). Use SPARSS when A,B,C,D are sparse matrices.
%
%    SYS = SS(A,B,C,D,Ts) creates a discrete-time state-space model with
%    sample time Ts (set Ts=-1 if the sample time is undetermined).
%
%    SYS = SS(D) specifies a static gain matrix D.
%
%    You can set additional model properties by using name/value pairs.
%    For example,
%       sys = ss(-1,2,1,0,'InputDelay',0.7,'StateName','position')
%    also sets the input delay and the state name. Type "properties(ss)"
%    for a complete list of model properties, and type
%       help ss.<PropertyName>
%    for help on a particular property. For example, "help ss.StateName"
%    provides information about the "StateName" property.
%
%  Arrays of state-space models:
%    You can create arrays of state-space models by using ND arrays for
%    A,B,C,D. The first two dimensions of A,B,C,D define the number of
%    states, inputs, and outputs, while the remaining dimensions specify
%    the array sizes. For example,
%       sys = ss(rand(2,2,3,4),[2;1],[1 1],0)
%    creates a 3x4 array of SISO state-space models. You can also use
%    indexed assignment and STACK to build SS arrays:
%       sys = ss(zeros(1,1,2))     % create 2x1 array of SISO models
%       sys(:,:,1) = rss(2)        % assign 1st model
%       sys(:,:,2) = ss(-1)        % assign 2nd model
%       sys = stack(1,sys,rss(5))  % add 3rd model to array
%
%  Conversion:
%    SYS = SS(SYS) converts any dynamic system SYS to the state-space
%    representation. The resulting model SYS is always of class SS.
%
%    SYS = SS(SYS,'min') computes a minimal realization of SYS.
%
%    SYS = SS(SYS,'explicit') computes an explicit realization (E=I) of SYS.
%    An error is thrown if SYS is improper.
%
%    See also DSS, DELAYSS, RSS, DRSS, SPARSS, MECHSS, SSDATA, TF, ZPK, FRD, GENSS, USS, DYNAMICSYSTEM.

%   Author(s): P. Gahinet, 5-1-96
%   Copyright 1986-2011 The MathWorks, Inc.
try
   ni = nargin;
   [ConstructFlag,InputList] = lti.isContructorCall('ss',varargin);
   if ConstructFlag
      % SS(a,b,c,d,SSSYS): Try again with system replaced by struct
      sysOut = ss(InputList{:});
   elseif ni>2 || (ni==2 && ~ischar(varargin{2}))
      % Invalid syntax
      error(message('Control:transformation:InvalidConversionSyntax','ss','ss'))
   else
      sys = InputList{1};
      if ni==1
         sysOut = ss_(sys);
      else
         optflag = ltipack.matchKey(InputList{2},{'minimal','explicit'});
         if isempty(optflag)
            error(message('Control:transformation:ss3'))
         end
         sysOut = ss_(sys,optflag);
      end
      % Transfer metadata
      sysOut = copyMetaData(sys,sysOut);
   end
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:ss1',class(sys)))
   else
      throw(E)
   end
end
