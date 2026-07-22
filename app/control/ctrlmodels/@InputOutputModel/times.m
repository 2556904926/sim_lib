function M = times(M1,M2)
%TIMES  Multiplies two input/output models I/O-pairwise.
%
%   M = TIMES(M1,M2) performs M = M1 .* M2. This operation
%   amounts to an element-by-element multiplication of the transfer
%   functions of the dynamic systems M1 and M2.
%
%   If M1 and M2 are arrays of dynamic systems, their .* product is a
%   system array M with the same number of models where the k-th system
%   is obtained by
%      M(:,:,k) = M1(:,:,k) .* M2(:,:,k)
%
%   See also DYNAMICMTEM/MTIMES, SERIES, DYNAMICMTEM.

%   Author(s): P. Gahinet
%   Copyright 1986-2012 The MathWorks, Inc.
try
   if ~ltipack.hasMatchingType('times',M1,M2)
      % Harmonize types
      [M1,M2] = ltipack.matchType('times',M1,M2);
   end
   
   % Check I/O dimensions and handle scalar multiplication
   sizes1 = M1.IOSize_;
   sizes2 = M2.IOSize_;
   ScalarFlags = false(1,2);
   if all(sizes1(1:2)==1) && any(sizes2(1:2)~=1)
      % M1 is scalar
      if any(sizes2==0)
         % Scalar * Empty = Empty
         M = M2;   return
      else
         ScalarFlags(1) = true;
      end
   elseif all(sizes2(1:2)==1) && any(sizes1(1:2)~=1)
      % M2 is scalar
      if any(sizes1==0)
         % Scalar * Empty = Empty
         M = M1;   return
      else
         ScalarFlags(2) = true;
      end
   elseif ~any(ScalarFlags) && (sizes1(1)~=sizes2(1) || sizes1(2)~=sizes2(2))
      error(message('Control:combination:IncompatibleIODims'))
   end
   
   % Combine data
   M = times_(M1,M2,ScalarFlags);% overloadable since M1,M2 are of the same class
   
   % Combine metadata
   if ScalarFlags(1)
      % Scalar multiplication: keep M2's metadata if M is scalar
      M = copyMetaData(M2,M);
   elseif ScalarFlags(2)
      M = copyMetaData(M1,M);
   else
      M = plusMetaData(M,M1,M2);
   end
catch E
   ltipack.throw(E,'operator','.*',class(M1))
end

