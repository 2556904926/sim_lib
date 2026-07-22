function g=freqresp(a,b,c,d,iu,s)
%FREQRESP  Frequency response of dynamic systems.
%
%   [H,W] = FREQRESP(SYS) computes the frequency response H of the dynamic
%   system SYS at default frequencies W determined from the dynamics of the
%   model.
%
%   H = FREQRESP(SYS,W) explicitly specifies the frequency grid W. Frequency
%   values should be real and expressed in radians/TimeUnit (relative to the
%   time units specified in SYS.TimeUnit, the default being seconds).
%
%   H = FREQRESP(SYS,W,UNITS) explicitly specifies the frequency units of W.
%   The string UNITS must be among the following: 'rad/TimeUnit',
%   'cycles/TimeUnit', 'rad/s', 'Hz', 'kHz', 'MHz', 'GHz', or 'rpm'.
%
%   If SYS has NY outputs and NU inputs, and W contains NW frequencies, H is
%   a NY-by-NU-by-NW array and H(:,:,k) gives the response at the frequency
%   W(k). If SYS is a S1-by-...-Sp array of models with NY outputs and NU
%   inputs, then H is of size [NY NU NW S1 ... Sp].
%
%   For linear identified models (see IDLTI),
%      [H,W,covH] = FREQRESP(SYS,...)
%   also computes the covariance covH of the response H. This is a 5D-array
%   where covH(i,j,k,:,:) contains the 2-by-2 covariance matrix of the
%   response from i-th input to j-th output at frequency W(k). The (1,1)
%   element is the variance of the real part, the (2,2) element the variance
%   of the imaginary part and the (1,2) and (2,1) elements the covariance
%   between the real and imaginary parts.
%
%   Note: FREQRESP is optimized for medium-to-large vectors of frequencies.
%   Use EVALFR for a handful of frequencies.
%
%   See also DYNAMICSYSTEM/EVALFR, BODE, SIGMA, NYQUIST, NICHOLS,
%   DYNAMICSYSTEM, IDLTI.

% Old help
%warning(['This calling syntax for ' mfilename ' will not be supported in the future.'])
%FREQRESP Low level frequency response function.
%   G=FREQRESP(A,B,C,D,IU,S)
%   G=FREQRESP(NUM,DEN,S)
%   G=FREQRESP(Z,P,K,S)

%   Clay M. Thompson 7-10-90
%       Revised: AFP 9-10-94
%   Copyright 1986-2015 The MathWorks, Inc.

% For P-output, M-input systems, g=freqresp(a,b,c,d,1:m,s)
% returns an NS by M*P matrix.  Each row of this matrix 
% contains [H11 H21 ... Hp1 H12 H22 ... Hp2 ... Hpm]
% where Hij is the frequenct response from the j-th input
% to the i-th output.
% This format WILL change in future versions.  The right thing
% to output is a PxMxNS 3-D matrix.

ni = nargin;
if ni==3,
   % It is in transfer function form.   Do directly, using Horner's method
   % of polynomial evaluation at the frequency points, for each row in
   % the numerator.   Then divide by the denominator.
   ny = size(a,1);
   s = c(:);
   % Initialize g for minor performance improvement
   g = zeros(length(s),ny);
   for i=1:ny
      g(:,i) = polyval(a(i,:),s);
   end
   g = polyval(b,s)*ones(1,ny).\g;
elseif ni==4,
   % ZPK form
   s = d(:);
   z = a(:);
   p = b(:);
   k = c(:);
   nu = length(k);
   nx = length(p);
   % Pad Z if necessary so it has the same number of rows as p (i.e. #zeros==#poles)
   INF = Inf;
   z = [z; INF(ones(nx-size(z,1),nu))];
   nw = size(s,1);

   % Initialize g to be the gain
   onesNW = ones(1,nw);
   g = (k(:,onesNW)).';

   % Assume it's faster to loop over poles as opposed to frequency points
   s = s(:,ones(1,nu));
   for i=1:nx,
      tmp = s - z(i(onesNW,:),:);
      ind = isinf(tmp);
      tmp(ind) = ones(sum(sum(ind)),1);
      g = g.*tmp./(s - p(i));
   end

else
   % Reduce state space A matrix to Hessenberg form
   % Then directly evaluate frequency response.
   nx = size(a,1);
   s = s(:);
   nw = size(s,1);

   % Balance A
   [t,a] = balance(a);
   b = t \ b;
   c = c * t;
   
   % Reduce A to Hessenburg form
   [p,a] = hess(a);

   % Apply similarity transformations from Hessenberg reduction to B and C:
   if nx>0,
      b = p' * b;
      c = c * p;
      g = [];
      for i=iu,
         G = ltifr(a,b(:,i),s);
         g = [g (c*G + d(:,i(1,ones(1,nw)))).']; %#ok<AGROW>
      end
   else
      D = d(:,iu);
      D = D(:).';
      g = D(ones(1,nw),:);
   end
end

% end freqresp
