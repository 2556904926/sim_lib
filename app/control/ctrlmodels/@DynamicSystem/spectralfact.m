function [G,S] = spectralfact(H,varargin)
%SPECTRALFACT  Spectral factorization of linear systems.
%
%   [G,S] = SPECTRALFACT(H) takes a para-Hermitian LTI model H (H=H') and
%   computes the spectral factorization
%       H = G' * S * G
%   where S is a symmetric matrix and G is a square, stable, and
%   minimum-phase system with unit (identity) feedthrough.
%
%   [G,S] = SPECTRALFACT(F,R) handles the case when H is specified in
%   factored form as H = F' * R * F. The spectral factorization is then
%   computed without explicitly forming H.
%
%   G = SPECTRALFACT(F,[]) computes a stable, minimum-phase system G such
%   that F'*F = G'*G.
%
%   The following restrictions apply:
%     * In continuous time, H(s) should have no poles or zeros at infinity
%       (bi-proper) or on the imaginary axis
%     * In discrete time, H(z) should have no poles or zeros on the unit
%       circle.
%
%   See also DynamicSystem/ctranspose, numlti.

%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(1,2)
if nmodels(H)>1
   error(message('Control:general:RequiresSingleModel','spectralfact'))
end

[ny,nu] = iosize(H);
if nargin>1
   % SPECTRALFACT(F,R)
   R = varargin{1};
   if ny<nu
      % F'*R*F is rank-deficient at all frequencies if F is wide
      error(message('Control:transformation:SpectralFact5'))
   elseif ~isequal(R,[])
      if ~(isnumeric(R) && isequal(size(R),[ny ny]) && allfinite(R))
         error(message('Control:transformation:SpectralFact11'))
      elseif norm(R-R',1)>1e3*eps*norm(R,1)
         error(message('Control:transformation:SpectralFact12'))
      end
      varargin{1} = (R+R')/2;
   end
else
   % SPECTRALFACT(H)
   if ny~=nu
      error(message('Control:transformation:SpectralFact3'))
   end
end
   
% Perform factorization
try
   [G,S] = spectralfact_(H,varargin{:});
catch E
   ltipack.throw(E,'command','spectralfact',class(H))
end

% Clear notes, userdata, etc
G.OutputName = [];  G.OutputUnit = [];  G.OutputGroup = [];
G.Name = '';  G.Notes = {};  G.UserData = [];