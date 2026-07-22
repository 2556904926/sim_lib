function Xlim = getFreqLims(Xlim,Focus,Ts,wc)
% Derives X limits based on auto-focus limits and frequency focus.

%   Copyright 2009-2016 The MathWorks, Inc.
Focus = [0.9*Focus(1) , min(1.1*Focus(2),pi/Ts)];
if nargin>3 && ~isempty(wc)
   Xlim(1) = min(wc(1)/30,max(Xlim(1),wc(1)/300));
   Xlim(2) = max(30*wc(end),min(Xlim(2),300*wc(end)));
end

% Combine XLIM and FOCUS
A = (Focus(1)<Xlim(1));
B = (Focus(2)>Xlim(2));
if A && B
   % Keep Xlim if entirely contained in Focus
   Focus = Xlim;
elseif A
   % Focus(1)<Xlim(1) and Focus(2)<=Xlim(2): Increase Focus(1) if possible
   Focus(1) = max(Focus(1),min(Xlim(1),Focus(2)/1e3));
elseif B
   % Focus(1)>=Xlim(1) and Focus(2)>Xlim(2): Decrease Focus(2) if possible
   Focus(2) = min(Focus(2),max(Xlim(2),1e3*Focus(1)));
%else: Keep Focus if entirely contained in Xlim
end

% Round to entire decades
Xlim = 10.^[floor(log10(Focus(1))) , ceil(log10(Focus(2)))];