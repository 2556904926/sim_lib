function [DGM,DPM] = getDGM(GM,PM,METHOD)
%getDGM  Turn gain and phase margins into disk-based gain margin.
%
%   Gain and phase variations in feedback loops can be modeled as a 
%   multiplicative factor F(s) taking values in a disk D centered on the 
%   real axis. The disk-based gain margin DGM=[GMIN,GMAX] guarantees 
%   stability for all gain and phase variations in the disk D with 
%   real-axis intercepts GMIN,GMAX, which secures some amount of phase 
%   margin based on the disk geometry.
%
%   getDGM does the inverse mapping from desired gain and phase margins to 
%   disk-based gain margin DGM. It picks the disk intercepts GMIN and GMAX 
%   to tightly meet both gain and phase margin demands.
%
%   DGM = getDGM(GM,PM,'tight') computes the smallest disk that delivers 
%   the gain margin GM (in absolute value) and phase margin PM (in degrees). 
%   The interval DGM=[GMIN,GMAX] is the intersection of this disk with the 
%   real axis. The disk may have nonzero skew (see DISKMARGIN). Specify GM 
%   and PM as scalars, meaning that the gain can increase or decrease by a 
%   factor GM, and the phase can increase or decrease by PM in absolute 
%   value). Set GM=[] or PM=[] to remove one constraint.
%
%   DGM = getDGM(GM,PM,'balanced') computes the smallest disk with
%   GMIN=1/GMAX that delivers the margins GM and PM. This disk has zero
%   skew, meaning that the gain can increase or decrease by the same factor.
%
%   DGM = getDGM([GMIN,GMAX],[PMIN,PMAX],METHOD) specifies lower and upper
%   limits for the gain and phase margins. METHOD is either 'tight' or
%   'balanced'. Note that DGM may be larger than [GMIN,GMAX] due to the 
%   phase margin and 'balanced' constraints.
%
%   [DGM,DPM] = getDGM(...) also returns the (disk-based) phase margin DPM
%   corresponding to DGM and the fitted disk.
%
%   getDGM is vectorized and returns DGM of size N-by-2 when given N-ny-1 
%   or N-by-2 arrays.
%
%   Example: Compute balanced disk provides 6dB gain margin and 30 degrees 
%   phase margin.
%      GM = db2mag(6);
%      PM = 30;
%      [DGM,DPM] = getDGM(GM,PM,'balanced')
%      % Note: This disk provides effective margins of 6dB and 36 degrees.
%      diskmarginplot(DGM)
%
%   Example: Compute the smallest disk that models gain variations between
%   80% and 150% of the nominal value, and phase variations from -20 to
%   +40 degrees.
%      GVAR = [0.8 , 1.5];
%      PVAR = [-20 , 40];
%      [DGM,DPM] = getDGM(GVAR,PVAR,'tight')
%      diskmarginplot(DGM)
%
%   See also GETDPM, DISKMARGIN, DISKMARGINPLOT, WCDISKMARGIN, UMARGIN.

%   Copyright 2020 The MathWorks, Inc.
narginchk(3,3)

% Validate method
METHOD = ltipack.matchKey(METHOD,{'tight','balanced'});
if isempty(METHOD)
    error(message('Control:utility:getDGM1'))
end

% Validate data and handle shorcuts
if ~(isnumeric(GM) && isreal(GM) && isnumeric(PM) && isreal(PM))
   error(message('Control:utility:getDGM2'))
end
if isequal(GM,[])
   GM = [1 1];
elseif iscolumn(GM)
   if ~all(GM>0 & isfinite(GM))
      error(message('Control:utility:getDGM7'))
   end
   GM = max(GM,1./GM);
   GM = [1./GM , GM];
end
if isequal(PM,[])
   PM = [0 0];
elseif iscolumn(PM)
   if ~allfinite(PM)
      error(message('Control:utility:getDGM8'))
   end
   PM = abs(PM);
   PM = [-PM , PM];
end
[Ng,Mg] = size(GM);
[Np,Mp] = size(PM);
if Mg~=2 || Mp~=2
   error(message('Control:utility:getDGM2'))
elseif (Ng>1 && Np>1 && Ng~=Np)
   error(message('Control:utility:getDGM3'))
elseif Np==1
   N = Ng;
else
   N = Np;
end

% Fit disk
try
   if N==1
      DGM = localFitDisk(GM,PM,METHOD);
   else
      DGM = zeros(N,2);
      for ct=1:N
         DGM(ct,:) = localFitDisk(GM(min(ct,Ng),:),PM(min(ct,Np),:),METHOD);
      end
   end
catch ME
   throw(ME)
end

% Compute DPM
DPM = getDPM(DGM,false);  % skip validation


%---------------------------
function DGM = localFitDisk(GM,PM,METHOD)
% Scalar implementation
g1 = GM(1); g2 = GM(2);
p1 = PM(1); p2 = PM(2);
if ~(g1<=1 && g2>=1 && g1>-Inf && g2<Inf)
   error(message('Control:utility:getDGM4'))
elseif ~(p1<=0 && p2>=0)
   error(message('Control:utility:getDGM5'))
end   
   
switch METHOD
   case 'tight'
      % Compute optimal real-axis intercepts x,y for tight fit.
      % When g1>-1, these should minimize the disk radius (y-x)/2 subject to
      %    x<=g1, y>=g2, 1+x*y<=cos(PM)*(x+y)
      % where PM is the desired phase margin.
      if g1<=-1
         x = g1; y = g2;
      else
         PM = min(180,max(p2,-p1));
         c = cosd(PM);
         if 1+g1*g2<=c*(g1+g2)
            % (g1,g2) feasible
            x = g1; y = g2;
         else
            s = sind(PM);
            xT = c-s;  yT = c+s;
            if c<=0 || (g1>xT && g2>yT)
               x = (c*g2-1)/(g2-c);  y = g2;
            elseif g1<xT && g2<yT
               x = g1;  y = (c*g1-1)/(g1-c);
            else
               x = xT;  y = yT;
            end
         end
      end
      if x<y
         % Prevent SIGMA=Inf when x<y=1 or 1=x<y (see GM2DM)
         tol = 1e-4;
         x = min(x,1-tol);  
         y = max(y,1+tol);
      end
      DGM = [x,y];

   case 'balanced'
      % Constraints are
      %   1/y<=g1,  y>=g2,  2<=cos(PM)*(y+1/y)
      PM = max(p2,-p1);
      tau = tand(45-PM/2);
      if g1<=0 || tau<=0
         % Can't meet specs with balanced disk
         error(message('Control:utility:getDGM6'))
      end
      y = max([g2,1/g1,1/tau]);
      DGM = [1/y y];
end
         


