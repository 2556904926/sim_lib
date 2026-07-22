function DPM = getDPM(DGM,~)
%getDPM  Compute phase margin corresponding to given gain margin.
%
%   DPM = getDPM(DGM) computes the (disk-based) phase margin DPM
%   corresponding to the (disk-based) gain margin DGM (see DISKMARGIN). 
%   Specify DGM as [GMIN,GMAX] with GMIN<1 and GMAX>1 in absolute units. 
%   For example, DGM=[0.5,3] means that the gain can change between 
%   50% and 300% of its nominal value. The phase margin DPM is in degrees.
%
%   For scalar GM, getDPM(GM) is the same as getDPM([1/GM,GM]).
%
%   When DGM has multiple rows, getDPM computes the phase margin for
%   each row.
%
%   Example: Compute the phase margin corresponding to a disk-based gain 
%   margin of 6dB:
%      DGM = db2mag(6);
%      DPM = getDPM(DGM)
%
%   Example: Compute the phase margin corresponding to the disk-based gain 
%   margin DGM = [0.3 2]
%      DPM = getDPM([0.3 2])
%
%   See also GETDGM, DISKMARGIN, DISKMARGINPLOT, WCDISKMARGIN, UMARGIN.

%   Copyright 2020 The MathWorks, Inc.
narginchk(1,2)
VALIDATE = (nargin<2);
if VALIDATE
   if ~(isnumeric(DGM) && isreal(DGM))
      error(message('Control:utility:gm2dm1'))
   end
   if iscolumn(DGM)
      DGM = [1./DGM , DGM];
   elseif ~(ismatrix(DGM) && size(DGM,2)==2)
      error(message('Control:utility:gm2dm2'))
   end
end
gmin = DGM(:,1);
gmax = DGM(:,2);
if VALIDATE && ~all(gmin<=1 & gmax>=1 & gmin>-Inf & gmax<Inf)
   error(message('Control:utility:getDGM4'))
end
N = size(DGM,1);
DPM = Inf(N,1);
ix = find(gmin>-1);
gmin = gmin(ix);
gmax = gmax(ix);
DPM(ix) = acosd((1+gmin.*gmax)./(gmin+gmax));
DPM = [-DPM,DPM];