function M = mtimes(M1,M2)
%MTIMES  Multiplies two input/output models together.
%
%   M = MTIMES(M1,M2) performs the multiplication M = M1 * M2. For dynamic
%   systems, this is equivalent to connecting M1 and M2 in series as follows:
%
%      u ----> M2 ----> M1 ----> y
%
%   If M1 and M2 are arrays of models, their product is a model array of 
%   the same size where the k-th system is obtained by
%      M(:,:,k) = M1(:,:,k) * M2(:,:,k) .
%
%   See also SERIES, INPUTOUTPUTMODEL/MLDIVIDE, INPUTOUTPUTMODEL/MRDIVIDE, 
%   INPUTOUTPUTMODEL/INV, INPUTOUTPUTMODEL.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.
try
   if isnumeric(M1) && all(size(M1,[1 2])==1) && hasCustomScalarMultiply_(M2)
      % Bypass for SCALAR * M2 (e.g., 3 * @pid, 3 * @mechss)
      M = M2.leftMultiplyByScalar_(M1);
      
   elseif isnumeric(M2) && all(size(M2,[1 2])==1) && hasCustomScalarMultiply_(M1)
      % Bypass for M1 * SCALAR
      M = M1.rightMultiplyByScalar_(M2);
      
   else
      % Harmonize types
      if ~ltipack.hasMatchingType('mtimes',M1,M2)
         [M1,M2] = ltipack.matchType('mtimes',M1,M2);
      end
         
      % Both operands are now of the same type
      % Check I/O dimensions and handle scalar multiplication
      sizes1 = M1.IOSize_;
      sizes2 = M2.IOSize_;
      ScalarFlags = false(1,2);
      if all(sizes1(1:2)==1) && sizes2(1)~=1
         % M1 is SISO (scalar multiplication)
         if any(sizes2==0)
            % Scalar * Empty = Empty
            M = M2;   return
         elseif sizes2(1)>sizes2(2) && ...
               (isLinear_(M1) && ~isTimeVarying_(M1)) && ...
               (isLinear_(M2) && ~isTimeVarying_(M2))
            % ny2>nu2: evaluate as M2 * (m1 * eye(nu2)) to minimize order.
            % This is only possible when m1*M2 = M2*m1 (LTI)
            tmp = M2;  M2 = M1;  M1 = tmp;
            ScalarFlags(2) = true;
         else            
            % Evaluate as (m1 * eye(ny2)) * M2
            ScalarFlags(1) = true;
         end
      elseif all(sizes2(1:2)==1) && sizes1(2)~=1
         % M2 is SISO (scalar multiplication)
         if any(sizes1==0)
            % Scalar * Empty = Empty
            M = M1;   return
         elseif sizes1(1)<sizes1(2) && ...
               (isLinear_(M1) && ~isTimeVarying_(M1)) && ...
               (isLinear_(M2) && ~isTimeVarying_(M2))
            % ny1<nu1: valuate as (m2 * eye(ny1)) * M1 to minimize order.
            % This is only possible when M1*m2 = m2*M1 (LTI)
            tmp = M1;  M1 = M2;  M2 = tmp;
            ScalarFlags(1) = true;
         else
            % Evaluate as M1 * (m2 * eye(nu1))
            ScalarFlags(2) = true;
         end
      elseif ~any(ScalarFlags) && sizes1(2)~=sizes2(1)
         error(message('Control:combination:IncompatibleIODims'))
      end
      
      % Combine data and metadata
      M = mtimes_(M1,M2,ScalarFlags);% overloadable since M1,M2 are of the same class
      M = mtimesMetaData(M,M1,M2,ScalarFlags);      
      % Consistency checks (e.g., consistent block definition in LFT arrays)
      checkModelArray_(M)
   end
catch E
   throw(E)
end

