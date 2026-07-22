function r = fastrloc(s,gains)
% Fast computation of closed-loop poles given the Hessenberg
% form and zero/pole/gain data obtained from LTIDATA/RLOCUS
% (used in SISO Tool for quick update mode).

%   Copyright 1986-2020 The MathWorks, Inc.

% RE: GAINS must be a row vector
if s.Gain==0
   r = zeros(0,length(gains));
else
   if s.InverseFlag
      % Working with inverse open-loop. Transform gains -> 1/gains
      iszero = (gains==0);
      gains(iszero) = Inf;
      gains(~iszero) = 1./gains(~iszero);
   end
   r = genrloc(s.a,s.b,s.c,s.d,s.Ts,gains,s.Zero,s.Pole,'sort');
end
