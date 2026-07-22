function Mout = genss(M)
%GENSS  Generalized state-space models.
%
%  Construction:
%    Generalized state-space (GENSS) models arise when combining ordinary LTI
%    models (see LTI) with tunable blocks (see TUNABLEBLOCK). These
%    blocks support common control design tasks such as parameter studies and
%    performance tuning. GENSS models keep track of how the tunable blocks
%    interact with the fixed dynamics.
%
%    You can use SERIES, PARALLEL, FEEDBACK, LFT, or CONNECT to construct
%    GENSS models from Control Design blocks and regular LTI models. You can
%    also use the commands:
%       GENSYS = TF(N,D)
%       GENSYS = SS(A,B,C,D)
%    where one or more of the input arguments is a generalized matrix (see
%    GENMAT). This approach is helpful to create parametric models of tunable
%    components. Finally, you can cast any LTI model or Control Design block
%    SYS to GENSS using
%       GENSYS = GENSS(SYS)
%
%    GENSS models can be manipulated as ordinary state-space models. The
%    "Blocks" property gives access to the Control Design blocks in the model
%    and the SS, TF, ZPK commands evaluate the model by replacing each Control
%    Design block with its current value.
%
%    Example: Create a closed-loop model of a SISO loop with a tunable PID
%    block:
%       G = tf(0.1,[1 0.1],'InputDelay',2)   % plant model
%       C = tunablePID('C','pid')          % tunable PID compensator
%       T = feedback(G*C,1)                  % closed-loop transfer
%    Here T is a GENSS model depending on the Control Design block "PID". You
%    can plot the step response for the current PID settings by
%       step(T)
%
%    Example: Create the parametric plant model G = a/(s+a):
%       a = realp('a',1)
%       G = tf(a,[1 a])
%    The resulting GENSS model G is parameterized by the REALP block "a".
%    Plot the Bode response of G for ten values of "a" in [1,10]:
%       Gs = replaceBlock(G,'a',1:10);  % 10x1 array of models
%       bode(Gs)
%    Change the current value of "a" from 1 to 10 and evaluate G:
%       G.Blocks.a.Value = 10;
%       tf(G)
%    This returns 10/(s+10) as expected.
%
%  Conversion:
%    M = GENSS(M) converts the input/output model M to a generalized
%    state-space model of class @genss.
%
%  See also ss, tf, getValue, genmat, genlti, ControlDesignBlock, InputOutputModel.

%   Author(s): P. Gahinet, 5-1-96
%   Copyright 1986-2010 The MathWorks, Inc.
try
   Mout = copyMetaData(M,genss_(M));
catch E
   if any(strcmp(E.identifier,{'MATLAB:class:undefinedMethod','MATLAB:noSuchMethodOrField'}))
      error(message('Control:transformation:genss1',class(M)))
   else
      throw(E)
   end
end