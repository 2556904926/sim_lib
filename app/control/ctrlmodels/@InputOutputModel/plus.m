function M = plus(M1,M2)
%PLUS  Adds two input/output models together.
%
%   M = PLUS(M1,M2) performs M = M1 + M2. For dynamic systems, this is 
%   equivalent to connecting M1 and M2 in parallel.
%
%   If M1 and M2 are arrays of models, M is a model array of the same size
%   where the k-th model is the sum of the k-th models in M1 and M2:
%      M(:,:,k) = M1(:,:,k) + M2(:,:,k) .
%
%   See also PARALLEL, INPUTOUTPUTMODEL.

%   Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.
try
   if isnumeric(M1) && all(size(M1,[1 2])==1) && hasCustomScalarAdd_(M2)
      % Bypass for SCALAR + M2 (2 + @pid)
      M = M2.addScalar_(M1);
      
   elseif isnumeric(M2) && all(size(M2,[1 2])==1) && hasCustomScalarAdd_(M1)
      % Bypass for M1 + SCALAR 
      M = M1.addScalar_(M2);
      
   else
      % Harmonize types
      if ~ltipack.hasMatchingType('plus',M1,M2)
         [M1,M2] = ltipack.matchType('plus',M1,M2);
      end
      
      % Both operands are now of the same type
      % Check I/O sizes and detect scalar addition M1 + M2
      % (interpreted as M1 + M2*ones(M1) )
      sizes1 = M1.IOSize_;
      sizes2 = M2.IOSize_;
      if all(sizes1(1:2)==1) && any(sizes2(1:2)~=1)
         % M1 is SISO (scalar addition)
         if any(sizes2==0)
            % Scalar + Empty = Empty
            M = M2;   return
         else
            % Perform scalar expansion
            M1 = iorep(M1,sizes2(1:2));
         end
      elseif all(sizes2(1:2)==1) && any(sizes1(1:2)~=1)
         % M2 is SISO
         if any(sizes1==0)
            % Scalar + Empty = Empty
            M = M1;   return
         else
            M2 = iorep(M2,sizes1(1:2));
         end
      elseif any(sizes1(1:2)~=sizes2(1:2))
         error(message('Control:combination:IncompatibleIODims'))
      end
      
      % Combine data and metadata
      M = plus_(M1,M2);  % overloadable since M1,M2 are of the same class
      M = plusMetaData(M,M1,M2);
      % Consistency checks (e.g., consistent block definition in LFT arrays)
      checkModelArray_(M)
   end
catch E
   throw(E)
end

