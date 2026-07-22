function sysOut = mechss(varargin)
%MECHSS  Sparse mass-spring-damper model.
%
%  Construction:
%    SYS = MECHSS(M,C,K,B,F,G,D) creates an object SYS representing the
%    continuous-time second-order model
%       M q''(t) + C q'(t) + K q(t) = B u(t)
%                              y(t) = F q(t) + G q'(t) + D u
%    Such models are common in finite-element analysis of mechanical
%    systems, where q and q' are the vector of displacements and
%    velocities (the full state is x = [q;q']). The matrices M,C,K
%    specify mass, damping, and stiffness. You can set M=[] when the
%    mass matrix is identity, and set G,D to [] or omit them when G=0 or
%    D=0. The M,C,K,B,F,G,D matrices are stored as sparse double arrays.
%
%    SYS = MECHSS(M,C,K,B,F,G,D,Ts) creates a discrete-time model with
%    equations
%       M q[k+2] + C q[k+1] + K q[k] = B u[k]
%                               y[k] = F q[k] + G q[k+1] + D u[k]
%    and sample time Ts. Set Ts=-1 if the sample time is undetermined.
%
%    SYS = MECHSS(D) specifies a static model with feedthrough D.
%
%    SYS = MECHSS(M,C,K) specifies a model with B=F=I and G=0.
%
%    Type "properties(mechss)" for a list of model properties, and type
%       help mechss.<PropertyName>
%    for help on specific property. For example, "help mechss.InputDelay"
%    has details about the "InputDelay" property. Use the "SolverOptions"
%    property to configure numerical computation involving SYS, see
%    mechssOptions for details.
%
%  Arrays of sparse mechanical models:
%    You can create an array of MECHSS models using indexed assignment
%    or the STACK function. For example,
%       sys = mechss(zeros(1,1,2))     % create 2x1 array of models
%       sys(:,:,1) = mechss(M,C,K,B,F) % assign 1st model
%       sys(:,:,2) = MDL2              % assign 2nd model
%       sys = stack(1,sys,MDL3)        % add 3rd model to array
%
%  Conversion:
%    SYS = MECHSS(SYS) converts any dynamic system SYS to second-order
%    form. For SPARSS models, the result has a nonzero mass matrix
%    when SYS has a second-order structure, and a zero mass matrix
%    otherwise.
%
%  See also SPARSS, SS, STACK, MECHSSDATA, MECHSSOPTIONS, SHOWSTATEINFO, DYNAMICSYSTEM.

%   Copyright 2020 The MathWorks, Inc.
try
   ni = nargin;
   [ConstructFlag,InputList] = lti.isContructorCall('mechss',varargin);
   if ConstructFlag
      % MECHSS(a,b,c,d,MECHSS_SYS): Try again with system replaced by struct
      sysOut = ss(InputList{:});
   elseif ni>1
      % Invalid syntax
      error(message('Control:transformation:InvalidConversionSyntax','mechss','mechss'))
   else
      sys = InputList{1};
      sysOut = copyMetaData(sys,mechss_(sys));
      % Make sure system name gets pushed down to StateInfo
      sysOut = setName_(sysOut,sys.Name);
   end
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:mechss1',class(sys)))
   else
      throw(E)
   end
end
