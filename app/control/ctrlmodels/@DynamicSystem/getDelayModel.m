function varargout = getDelayModel(sys,varargin)
%GETDELAYMODEL  State-space representation of internal delays.
%
%   State-space models with internal delays are represented by 
%   differential-algebraic equations of the form:
%      E dx/dt =  A x +  B1 u +  B2 w
%           y  = C1 x + D11 u + D12 w
%           z  = C2 x + D21 u + D22 w
%         w(t) = z(t - tau)
%   or their discrete-time counterparts:
%      E x[k+1] =  A x[k] +  B1 u[k] +  B2 w[k]
%         y[k]  = C1 x[k] + D11 u[k] + D12 w[k]
%         z[k]  = C2 x[k] + D21 u[k] + D22 w[k]
%         w[k]  = z[k - tau]
%   where u,y are the external inputs and outputs, and tau is the vector of 
%   internal delays. These equations correspond to the block diagram:
%
%                    +--------+
%          u ------->|        |-------> y
%                    |  H(s)  |
%             +----->|        |-----+
%             |      +--------+     |
%          w  |                     | z
%             |   +-------------+   |
%             +<--| exp(-tau*s) |<--+
%                 +-------------+   
%
%   where H(s) is the delay-free state-space model mapping [u;w] to [y;z].
%
%   [H,TAU] = GETDELAYMODEL(SYS) returns the state-space model H and vector 
%   TAU of internal delays making up the block diagram above. TAU is expressed
%   in the time units of H.
%
%   [A,B1,B2,C1,C2,D11,D12,D21,D22,E,TAU] = GETDELAYMODEL(SYS) returns the
%   matrices A,B1,B2,... and vector TAU of internal delays for the 
%   state-space model SYS (see SS and DSS). The E matrix is set to [] for 
%   explicit models with no E matrix.
% 
%   Note that for models without internal delays:
%     * only A,B1,C1,D11 (and possibly E) are non-empty 
%     * TAU is empty and H is equal to SYS.
%
%   See also SS, DSS, DELAYSS, SPARSS, MECHSS, SETDELAYMODEL.

%   Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.
if nmodels(sys)~=1
   error(message('Control:general:RequiresSingleModel','getDelayModel'))
end

% Extract delay model
[ny,nu] = iosize(sys);
try
   [H,tau] = getDelayModel_(sys);
catch ME
   throw(ME)
end
nfd = numel(tau);
H.IOSize_ = [ny+nfd , nu+nfd];
% Resize Unit property
if ~isempty(sys.InputUnit_)
   H.InputUnit_ = [sys.InputUnit_ ; strings(nfd,1)];
end
if ~isempty(sys.OutputUnit_)
   H.OutputUnit_ = [sys.OutputUnit_ ; strings(nfd,1)];
end
% Name additional signals wj and zj
wstr = "w" + (1:nfd)';
if nfd>0 && isempty(intersect(wstr,sys.InputName_))
   H.InputName_ = [ltipack.fullstring(sys.InputName_,nu) ; wstr];
end
zstr = "z" + (1:nfd)';
if nfd>0 && isempty(intersect(zstr,sys.OutputName_))
   H.OutputName_ = [ltipack.fullstring(sys.OutputName_,ny) ; zstr];
end

if nargout<3
   varargout = {H , tau};
elseif isa(H,'mechss')
   error(message('Control:ltiobject:getDelayModel3'))
else
   A = H.A;  B = H.B;  C = H.C;  D = H.D;   E = H.E;
   B1 = B(:,1:nu);  B2 = B(:,nu+1:nu+nfd);
   C1 = C(1:ny,:);  C2 = C(ny+1:ny+nfd,:);
   D11 = D(1:ny,1:nu);  D12 = D(1:ny,nu+1:nu+nfd);
   D21 = D(ny+1:ny+nfd,1:nu);  D22 = D(ny+1:ny+nfd,nu+1:nu+nfd);
   varargout = {A,B1,B2,C1,C2,D11,D12,D21,D22,E,tau};
end
