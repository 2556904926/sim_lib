function L = lft(M,N,varargin)
%LFT  Generalized feedback interconnection of input/output models.
%
%   M = LFT(M1,M2,NU,NY) forms the following feedback interconnection 
%   of the input/output models M1 and M2:
%		
%                        +-------+
%            w1 -------->|       |-------> z1
%                        |   M1  |
%                  +---->|       |-----+
%                  |     +-------+     |
%                u |                   | y
%                  |     +-------+     |
%                  +-----|       |<----+
%                        |   M2  |
%           z2 <---------|       |-------- w2
%                        +-------+
%
%   The feedback loop connects the first NU outputs of M2 to the last 
%   NU inputs of M1 (signals u), and the last NY outputs of M1 to the 
%   first NY inputs of M2 (signals y). The resulting system M maps the
%   input vector [w1;w2] to the output vector [z1;z2]. This operation is 
%   referred to as a linear fractional transformation or LFT.
%
%   M = LFT(M1,M2) returns
%     * the lower LFT of M1 and M2 if M2 has fewer inputs and outputs 
%       than M1. This amounts to deleting w2,z2 in the above diagram.
%     * the upper LFT of M1 and M2 if M1 has fewer inputs and outputs 
%       than M2. This amounts to deleting w1,z1 above.
%
%   If M1 and M2 are arrays of models, LFT returns a model array M of the 
%   same size where 
%      M(:,:,k) = LFT(M1(:,:,k),M2(:,:,k),NU,NY) .
%
%   For dynamic systems SYS1 and SYS2, 
%      SYS = LFT(SYS1,SYS2,'name') 
%   connects SYS1 and SYS2 by matching their I/O names. The output of SYS1 
%   are connected to the inputs of SYS2 with the same names, and similarly 
%   for the inputs of SYS1 and outputs of SYS2.
%
%   See also FEEDBACK, CONNECT, INPUTOUTPUTMODEL, DYNAMICSYSTEM.

%   Author(s): P. Gahinet.
%   Copyright 1986-2023 The MathWorks, Inc.

% Note: Limited to 2D, no error checking since used as low-level utility
ni = nargin;
[nyz1,nuw1] = size(M);
[nuz2,nyw2] = size(N);
if ni==2
   % LFT(M,N) computes the upper or lower LFT depending which of M,N is bigger
   [ny1,nu1] = size(M);
   [nu2,ny2] = size(N);
   if nu2>nu1 && ny2>ny1
      % Upper LFT
      N22 = N(1:nu1,1:ny1);
      if norm(N22,1)==0
         X = M;
      elseif ny1>nu1
         X = matlab.internal.math.nowarn.mrdivide(M,eye(nu1)-N22*M);
      else
         X = matlab.internal.math.nowarn.mldivide(eye(ny1)-M*N22,M);
      end
      if ny1>nu1
         L = N(nu1+1:nu2,ny1+1:ny2) + N(nu1+1:nu2,1:ny1) * (X * N(1:nu1,ny1+1:ny2));
      else
         L = N(nu1+1:nu2,ny1+1:ny2) + (N(nu1+1:nu2,1:ny1) * X) * N(1:nu1,ny1+1:ny2);
      end
   else
      % Lower LFT
      nz1 = nyz1-ny2;   nw1 = nuw1-nu2;
      M22 = M(nz1+1:nyz1,nw1+1:nuw1);
      if norm(M22,1)==0
         X = N;
      elseif ny2>nu2
         X = matlab.internal.math.nowarn.mldivide(eye(nu2)-N*M22,N);
      else
         X = matlab.internal.math.nowarn.mrdivide(N,eye(ny2)-M22*N);
      end
      if ny2>nu2
         L = M(1:nz1,1:nw1) + M(1:nz1,nw1+1:nuw1) * (X * M(nz1+1:nyz1,1:nw1));
      else
         L = M(1:nz1,1:nw1) + (M(1:nz1,nw1+1:nuw1) * X) * M(nz1+1:nyz1,1:nw1);
      end
   end
else
   if ni==4
      % LFT(M,N,nu,ny)
      nu = varargin{1};   ny = varargin{2};
      indu1 = nuw1-nu+1:nuw1;   indy2 = 1:ny;
      indy1 = nyz1-ny+1:nyz1;   indu2 = 1:nu;
   elseif ni==6
      % LFT(M,N,indu1,indy1,indy2,indu2)  (not documented)
      indu1 = varargin{1};   indy1 = varargin{2};
      indy2 = varargin{3};   indu2 = varargin{4};
      nu = numel(indu1);  ny = numel(indy1);
   else
      error(message('Control:combination:lft3'))
   end      
   indw1 = 1:nuw1; indw1(indu1) = [];  nw1 = length(indw1);
   indz1 = 1:nyz1; indz1(indy1) = [];  nz1 = length(indz1);
   indw2 = 1:nyw2; indw2(indy2) = [];  nw2 = length(indw2);
   indz2 = 1:nuz2; indz2(indu2) = [];  nz2 = length(indz2);
   M22 = M(indy1,indu1);
   N22 = N(indu2,indy2);
   if norm(M22,1)==0 && norm(N22,1)==0
      L = [M(indz1,indw1) M(indz1,indu1)*N(indu2,indw2) ; ...
         N(indz2,indy2)*M(indy1,indw1) N(indz2,indw2)];
   else
      L = [M(indz1,indw1) zeros(nz1,nw2) ; zeros(nz2,nw1) N(indz2,indw2)];
      if nw1+nw2<nz1+nz2
         X = matlab.internal.math.nowarn.mldivide([eye(ny) -M22;-N22 eye(nu)],...
            [M(indy1,indw1) zeros(ny,nw2) ; zeros(nu,nw1) N(indu2,indw2)]);
         L = L + [M(indz1,indu1) * X(ny+1:ny+nu,:) ; N(indz2,indy2) * X(1:ny,:)];
      else
         X = matlab.internal.math.nowarn.mrdivide(...
            [zeros(nz1,ny) M(indz1,indu1) ; N(indz2,indy2) zeros(nz2,nu)],...
            [eye(ny) -M22;-N22 eye(nu)]);
         L = L + [X(:,1:ny) * M(indy1,indw1) , X(:,ny+1:ny+nu) * N(indu2,indw2)];
      end
   end   
end

