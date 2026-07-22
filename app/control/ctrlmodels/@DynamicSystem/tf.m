function sysOut = tf(varargin)
%TF  Construct transfer function or convert to transfer function.
%
%  Construction:
%    SYS = TF(NUM,DEN) creates a continuous-time transfer function SYS with
%    numerator NUM and denominator DEN. SYS is an object of type TF when 
%    NUM,DEN are numeric arrays, of type GENSS when NUM,DEN depend on tunable 
%    parameters (see REALP and GENMAT), and of type USS when NUM,DEN are 
%    uncertain (requires Robust Control Toolbox).
%
%    SYS = TF(NUM,DEN,TS) creates a discrete-time transfer function with
%    sample time TS (set TS=-1 if the sample time is undetermined).
%
%    S = TF('s') specifies the transfer function H(s) = s (Laplace variable).
%    Z = TF('z',TS) specifies H(z) = z with sample time TS.
%    You can then specify transfer functions directly as expressions in S
%    or Z, for example,
%       s = tf('s');  H = exp(-s)*(s+1)/(s^2+3*s+1)
%
%    SYS = TF creates an empty TF object.
%    SYS = TF(M) specifies a static gain matrix M.
%
%    You can set additional model properties by using name/value pairs.
%    For example,
%       sys = tf(1,[1 2 5],0.1,'Variable','q','ioDelay',3)
%    also sets the variable and transport delay. Type "properties(tf)"
%    for a complete list of model properties, and type
%       help tf.<PropertyName>
%    for help on a particular property. For example, "help tf.Variable"
%    provides information about the "Variable" property.
%
%    By default, transfer functions are displayed as functions of 's' or 'z'.
%    Alternatively, you can use the variable 'p' in continuous time and the
%    variables 'z^-1', 'q', or 'q^-1' in discrete time by modifying the
%    "Variable" property.
%
%  Data format:
%    For SISO models, NUM and DEN are row vectors listing the numerator
%    and denominator coefficients in descending powers of s,p,z,q or in
%    ascending powers of z^-1 (DSP convention). For example,
%       sys = tf([1 2],[1 0 10])
%    specifies the transfer function (s+2)/(s^2+10) while
%       sys = tf([1 2],[1 5 10],0.1,'Variable','z^-1')
%    specifies (1 + 2 z^-1)/(1 + 5 z^-1 + 10 z^-2).
%
%    For MIMO models with NY outputs and NU inputs, NUM and DEN are
%    NY-by-NU cell arrays of row vectors where NUM{i,j} and DEN{i,j}
%    specify the transfer function from input j to output i. For example,
%       H = tf( {-5 ; [1 -5 6]} , {[1 -1] ; [1 1 0]})
%    specifies the two-output, one-input transfer function
%       [     -5 /(s-1)      ]
%       [ (s^2-5s+6)/(s^2+s) ]
%
%  Arrays of transfer functions:
%    You can create arrays of transfer functions by using ND cell arrays
%    for NUM and DEN above. For example, if NUM and DEN are cell arrays
%    of size [NY NU 3 4], then
%       SYS = TF(NUM,DEN)
%    creates the 3-by-4 array of transfer functions
%       SYS(:,:,k,m) = TF(NUM(:,:,k,m),DEN(:,:,k,m)),  k=1:3,  m=1:4.
%    Each of these transfer functions has NY outputs and NU inputs.
%
%    To pre-allocate an array of zero transfer functions with NY outputs
%    and NU inputs, use the syntax
%       SYS = TF(ZEROS([NY NU k1 k2...])) .
%
%  Conversion:
%    SYS = TF(SYS) converts any dynamic system SYS to the transfer function 
%    representation. The resulting SYS is always of class TF.
%
%  See also TF/EXP, FILT, TFDATA, ZPK, SS, FRD, GENSS, USS, DYNAMICSYSTEM.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.
try
   ni = nargin;
   [ConstructFlag,InputList] = lti.isContructorCall('tf',varargin);
   if ConstructFlag
      % TF(num,den,TFSYS): Try again with system replaced by struct
      sysOut = tf(InputList{:});
   else
      if ni>1
         if strcmp(InputList{2},'inv')
            % Obsolete syntax: ignore
            InputList(:,2) = [];
         elseif ni==2
            % tf(a,b) with a or b a dynamic block
            error(message('Control:transformation:InvalidConversionSyntax','tf','tf'))
         end
      end
      sys = InputList{1};
      opt = initOptions(ltioptions.zpk,InputList(2:end));
      sysOut = tf_(sys,opt);
      % Inherit metadata and Variable
      sysOut = copyMetaData(sys,sysOut);
      var = getVariable_(sys);
      if ~isempty(var)
         sysOut.Variable = var;
      end
   end
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:tf2',class(sys)))
   else
      throw(E)
   end
end
