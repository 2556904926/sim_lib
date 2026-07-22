function varargout = gainsurfdata(M,ID)
%GAINSURFDATA   Get values of gain surface coefficients.
%
%   For a gain surface
%      K(SV) = K0 + K1 * F1(SV) + ... + KM * FM(SV)
%   created with GAINSURF,
%      [K0,K1,K2,...] = GAINSURFDATA(K)
%   returns the current values of the surface coefficients K0,...,KM.
%   See GAINSURF for more details.
%
%   If a generalized model M depends on a gain surface K with name KNAME,
%   you can retrieve the coefficients of K directly from M using
%      [K0,K1,K2,...] = GAINSURFDATA(M,KNAME)
%   For example, if M models the gain-scheduled PI loop:
%      Kp = gainsurf('Kp',1,F1,F2,...)
%      Ki = gainsurf('Ki',0.1,F1,F2,...)
%      M = feedback(G*pid(Kp,Ki),1)
%   you can retrieve the coefficients of Kp and Ki from M using
%      [Kp0,Kp1,Kp2,...] = gainsurfdata(M,'Kp')
%      [Ki0,Ki1,Ki2,...] = gainsurfdata(M,'Ki')
%
%   Note: Make sure to use the same formula and variables when specifying
%   the gain surface and when implementing the corresponding gain schedule. 
%   If you used normalized scheduling variables to define the gain surface,
%   make sure to apply the same normalization when implementing it.
%
%   See also GAINSURF, GETBLOCKVALUE.

%   Author(s): P. Gahinet, 5-1-96
%   Copyright 1986-2011 The MathWorks, Inc.
narginchk(1,2)
if ~(isa(M,'ltipack.LFTModelArray') && isParametric(M))
   error(message('Control:tuning:gainsurfdata1'))
end
B = M.Blocks;
BN = fieldnames(B);
BV = struct2cell(B);

% Locate relevant blocks
if nargin<2
   % M must be a gain surface
   c = regexp(BN{1},'(.+_)\d+$','tokens');
   if isempty(c)
      error(message('Control:tuning:gainsurfdata2'))
   end
   ID = c{1}{1};
   ncoeff = numel(BN);
else
   % Find blocks related to gain surface
   if ~isvarname(ID)
      error(message('Control:tuning:gainsurfdata3'))
   end
   ID = [ID '_'];
   Pattern = ['^' regexptranslate('escape',ID) '(\d+)$'];
   ncoeff = sum(~cellfun('isempty',regexp(BN,Pattern)));
end

% Look for block sequence ID_0,ID_1,ID_2,...
[~,loc] = ismember(strseq(ID,0:ncoeff-1),BN);
if ncoeff>0 && all(loc>0)
   BN = BN(loc);
   BV = BV(loc);
else
   BlockSeq = [ID '0, ' ID '1, ' ID '2,...'];
   error(message('Control:tuning:gainsurfdata4',BlockSeq))
end

% Get block values
for ct=1:ncoeff
   if isa(BV{ct},'realp')
      BV{ct} = BV{ct}.Value;
   else
      error(message('Control:tuning:gainsurfdata5',BN{ct}))
   end
end

no = max(1,nargout);
if no>numel(BV)
   error(message('Control:tuning:gainsurfdata6',ID))
else
   varargout = BV(1:no);
end
