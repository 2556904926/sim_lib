classdef incrementalPOD 
   % Incremental Proper Orthogonal Decomposition (POD).
   %
   %   This class computes a low-rank approximation X~U*R*V' of the snapshot
   %   matrix X. In POD-based model reduction, the columns of X are snapshots
   %   of the state vector x gathered during simulation of the state-space
   %   model to be reduced. In incremental POD, the matrix X is not stored
   %   in memory. Instead, the U,R factors are updated when a new column of
   %   X becomes available, and this column is then discarded. In the
   %   resulting U*R*V' approximation, U,V are tall orthogonal and R is square.
   %   Since this is used to approximate the gramian
   %      G = X*X' ~ (U*R)*(U*R)'
   %   the V matrix is not stored. The computed factorization satisfies
   %      || X - U*R*V' || = || X - U*(U'*X) || <= o(RankTol) * || X ||.
   %
   %   XPOD = incrementalPOD() initializes the incremental POD process.
   %   When a new column x becomes available,
   %      XPOD = update(XPOD,x,wx)
   %   updates U,R to incorporate this new snapshot. You can specify a 
   %   different weight wx for each snapshot. When all columns of X have been 
   %   processed, XPOD contains a low-rank approximation of X*X' that can be 
   %   retrieved with the GETUR or SVD methods.
   %
   %   Properties:
   %      Snapshots    Number of snapshots processed.
   %      MaxRank      Upper estimate of rank of snapshot matrix.
   %      RankTol      Tolerance for SVD truncation.
   %      Transform    Snapshot transformation.
   %
   % See also incrementalPOD/update, incrementalPOD/getUR, incrementalPOD/svd,
   % incrementalPOD/merge.

   %  Author(s): P. Gahinet
   %  Copyright 2024 The MathWorks, Inc.
   properties (SetAccess=protected)
      % Number of snapshots collected so far.
      Snapshots = 0;
      % Rank of URV factorization (upper estimate of rank of X).
      MaxRank = 0;
   end

   properties
      % Tolerance for SVD truncation.
      RankTol (1,1) double {mustBeInRange(RankTol,0,1,"exclusive")} = 1e-6;
      % State transform (T*x is the actual state)
      Transform = [];
   end

   properties (Access=protected)
      % Internal U,R factors 
      U_ = [];
      R_ = [];
      % Cumulative sum of columns (for centering)
      ColSum_ = 0;
      % Current column size of R_
      NCR_ = 0;
      % Rank after last SVD compression
      LastRank_ = 0;
      % Number of SVD compressions
      NCompress_ = 0;
   end


   methods

      function POD = update(POD,c,wc)
         % Update URV approximation given new snapshots.
         %
         %   Given the result XPOD of incremental POD applied to the snapshot 
         %   ensemble X, 
         %      XPOD = update(XPOD,XNEW) 
         %   adds new snapshots to X and updates the U,R factors accordingly. 
         %   XNEW can be a single column or a batch of columns.
         %
         %   XPOD = update(XPOD,XNEW,WX) specifies a scalar weight for each  
         %   new snapshot. The weights are typically a function of step size.
         %
         % See also incrementalPOD/merge.
         arguments
            POD
            c (:,:) double;
            wc double = 1;
         end

         if ~allfinite(c)
            error(message('Control:analysis:incPOD4'))
         end

         % Absorb weight
         if nargin>2
            if isscalar(wc)
               c = wc * c;
            elseif numel(wc)==size(c,2)
               c = c .* reshape(wc,[1 numel(wc)]);
            else
               error(message('Control:analysis:incPOD3'))
            end
         end

         rk = POD.MaxRank;
         tol = POD.RankTol;
         if iscolumn(c)
            % Process single column
            try
               if ~isempty(POD.Transform)
                  c = POD.Transform * c;
               end
               POD.ColSum_ = POD.ColSum_+c;
            catch
               error(message('Control:analysis:incPOD1'))
            end
            % Memory management
            if rk==size(POD.U_,2)
               % Double buffer sizes
               nrx = max(50,rk);
               POD.U_ = [POD.U_ zeros(numel(c),nrx)];
               POD.R_ = blkdiag(POD.R_,zeros(nrx,10*nrx));
            end
            % Compress R when allocated columns are filled up
            if POD.NCR_==size(POD.R_,2)
               RR = qr(POD.R_(1:rk,:)',0);
               POD.R_(1:rk,1:rk) = RR';
               POD.NCR_ = rk;
            end
            % Decompose c = U*w + rho*r with [U,r] orthogonal.
            [r, rho, w] = orthogonalize(POD.U_, c, rk, tol);
            ncR = POD.NCR_;
            if rho==0
               % R -> [R w]
               POD.R_(1:rk,ncR+1) = w;
            else
               % U -> [U r],  R -> [R w;0 rho]
               POD.U_(:,rk+1) = r;
               POD.R_(1:rk,ncR+1) = w;
               POD.R_(rk+1,1:ncR) = 0;
               POD.R_(rk+1,ncR+1) = rho;
               rk = rk+1;
            end
            POD.NCR_ = ncR+1;
            % Compress by truncated SVD when the rank has doubled
            if rk>=max(50,2*POD.LastRank_)
               [u,s,~] = svd(POD.R_(1:rk,1:POD.NCR_),"econ","vector");
               rkc = nnz(s>tol*s(1));
               POD.U_(:,1:rkc) = matlab.internal.math.viewColumns(POD.U_,rk) * u(:,1:rkc);
               POD.R_(1:rkc,1:rkc) = diag(s(1:rkc,:));
               rk = rkc;
               POD.LastRank_ = rk;
               POD.NCR_ = rk;
               POD.NCompress_ = POD.NCompress_+1;
            end
            POD.Snapshots = POD.Snapshots+1;
         else
            % Process a batch of columns at once
            % Note: Processing one column at a time in a FOR loop may be
            % more efficient for small column size.
            [nrX,ncX] = size(c);
            try
               if ~isempty(POD.Transform)
                  c = POD.Transform * c;
               end
               POD.ColSum_ = POD.ColSum_ + sum(c,2);
            catch
               error(message('Control:analysis:incPOD1'))
            end
            POD.Snapshots = POD.Snapshots + ncX;
            if ncX>0
               if nrX>rk+ncX
                  % Tall problem: [U*R,X] = [U C]*[R 0;0 I]
                  [Q,RX] = qr([POD.U_(:,1:rk) c],"econ");
                  if POD.NCR_>rk
                     % Compress R' to rk x rk
                     RR = qr(POD.R_(1:rk,1:POD.NCR_)',"econ");
                     RX(:,1:rk) = RX(:,1:rk) * RR';
                  else
                     RX(:,1:rk) = RX(:,1:rk) * POD.R_(1:rk,1:rk);
                  end
                  [u,s] = svd(RX,"vector");  % RX square size rk+ncX
                  rk = nnz(s>tol*s(1));
                  POD.U_ = Q * u(:,1:rk);
               else
                  % Wide problem: Treat as [U*R X]
                  UR = POD.U_(:,1:rk) * POD.R_(1:rk,1:POD.NCR_);
                  RX = qr([UR c]',"econ")';
                  [u,s] = svd(RX,"vector"); % RX square size nrX
                  rk = nnz(s>tol*s(1));
                  POD.U_ = u(:,1:rk);
               end
               POD.R_ = diag(s(1:rk,:));
               POD.NCR_ = rk;
               POD.LastRank_ = rk;
            end
         end
         POD.MaxRank = rk;
      end

      function POD = set.Transform(POD,Value)
         % SET function for Transform
         if isempty(Value)
            POD.Transform = [];
         elseif isnumeric(Value) && ismatrix(Value) && diff(size(Value))==0
            POD.Transform = double(Value);
         else
            error(message('Control:analysis:incPOD2'))
         end
      end

      function [U,R] = getUR(POD)
         % Query the U,R factors.
         %
         %   [U,R] = getUR(XPOD) returns the U,R factors for the snapshot
         %   collection X processed so far by XPOD. The matrix U is tall 
         %   and orthogonal, R is square, and (U*R)*(U*R)' is a low-rank 
         %   approximation of X*X'.
         %
         % See also incrementalPOD/svd.
         rk = POD.MaxRank;
         U = POD.U_(:,1:rk);
         if rk==POD.NCR_
            R = POD.R_(1:rk,1:rk);
         else
            % Compress to square
            R = qr(POD.R_(1:rk,1:POD.NCR_)',0)';
         end
      end

      function xm = getMean(POD)
         % Returns mean value of X
         xm = POD.ColSum_/POD.Snapshots;
      end

      function n = numelSnapshot(POD)
         % Returns snapshot length.
         if POD.Snapshots==0
            n = 0;
         else
            n = numel(POD.ColSum_);
         end
      end

      function [Ur,sr] = svd(POD,tol,CENTER)
         % Compute truncated SVD of X.
         %
         %    [UR,SR] = svd(XPOD) returns a tall orthogonal matrix UR and
         %    a vector SR with positive entries such that 
         %        X * X' ~ UR * diag(SR.^2) * UR'
         %    for the matrix X of snapshots processed so far by XPOD. This 
         %    is a truncated SVD of X where SR are the dominant singular
         %    values (for the relative threshold XPOD.RankTol) and the 
         %    columns of UR are the corresponding left singular vectors.
         %    
         %    [UR,SR] = svd(XPOD,TOL) specifies the relative tolerance TOL
         %    for SVD truncation. It should be larger than XPOD.RankTol for 
         %    meaningful results. The default value is TOL=XPOD.RankTol.
         %
         %    [UR,SR] = svd(XPOD,TOL,CENTER) specifies whether to center 
         %    the data. When CENTER=TRUE, the mean value of X is substracted
         %    from X before computing the SVD. The default is CENTER=FALSE.
         %    
         % See also incrementalPOD/getUR, incrementalPOD/getMean.
         arguments
            POD
            tol (1,1) double {mustBeInRange(tol,0,1,"exclusive")} = POD.RankTol;
            CENTER = false;
         end
         %    X ~ Ur * diag(sr) * Vr' or X-mean(X,2) ~ Ur * diag(sr) * Vr'
         [u,s,~] = svd(POD.R_(1:POD.MaxRank,1:POD.NCR_),"econ","vector");
         if isempty(s)
            rk = 0;
         else
            rk = nnz(s>tol*s(1));
         end
         Ur = matlab.internal.math.viewColumns(POD.U_,POD.MaxRank) * u(:,1:rk);
         sr = s(1:rk,:);
         if CENTER
            % Centering
            xmr = Ur'*POD.ColSum_;
            [q,t] = schur(diag(sr.^2)-(xmr*xmr')/POD.Snapshots);
            [sr,is] = sort(sqrt(max(0,diag(t))),'descend');
            rk = nnz(sr>tol*sr(1));
            sr = sr(1:rk,:);
            Ur = Ur * q(:,is(1:rk));
         end
      end

      function POD = merge(POD,varargin)
         % Combine POD results.
         %
         %   XPOD = merge(XPOD1,XPOD2,...) combines the results of several
         %   incremental PODs applied to the snapshot ensembles X1,X2,... 
         %   This is equivalent to one incremental POD applied to the columns
         %   of X=[X1,X2,...].
         %    
         % See also incrementalPOD/update.
         ni = nargin;
         if ni>1
            [U,R] = getUR(POD);
            M = U*R;
            try
               for j=1:ni-1
                  PODj = varargin{j};
                  POD.ColSum_ = POD.ColSum_ + PODj.ColSum_;
                  POD.Snapshots = POD.Snapshots + PODj.Snapshots;
                  [Uj,Rj] = getUR(PODj);
                  M = [M Uj*Rj]; %#ok<AGROW>
               end
            catch
               error(message('Control:analysis:incPOD5'))
            end
            [U,s] = svd(M,"econ","vector");
            rk = nnz(s>POD.RankTol*s(1));
            POD.U_ = U(:,1:rk);
            POD.R_ = diag(s(1:rk,:));
            POD.MaxRank = rk;
            POD.NCR_ = rk;
            POD.LastRank_ = rk;
         end
      end

   end

end


%---------------------------------------------------------------
function [r, normRes, w] = orthogonalize(V, r, j, tol)
% DGKS orthogonalization, also used in EIGS.
% Decomposes r as V*w + normRes*r with [V,r] orthogonal.
if j>0
   Vj = matlab.internal.math.viewColumns(V, j);
   normResOld = norm(r);
   w = 0;
   for numReorths=1:5
      dw = Vj' * r;
      r = r - Vj * dw;
      w = w + dw;
      normRes = norm(r);
      if normRes <= tol * norm(w)
         % Treat small residual as zero
         normRes = 0;   break
      elseif normRes > 0.707*normResOld
         % r orthogonalized wrt Vj
         break
      elseif numReorths==5
         % r is in span(Vj)
         normRes = 0;
      end
      normResOld = normRes;
   end
else
   normRes = norm(r);
   w = zeros(0,1);
end

if normRes>0
   r = r/normRes;
end
end
