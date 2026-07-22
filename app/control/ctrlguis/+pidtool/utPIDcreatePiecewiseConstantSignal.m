function out = utPIDcreatePiecewiseConstantSignal(breakpoints, offset, starttime, onsettime, sampletime, endtime)
%utPIDcreatePiecewiseConstantSignal build a piecewise constant signal.

% Copyright 2013 The MathWorks, Inc.
time = breakpoints(:,1) + onsettime;
time = ceil(time/sampletime)*sampletime;

% lose time-stamps greater than the end time
i = (time > endtime);
if any(i)
    time(i) = [];
    breakpoints(i,:) = [];
end

tol = sqrt(eps);
value = breakpoints(:,2);
Ns = floor((time(end)-time(1))/sampletime)+1;
u_ = ones(Ns,1)*value(end);
t_ = time(1)+sampletime*(0:(Ns-1))';

for i = 1:length(time)-1
    u_(t_>=time(i)-tol & (t_<time(i+1)+tol)) = value(i);
end

I = t_>endtime;
t_(I) = []; u_(I) = [];

% Implement boundary conditions:
% u(t<time(1)) = 0 and u(t>=time(end)) = value(end)

t = (starttime:sampletime:endtime)';
u = zeros(numel(t),1);
if Ns>0
    u(t >= (t_(1)-tol)  &  t <= (t_(end)+tol)) = u_;
    u(t > t_(end)+tol) = value(end);
else
    u(t>=time(1)-tol) = value(end);
end
u = u+offset;

ts = timeseries(u,t);
ts.DataInfo.Interpolation = tsdata.interpolation.createZOH;
out = setuniformtime(ts, 'Interval', sampletime, 'StartTime', t(1));
