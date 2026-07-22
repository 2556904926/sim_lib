function [A,B,C,E] = lyapcheckin(Caller,ni,A,B,C,E)
% Validates input arguments to LYAP and DLYAP.

%   Copyright 1986-2007 The MathWorks, Inc.
if ni==3
   % Sylvester
   A = full(A);  B = full(B);  C = full(C);
   szA = size(A);  szB = size(B);  szC = size(C);
   if szA(1)~=szA(2) || szB(1)~=szB(2)
      error(message('Control:foundation:Sylvester1',Caller))
   elseif szC(1)~=szA(1) || szC(2)~=szB(1)
      error(message('Control:foundation:Sylvester2',Caller))
   end
else
   % Lyapunov
   A = full(A);  B = full(B);  E = full(E);
   szA = size(A);  szB = size(B);  szE = size(E);
   if numel(szA)>2 || numel(szB)>2 || szA(1)~=szA(2) || szB(1)~=szB(2) || szA(1)~=szB(1)
      error(message('Control:foundation:Lyapunov4',Caller))
   elseif any(szE) && any(szE~=szA(1))
      error(message('Control:foundation:Lyapunov5',Caller))
   end
end
