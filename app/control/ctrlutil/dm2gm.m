function [DGM,DPM] = dm2gm(alpha,sigma)
%DM2GM  Converts disk margin to gain and phase margins.
%
%   DISKMARGIN and UMARGIN model gain and phase variations as a dynamic
%   multiplicative factor F(s) with nominal value 1 and parameterization
%
%   F = (1 + ALPHA*(1-SIGMA)/2 * DELTA) / (1 - ALPHA*(1+SIGMA)/2 * DELTA)
%
%   where
%     * DELTA is normalized, gain-bounded dynamic uncertainty
%     * The "disk margin" ALPHA sets the amount of gain/phase uncertainty
%     * The "skew" SIGMA is a bias toward gain increase (SIGMA>0) or gain
%       decrease (SIGMA<0). The default SIGMA=0 is "balanced", meaning
%       that the gain can increase or decrease by the same factor.
%
%   [DGM,DPM] = DM2GM(ALPHA) returns the symmetric disk-based gain margin
%   DGM (in absolute units) and phase margin DPM (in degrees) corresponding
%   to the disk margin ALPHA and the skew SIGMA=0. The nominal gain can
%   increase or decrease by a factor DGM, and the nominal phase can
%   increase or decrease by DPM degrees.
%
%   [DGM,DPM] = DM2GM(ALPHA,SIGMA) returns the disk-based gain margin
%   DGM=[GMIN,GMAX] and phase margin DPM=[PMIN,PMAX]. The nominal gain can
%   be multiplied by any factor between GMIN<1 and GMAX>1, and the nominal
%   phase can change by any amount between PMIN<0 and PMAX>0. For example,
%   DGM=[0.5,1.2] means that the gain can vary between 50% and 120% of its
%   nominal value, and DPM=[-30,30] means that the phase can vary by up to
%   30 degrees.
%
%   DM2GM is vectorized and returns N-by-1 or N-by-2 arrays when
%   ALPHA,SIGMA are vectors of length N.
%
%   Example: Compute the disk-based gain and phase margins corresponding to
%   the disk margin ALPHA=0.75
%      [DGM,DPM] = dm2gm(0.75);
%      mag2db(DGM)   % gain margin in dB
%      DPM           % phase margin in degrees
%
%   Example: Compute the range of gain and phase variations modeled by
%   the disk with parameters ALPHA=0.75 and SIGMA=-0.5
%      [DGM,DPM] = dm2gm(0.75,-0.5);
%      mag2db(DGM)   % relative gain variation in dB
%      DPM           % absolute phase variation in degrees
%
%   See also GM2DM, DISKMARGIN, DISKMARGINPLOT, WCDISKMARGIN, UMARGIN.

%   Copyright 2018-2020 The MathWorks, Inc.
narginchk(1,2)
if nargin<2
   sigma = 0;
end
Na = numel(alpha);
Ne = numel(sigma);
if ~(isnumeric(alpha) && isvector(alpha) && isreal(alpha) && ...
      isnumeric(sigma) && isvector(sigma) && isreal(sigma))
   error(message('Control:utility:dm2gm3'))
elseif (Na>1 && Ne>1 && Ne~=Na)
   error(message('Control:utility:dm2gm4'))
elseif Ne==1
   N = Na;
else
   N = Ne;
end

try
   if N==1
      [DGM,DPM] = localConvert(alpha,sigma);
   else
      DGM = zeros(N,2);
      DPM = zeros(N,2);
      for ct=1:N
         [DGM(ct,:),DPM(ct,:)] = ...
            localConvert(alpha(min(ct,Na)),sigma(min(ct,Ne)));
      end
   end
catch ME
   throw(ME)
end
   
if nargin==1
   DGM = DGM(:,2);   DPM = DPM(:,2);
end

%---------------------------
function [DGM,DPM] = localConvert(alpha,sigma)
% Scalar implementation
if alpha<0
   error(message('Control:utility:dm2gm1'))
elseif ~isfinite(sigma)
   error(message('Control:utility:dm2gm2'))
end

if isnan(alpha)
   DGM = NaN(1,2);
   DPM = NaN(1,2);
elseif isinf(alpha)
   DGM = [-Inf Inf];
   DPM = [-Inf Inf];
else
   % Gain margin
   B = (1+sigma)/2;
   gmin = 1-alpha/(1+B*alpha);
   gmax = 1+alpha/(1-B*alpha);
   if gmin>1
      gmin = -Inf;
   elseif abs(gmin)<sqrt(eps)
      % To avoid returning -eps due to rounding errors
      gmin = 0;
   end
   if gmax<1
      gmax = Inf;
   end
   DGM = [gmin,gmax];
         
   % Phase margin
   tau = alpha*sigma;
   if abs(tau)>=2
      % |alpha * sigma|<2 is equivalent to 
      % (1-gmin^2)*(1-gmax^2) = (1+gmin*gmax)^2-(gmin+gmax)^2 < 0
      PM = Inf;
   else
      % cos(PM) = (1+gmin*gmax)/(gmin+gmax)
      %         = (4-(alpha*sigma)^2 - alpha^2)/(4-(alpha*sigma)^2 + alpha^2)
      %         = (1 - t^2) / (1 + t^2)
      % tan(PM/2) = t = alpha / sqrt(4-(alpha*sigma)^2)
      PM = 2*atand(alpha/sqrt((2+tau)*(2-tau))); % (2+tau)*(2-tau)>0 from |tau|<2
   end
   DPM = [-PM PM];
end