classdef (Hidden) neutral_genfrd
   % Virtual class representing a genss model with no blocks and lower
   % precendence than all generalized state-space classes. This is needed
   % to prevent frd+ufrd from returning genfrd because ufrd<genfrd. This
   % class is never instantiated and only plays a transient role in
   % resolving the class of generalized models in binary operations.

   %	Copyright 2022 The MathWorks, Inc.

   methods (Static, Hidden)

      function T = superiorTypes()
         T = {'neutral_genfrd','ufrd','genfrd'};
      end

      function A = getAttributes(A)
         A.Varying = false;
         A.Sparse = false;
      end

   end

end