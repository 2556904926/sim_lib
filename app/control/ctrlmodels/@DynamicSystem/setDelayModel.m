function sys = setDelayModel(H,tau)
%SETDELAYMODEL  Constructs models with internal delays.
%
%   SETDELAYMODEL is the converse of GETDELAYMODEL and lets you construct
%   models with internal delays as the LFT connection of delay-free
%   dynamics with pure delays. See GETDELAYMODEL for more details on the
%   LFT-based representation of internal delays. SETDELAYMODEL is an
%   advanced operation and is not the natural way to construct models with
%   internal delays.
%
%   SYS = SETDELAYMODEL(A,B1,B2,C1,C2,D11,D12,D21,D22,TAU) constructs the
%   state-space model SYS defined by the matrices A,B1,B2,... and the
%   vector of internal delays TAU (expressed in seconds). The resulting
%   model is continuous and can be made discrete by modifying its sample
%   time.
%
%   SYS = SETDELAYMODEL(H,TAU) returns the LFT interconnection SYS of the
%   the state-space model H with the vector of pure delays TAU (expressed 
%   in the time units of H). When H is delay free, the delays TAU become
%   the internal delays of SYS. The model H can be SS, SPARSS, or MECHSS.
%
%   See also GETDELAYMODEL, SS, SPARSS, MECHSS.

%   Author(s): P. Gahinet
%   Copyright 1986-2020 The MathWorks, Inc.
narginchk(2,2)
if ~(isnumeric(tau) && isvector(tau) && isreal(tau) && all(tau>=0 & tau<Inf))
   error(message('Control:ltiobject:setDelayModel1'))
end

% Check size compatibility
[ny,nu] = iosize(H);
nfd = numel(tau);
if ny<=nfd || nu<=nfd
   error(message('Control:ltiobject:setDelayModel3'))
end

% Build model
try
   tau = full(double(tau(:)));
   tau = ltipack.util.checkInternalDelay(tau,H.Ts);
   sys = setDelayModel_(H,tau);
   sys = lftMetaData(sys,H,ss(eye(nfd)),nu-nfd+1:nu,ny-nfd+1:ny,1:nfd,1:nfd);
catch ME
   throw(ME)
end