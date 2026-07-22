function sysOut = sparss(varargin)
%SPARSS  Sparse state-space model.
%
%  Construction:
%    SYS = SPARSS(A,B,C,D,E) creates an object SYS representing the
%    continuous-time state-space model
%        E dx/dt = Ax(t) + Bu(t)
%           y(t) = Cx(t) + Du(t)
%    where x(t) denotes the state vector (vector of generalized degrees
%    of freedom). You can set D=0 to mean the zero matrix of appropriate
%    size. The A,B,C,D,E matrices are stored as sparse double arrays.
%    When omitted, E defaults to the identity matrix.
%
%    SYS = SPARSS(A,B,C,D,E,Ts) creates a discrete-time state-space model
%    with sample time Ts (set Ts=-1 if the sample time is undetermined).
%    When E is the identity matrix, you can set E=[] or omit E as long
%    as A is not a scalar.
%
%    SYS = SPARSS(D) specifies a static gain matrix D.
%
%    Type "properties(sparss)" for a list of model properties, and type
%       help sparss.<PropertyName>
%    for help on specific property. For example, "help sparss.InputDelay"
%    has details about the "InputDelay" property. Use the "SolverOptions"
%    property to configure numerical computation involving SYS, see
%    sparssOptions for details.
%
%  Arrays of sparse state-space models:
%    You can create arrays of sparse state-space models using indexed
%    assignment or the STACK function. For example,
%       sys = sparss(zeros(1,1,2))   % create 2x1 array of models
%       sys(:,:,1) = sparss(A,B,C,D) % assign 1st model
%       sys(:,:,2) = MDL2            % assign 2nd model
%       sys = stack(1,sys,MDL3)      % add 3rd model to array
%
%  Conversion:
%    SYS = SPARSS(SYS) converts any dynamic system SYS to SPARSS. For a
%    MECHSS model with displacement q and nonsingular mass matrix M,
%    the SPARSS equivalent has state x(t) = [q(t);q'(t)] or
%    x[k] = [q[k];q[k+1]]. Use GETX0 to map initial conditions from
%    MECHSS to SPARSS.
%
%  See also MECHSS, STACK, SPARSSDATA, SPARSSOPTIONS, SHOWSTATEINFO,
%  MECHSS/GETX0, SS, FULL, DYNAMICSYSTEM.
   
%   Copyright 2020 The MathWorks, Inc.
try
   ni = nargin;
   [ConstructFlag,InputList] = lti.isContructorCall('sparss',varargin);
   if ConstructFlag
      % SPARSS(a,b,c,d,SPARSSSYS): Try again with system replaced by struct
      sysOut = ss(InputList{:});
   elseif ni>1
      % Invalid syntax
      error(message('Control:transformation:InvalidConversionSyntax','sparss','sparss'))
   else
      sys = InputList{1};
      sysOut = copyMetaData(sys,sparss_(sys));
      % Make sure system name gets pushed down to StateInfo
      sysOut = setName_(sysOut,sys.Name);
   end
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:sparss1',class(sys)))
   else
      throw(E)
   end
end
