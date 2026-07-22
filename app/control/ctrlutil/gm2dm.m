function [alpha,sigma] = gm2dm(DGM)
%GM2DM  Converts gain margin to disk margin.
%
%   DISKMARGIN and UMARGIN model gain and phase variations as a dynamic
%   multiplicative factor F(s) with nominal value 1 and parameterization
%
%   F = (1 + ALPHA*(1-SIGMA)/2 * DELTA) / (1 - ALPHA*(1+SIGMA)/2 * DELTA)
%
%   where
%     * DELTA is normalized, gain-bounded dynamic uncertainty
%     * The "disk margin" ALPHA sets the amount of gain/phase uncertainty
%     * The "skew" SIGMA is a bias toward gain increase (SIGMA>0) or
%       gain decrease (SIGMA<0). The default SIGMA=0 is "balanced", meaning 
%       that the gain can increase or decrease by the same factor.
%
%   [ALPHA,SIGMA] = GM2DM(DGM) takes the disk-based gain margin 
%   DGM=[GMIN,GMAX] and returns the corresponding (ALPHA,SIGMA) pair. 
%   A feedback loop has a disk-based gain margin DGM=[GMIN,GMAX] when the 
%   loop gain can change by any factor between GMIN and GMAX without going 
%   unstable. GMIN and GMAX are in absolute units and must satisfy GMIN<1 
%   and GMAX>1. GMIN can be negative when the loop can withstand gain sign 
%   reversals.
%
%   For scalar GM>1, GM2DM(GM) is the same as GM2DM([1/GM,GM]) and always 
%   returns SIGMA=0 ("balanced" gain uncertainty).
%
%   Example: Compute ALPHA corresponding to gain margin of 6dB.
%      GM = db2mag(6);  % factor two change
%      alpha = gm2dm(GM)
%
%   Example: Compute ALPHA,SIGMA to capture gain variations between 80% and 150%
%   and phase variation between -20 and +40 degrees of nominal values.
%      DGM = getDGM([0.8 , 1.5],[-20 , 40],'tight');
%      [alpha,sigma] = gm2dm(DGM)
%
%   Example: Compute balanced disk margin ALPHA that provides 6dB gain
%   margin and 30 degrees phase margin.
%      GM = db2mag(6);
%      PM = 30;
%      DGM = getDGM(GM,PM,'balanced');
%      alpha = gm2dm(DGM);
%      % This ALPHA provides 6dB gain margin and 36 degrees phase margin:
%      [GMact,PMact] = dm2gm(alpha)
%
%   See also DM2GM, GETDPM, GETDGM, DISKMARGIN, DISKMARGINPLOT, WCDISKMARGIN, UMARGIN.

%   Copyright 2020 The MathWorks, Inc.
narginchk(1,1)
% Validate DGM
if ~(isnumeric(DGM) && isreal(DGM))
   error(message('Control:utility:gm2dm1'))
end
if iscolumn(DGM)
   DGM = [1./DGM , DGM];
elseif ~(ismatrix(DGM) && size(DGM,2)==2)
   error(message('Control:utility:gm2dm2'))
end
N = size(DGM,1);
try
   if N==1
      [alpha,sigma] = localConvert(DGM(1),DGM(2));
   else
      alpha = zeros(N,1);  sigma = zeros(N,1);
      for ct=1:N
         [alpha(ct),sigma(ct)] = localConvert(DGM(ct,1),DGM(ct,2));
      end
   end
catch ME
   throw(ME)
end

%---------------------------
function [alpha,sigma] = localConvert(gmin,gmax)
% Scalar implementation
if ~(gmin<=1 && gmax>=1 && gmin>-Inf && gmax<Inf)
   error(message('Control:utility:getDGM4'))
end   
   
% Compute alpha and sigma
if gmin==gmax
   % gmin=gmax=1
   alpha = 0; sigma = 0;
else
   % [alpha ; alpha*sigma] = 2*[gmin+1 gmin-1;gmax+1 gmax-1]\[1-gmin;gmax-1] 
   %                   = 2*[(gmax-1)*(1-gmin);gmin*gmax-1]/(gmax-gmin)
   tau = (gmax-1)*(1-gmin);
   alpha = 2*tau/(gmax-gmin);
   sigma = (gmin*gmax-1)/tau;  % inf when either gmin=1 or gmax=1
end