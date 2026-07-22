function x = randomizeGain(N,x0,xMin,xMax)
% Generate N random values of a parameter x with initial value x0 and 
% bounds [xMin,xMax]

%   Copyright 2009-2016 The MathWorks, Inc.

% Ignore x0 if out of bounds
if x0<xMin || x0>xMax
   x0 = 0;  % default value
end

FLB = isfinite(xMin);
FUB = isfinite(xMax);
if FLB && FUB
   % Both bound are specified: ignore x0
   r = rand(1,N);
   x = r * xMin + (1-r) * xMax;
elseif ~FLB && ~FUB
   % [xMin,xMax]=[-Inf,Inf]
   if x0==0
      % |x| ranges in [0.01,100] and sign(x) random
      x = sign(rand(1,N)-0.5) .* 10.^(4*rand(1,N)-2);
   else
      % |x| ranges in [x0/10,10*x0] and sign(x)=sign(x0)
      x = x0 * 10.^(2*rand(1,N)-1);
   end
elseif FLB
   % [xMin,xMax]=[xMin,Inf]
   if xMin~=0
      x = xMin + max(abs(x0),abs(xMin)) * (10.^(2*rand(1,N)-1) - 0.1);
   elseif x0==0
      x = 10.^(4*rand(1,N)-2);  % range = [0.01,100]
   else
      x = x0 * 10.^(2*rand(1,N)-1);
   end
else
   % [xMin,xMax]=[-Inf,xMax]
   if xMax~=0
      x = xMax - max(abs(x0),abs(xMax)) * (10.^(2*rand(1,N)-1) - 0.1);
   elseif x0==0
      x = -10.^(4*rand(1,N)-2);  % range = [-100,-0.01]
   else
      x = x0 * 10.^(2*rand(1,N)-1);
   end
end