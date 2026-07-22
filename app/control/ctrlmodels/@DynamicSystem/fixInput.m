function sys = fixInput(sys,indices,values)
%fixInput  Fix value of some inputs and delete them.
%
%   For state-space models with offsets (SS,SPARSS,LTVSS,LPVSS), SYS(:,J)
%   discards all inputs not listed in J by fixing their value to zero.
%   This is appropriate, for example, when dropping noise or disturbance
%   inputs from a closed-loop model. When operating around a trajectory or
%   trim condition, however, discarded inputs must be held at their trim
%   value to maintain the desired operating condition. You can then use
%   fixInput to assign nonzero values to the discarded inputs.
%
%   SYS = fixInput(SYS,J,UJ) fixes the J-th input to the value UJ and
%   deletes it.
%
%   SYS = fixInput(SYS,J,'u0') equates the J-th input with the J-th entry
%   of the input offset u0, u0(t), or u0(t,p) specified in the model. When
%   u0 is the input level to achieve steady state or follow a given
%   trajectory, this syntax is useful to maintain the system in the desired
%   operating regime while manipulating the remaining inputs.
%
%   SYS = fixInput(SYS,INDICES,VALUES) fixes and deletes several inputs at
%   once. For example
%      sys = fixInput(sys,[1 3],[-0.5 0.7])   % set u(1)=-0.5, u(2)=0.7
%      sys = fixInput(sys,[2 3],'u0')         % set u([2 3])=u0([2 3])
%      sys = fixInput(sys,[1 3],{-0.5,'u0'})  % set u(1)=-0.5, u(2)=u0(2)
%
%   See also SS, SPARSS, LTVSS, LPVSS, IOSIZE.

%   Copyright 2022 The MathWorks, Inc.
narginchk(3,3)
[~,nu] = iosize(sys);

% Validate INDICES
indices = indices(:);
ndel = numel(indices);
if ~(isnumeric(indices) && all(indices>0 & indices==round(indices) & indices<=nu))
   error(message('Control:ltiobject:fixInput1'))
elseif numel(unique(indices))<ndel
   error(message('Control:ltiobject:fixInput2'))
end

% Format VALUES
isU0 = @(x) ((ischar(x) && isrow(x)) || (isstring(x) && isscalar(x))) && strcmp(x,'u0');
if isnumeric(values)
   values = num2cell(values(:));
elseif isU0(values)
   values = {'u0'};
elseif iscell(values)
   if ~all(cellfun(@(x) isU0(x) || (isnumeric(x) && isscalar(x)),values))
      error(message('Control:ltiobject:fixInput3'))
   end
   values = values(:);
else
   error(message('Control:ltiobject:fixInput3'))
end
if isscalar(values)
   values = repmat(values,[ndel 1]);
elseif numel(values)~=ndel
   error(message('Control:ltiobject:fixInput4'))
end

% Fix input value and discard
try
   sys = fixInput_(sys,indices,values);
catch ME
   ltipack.throw(ME,'command','fixInput',class(sys))
end
colIndex = 1:nu;  colIndex(:,indices) = [];
sys = parenReferenceMetaData(sys,':',colIndex);
sys.IOSize_(2) = nu-ndel;

