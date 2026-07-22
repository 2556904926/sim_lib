classdef (Hidden) neutral_genss
   % Virtual class representing a genss model with no blocks and lower
   % precendence than all generalized state-space classes. This is needed 
   % to prevent ss+uss from returning genss because uss<genss. This class
   % is never instantiated and only plays a transient role in resolving 
   % the class of generalized models in binary operations.

   %	Copyright 2022 The MathWorks, Inc.

   methods (Static, Hidden)

      function T = superiorTypes()
         T = {'neutral_genss','uss','genss'};
      end

      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.FRD = false;
         A.Sparse = false;
      end

      function T = toFRD()
         T = 'neutral_genfrd';
      end

   end

end