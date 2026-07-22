function display(sys)
%DISPLAY   Pretty-print for PIDSTD object.
%
%   DISPLAY(SYS) is invoked by typing SYS followed
%   by a carriage return.  DISPLAY produces a custom
%   display for PIDSTD object.
%
%   See also LTIMODELS.

% Author(s): Rong Chen 10-Nov-2009
%   Copyright 2009-2011 The MathWorks, Inc.
Data = sys.Data_;
StaticFlag = isstatic(sys);

% Get variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

% Get number of models in array
ArraySizes = size(Data);
nsys = numel(Data);
if nsys>1
    % Construct sequence of indexing coordinates
    indices = zeros(nsys,length(ArraySizes));
    for k=1:length(ArraySizes)
        range = 1:ArraySizes(k);
        base = repmat(range,[prod(ArraySizes(1:k-1)) 1]);
        indices(:,k) = repmat(base(:),[nsys/numel(base) 1]);
    end
end
ArrayDims = sprintf('%dx',ArraySizes);

if any(ArraySizes==0)
   fprintf('\n%s =\n\n  %s\n\n',VarName,...
      ctrlMsgUtils.message('Control:ltiobject:pidstdDisplayArray1',ArrayDims(1:end-1)));
elseif nsys==1
   % Single PID
   fprintf('\n%s =\n',VarName)
   dispsys(Data,'  ')
   % System name and sample time
   dispTs(sys,StaticFlag);
   % Last line
   if StaticFlag
      MsgID = 'Control:ltiobject:pOnlyDisplay';
   elseif Data.Ts==0
      MsgID = sprintf('Control:ltiobject:pidstdDisplayType%s1',getType(Data));
   else
      MsgID = sprintf('Control:ltiobject:pidstdDisplayType%s2',getType(Data));
   end
   fprintf('%s\n',getString(message(MsgID)))
else
   % PID array
   G = sys.SamplingGrid;
   for k=1:nsys
      ltipack.dispHeader(VarName,indices(k,:),G)
      dispsys(Data(k),'  ');
   end
   % System name and sample time
   dispTs(sys,StaticFlag);
   % Last line
   if StaticFlag
      MsgID = 'Control:ltiobject:pOnlyDisplayArray';
   elseif Data(1).Ts==0
      MsgID = 'Control:ltiobject:pidstdDisplayArray2';
   else
      MsgID = 'Control:ltiobject:pidstdDisplayArray3';
   end
   fprintf('%s\n',getString(message(MsgID,ArrayDims(1:end-1))))
end

try
   showModelProperties(sys)
end
