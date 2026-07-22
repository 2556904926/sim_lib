function X = lyap(A, B, C, E)
%LYAP  Solve continuous-time Lyapunov equations.
%
%   X = LYAP(A,Q) solves the Lyapunov matrix equation:
%
%       A*X + X*A' + Q = 0
%
%   X = LYAP(A,B,C) solves the Sylvester equation:
%
%       A*X + X*B + C = 0
%
%   X = LYAP(A,Q,[],E) solves the generalized Lyapunov equation:
%
%       A*X*E' + E*X*A' + Q = 0    where Q is symmetric
%
%   See also LYAPCHOL, DLYAP.

%	Authors: S.N. Bangert 1-10-86
%           JNL 3-24-88, AFP 9-3-95, PG 09-02
%   Copyright 1986-2021 The MathWorks, Inc.
arguments
   A(:,:) double {mustBeFinite}
   B(:,:) double {mustBeFinite}
   C(:,:) double {mustBeFinite} = [];
   E(:,:) double {mustBeFinite} = [];
end
ni = nargin;

% Validate data
try
   [A,B,C,E] = lyapcheckin('lyap',ni,A,B,C,E);
catch err
   throw(err)
end

% Balance to minimize spectrum distorsions in Hess/Schur/QZ factorizations
if ni==3
   % Sylvester
   [sA,pA,A] = mscale(A,'fullbal');
   [sB,pB,B] = mscale(B,'fullbal');
   C(pA,pB) = lrscale(C,1./sA,sB);  % TA\C*TB
else
   [A,~,~,E,s,p] = aebalance(A,[],[],E,'fullbal');
   B(p,p) = lrscale(B,1./s,1./s);  % T\B/T'
end

% Solve equation
if ni==3
   % Sylvester equation A*X+X*B=-C
   X = sylvester(A, B, -C);
   X = lrscale(X(pA,pB),sA,1./sB);  % TA*X/TB
else
   % Lyapunov equation A*X+X*A'=-B or A*X*E'+E*X*A'=-B
   if isequal(E, [])
      X = lyapunov(A, -B);
   else
      X = genlyapunov(A, -B, E);
   end
   X = lrscale(X(p,p),s,s);  % T*X*T' using T(:,p)=diag(s)
end

% Error if X contains Inf or NaN.
if ~allfinite(X)
   try
      if ni==3
         error(message('Control:foundation:SingularSylv'))
      else
         error(message('Control:foundation:SingularLyap'))
      end
   catch err
      throw(err);
   end
end



function X = lyapunov(A, C)
%Solve simple continuous-time Lyapunov Equation A*X + X*A' = C,

if ishermitian(A)
   [QA, dA] = eig(A, 'vector');

   CC = QA'*C*QA;
   X = CC ./ (dA + dA');
   X = QA*X*QA';

else
   % Reduce equation to triangular form
   flag = 'real';
   if ~isreal(A) || ~isreal(C)
      flag = 'complex'; % Need complex Schur form
   end

   CC = C;
   schurA = matlab.internal.math.isQuasiTriangular(A,flag);
   if schurA
      TA = A;
   else
      [QA, TA] = schur(A, flag);
      CC = QA'*CC*QA;
   end

   % Solve Lyapunov Equation TA*X + X*TA' = QA'*C*QA.
   X = matlab.internal.math.sylvester_tri(TA, TA, CC, 'I', 'I', 'transp');

   % Recover X
   if ~schurA
      X = QA*X*QA';
   end
end

if ishermitian(C)
   X = (X + X') / 2;
end


function X = genlyapunov(A, C, E)
% Solve generalized continuous-time Lyapunov equation A*X*E' + E*X*A' = C

% Reduce equation to triangular form
flag = 'real';
if ~isreal(A) || ~isreal(C) || ~isreal(E)
   flag = 'complex'; % Need complex Schur form
end

CC = C;
qzAE = matlab.internal.math.isQuasiTriangular(A, E, flag);
if qzAE
   TA = A;
   TE = E;
else
   [TA, TE, Q, Z] = qz(A, E, flag);
   CC = Q*CC*Q';
end

% Solve Lyapunov Equation TA*X*TE' + TE*X*TA' = Q*C*Q'.
X = matlab.internal.math.sylvester_tri(TA, TA, CC, TE, TE, 'transp');

% Recover X
if ~qzAE
   X = Z*X*Z';
end

if ishermitian(C)
   X = (X + X') / 2;
end
