function X = dlyap(A, B, C, E)
%DLYAP  Solve discrete Lyapunov equations.
%
%   X = DLYAP(A,Q) solves the discrete Lyapunov matrix equation:
%
%       A*X*A' - X + Q = 0
%
%   X = DLYAP(A,B,C) solves the Sylvester equation:
%
%       A*X*B - X + C = 0
%
%   X = DLYAP(A,Q,[],E) solves the generalized discrete Lyapunov equation:
%
%       A*X*A' - E*X*E' + Q = 0
%
%   See also DLYAPCHOL, LYAP.

%	J.N. Little 2-1-86, AFP 7-28-94
%  Copyright 1986-2018 The MathWorks, Inc.
arguments
   A(:,:) double {mustBeFinite}
   B(:,:) double {mustBeFinite}
   C(:,:) double {mustBeFinite} = [];
   E(:,:) double {mustBeFinite} = [];
end
ni = nargin;

% Validate data
try
   [A,B,C,E] = lyapcheckin('dlyap',ni,A,B,C,E);
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
   % Sylvester equation A*X*B-X+C=0
   X = dsylvester(A, B, -C);
   X = lrscale(X(pA,pB),sA,1./sB);  % TA*X/TB
else
   % Lyapunov equation A*X*A'-X+B=0 or A*X*A'-E*X*E'+B=0
   if isequal(E, [])
      X = dlyapunov(A, -B);
   else
      X = dgenlyapunov(A, -B, E);
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



function X = dlyapunov(A, C)
% Solve simple discrete Lyapunov equation A*X*A' - X = C

if ishermitian(A)
   [QA, dA] = eig(A, 'vector');

   CC = QA'*C*QA;
   X = CC ./ (dA.*dA' - 1);
   X = QA*X*QA';

else
   % Reduce equation to triangular form
   flag = 'real';
   if ~isreal(A) || ~isreal(C)
      flag = 'complex'; % Need complex Schur form
   end

   CC = -C;
   schurA = matlab.internal.math.isQuasiTriangular(A,flag);
   if schurA
      TA = A;
   else
      [QA, TA] = schur(A, flag);
      CC = QA'*CC*QA;
   end

   % Solve Lyapunov Equation -TA*X*TA' + X = -QA'*C*QA.
   X = matlab.internal.math.sylvester_tri(TA, 'I', CC, 'I', -TA, 'transp');

   % Recover X
   if ~schurA
      X = QA*X*QA';
   end
end

if ishermitian(C)
   X = (X + X') / 2;
end


function X = dsylvester(A, B, C)
% Solve Sylvester Equation A*X*B - I = C.

if ishermitian(A) && ishermitian(B)
   [QA, dA] = eig(A, 'vector');
   [QB, dB] = eig(B, 'vector');

   CC = QA'*C*QB;
   X = CC ./ (dA.*dB' - 1);
   X = QA*X*QB';

else
   % Reduce equation to triangular form
   flag = 'real';
   if ~isreal(A) || ~isreal(B) || ~isreal(C)
      flag = 'complex'; % Need complex Schur form
   end

   CC = -C;
   schurA = matlab.internal.math.isQuasiTriangular(A,flag);
   if schurA
      TA = A;
   else
      [QA, TA] = schur(A, flag);
      CC = QA'*CC;
   end
   schurB = matlab.internal.math.isQuasiTriangular(B,flag);
   if schurB
      TB = B;
   else
      [QB, TB] = schur(B, flag);
      CC = CC*QB;
   end

   % Solve Sylvester Equation -TA*X*TB' + X = -QA'*C*QB.
   X = matlab.internal.math.sylvester_tri(TA, 'I', CC, 'I', -TB, 'notransp');

   % Recover X
   if ~schurA
      X = QA*X;
   end
   if ~schurB
      X = X*QB';
   end
end


function X = dgenlyapunov(A, C, E)
% Solve generalized discrete Lyapunov equation A*X*A' - E*X*E' = C

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

% Solve Lyapunov Equation TA*X*TA' - TE*X*TE' = Q*C*Q'.
X = matlab.internal.math.sylvester_tri(TA, TE, CC, -TE, TA, 'transp');

% Recover X
if ~qzAE
   X = Z*X*Z';
end

if ishermitian(C)
   X = (X + X') / 2;
end
