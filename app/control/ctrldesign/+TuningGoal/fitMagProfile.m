function WF = fitMagProfile(w,mag)
% Computes weighting function that approximately fits specified magnitude
% profile.
%
% The frequency values W must be nonnegative, sorted, and expressed in 
% rad/TimeUnit. The magnitude values MAG must be positive and finite.

% Copyright 2009-2013 The MathWorks, Inc.
if isequal(w,[0,Inf])
   % Uniform gain constraint on [0,Inf]
   WF = zpk(sqrt(mag(1)*mag(2)));  return
end

% Below W contains at least one positive and finite frequency and all MAG
% values are finite. Deal with W(1)=0 and W(end)=Inf
nf = numel(w);
if w(1)==0
   w(1) = 1e-3 * w(2);
end
if isinf(w(nf))
   w(nf) = 1e3 * w(nf-1);
end

% Compute slopes and round to nearest integer
logw = log10(w(:));
logmag = log10(mag(:));
slopes = round(diff(logmag)./diff(logw));

% Reduce to a sequence of supporting lines with different slopes
ichg = find([1 ; diff(slopes) ; 1]);  % indices of points where slope changes
nseg = numel(ichg)-1;
a = zeros(nseg,1);  b = zeros(nseg,1); 
for ct=1:nseg
   % Fit line y=a*x+b through points ichg(ct),...,ichg(ct+1)
   ind = ichg(ct):ichg(ct+1);
   a(ct) = slopes(ichg(ct));  % slope
   b(ct) = mean(logmag(ind)-a(ct)*logw(ind));  % y intercept
end

% Visualize supporting lines
% figure(1),clf
% loglog(w,mag,'rx')
% hold
% f = logspace(log10(w(1)),log10(w(end)),30);
% for ct=1:nseg
%    loglog(f,10^b(ct)*f.^a(ct),'b--')
% end

% Pick poles and zeros based on slopes and break point locations
delta = diff(a);             % slope variations
wb = 10.^(-diff(b)./delta);  % break points
% Initial slope
z = zeros(a(1),1);  
p = zeros(-a(1),1);  
k = 10^b(1);
% Add poles and zeros to effect slope changes
for ct=1:nseg-1
   z = [z ; repmat(-wb(ct),[delta(ct) 1])]; %#ok<*AGROW>
   p = [p ; repmat(-wb(ct),[-delta(ct) 1])];
end
k = k * prod(wb.^(-delta));
WF = zpk(z,p,k);

% Check fit
% m = bode(WF,f);
% loglog(f,m(:),'r')
   
