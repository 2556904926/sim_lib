function G = modalsum(H,H0)
%MODALSUM  Sum of modal components.
%
%   G = MODALSUM(H,H0) takes an array H models and a static gain H0 and 
%   returns the sum
%
%      G(s) = H0 +  sum   Hj(s)
%                  j=1:N
%
%   where Hj = H(:,:,j) are the models in the array H. MODALSUM is useful 
%   to sum up a subset of the modal components computed by MODALSEP. A 
%   missing H0 is interpreted as H0=0.
%
%   Example 1: Compute the modal decomposition of a 10th-order state-space
%   model and retain only modal components with a relative DC contribution
%   of more than 10%:
%      rng(0), G = rss(10,2,2);
%      [H,H0,INFO] = modalsep(G)
%      Gr = modalsum(H(:,:,INFO.DCGain>0.1),H0)
%      bode(G,Gr)
%
%   See also MODALSEP, MODALREAL, LTI.

%   Copyright 2023 The MathWorks, Inc.
if nargin>1
   if isequal(size(H0),iosize(H))
      % Simple way to align type, sample time, etc.
      H = stack(1,H(:,:,:),H0);
   else
      error(message('Control:transformation:modalsum2'))
   end
end
try
   G = modalsum_(H);
catch ME
   throw(ME)
end
% Clear notes, userdata, etc
G.Name = '';  G.Notes = {};  G.UserData = [];
