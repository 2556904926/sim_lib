function display(sys)
%DISPLAY   Pretty-print for SS models.

%   Copyright 1986-2022 The MathWorks, Inc.

% Extract state-space data and sampling/delay times
Data = sys.Data_;
Inames = sys.InputName;
Onames = sys.OutputName;
TimeUnit = sys.TimeUnit;

% Get variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

% Get number of models in array
[Ny,Nu] = iosize(sys);
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

% Use ISSTATIC to account for delays
StaticFlag = isstatic(sys);

% Handle various types
if any(ArraySizes==0) || ((Ny==0 || Nu==0) && StaticFlag)
   fprintf('\n%s =\n\n  %s\n\n',VarName,...
      getString(message('Control:ltiobject:DispSS4')))
else
   if nsys==1
      % Single SS model
      fprintf('\n%s =\n',VarName)
      dispsys(Data,Inames,Onames,TimeUnit,'  ')
      % Metadata
      dispGroup(sys);
      % System name and sample time
      dispTs(sys,StaticFlag);
      % Last line
      if StaticFlag
         if isempty(sys.Offsets)
            MsgID = 'Control:ltiobject:DispGain';
         else
            MsgID = 'Control:ltiobject:DispGainOffset';
         end
      elseif Data.Ts==0
         if isempty(sys.Offsets)
            MsgID = 'Control:ltiobject:DispSS5';
         else
            MsgID = 'Control:ltiobject:DispSS5Offset';
         end
      else
         if isempty(sys.Offsets)
            MsgID = 'Control:ltiobject:DispSS6';
         else
            MsgID = 'Control:ltiobject:DispSS6Offset';
         end
      end
      fprintf('%s\n',getString(message(MsgID)))
   else
      % SS array
      G = sys.SamplingGrid;
      for k=1:nsys
         ltipack.dispHeader(VarName,indices(k,:),G)
         dispsys(Data(k),Inames,Onames,TimeUnit,'  ')
      end
      % Metadata
      dispGroup(sys);
      % System name and sample time
      dispTs(sys,StaticFlag);
      % Last line
      ArrayDims = sprintf('%dx',ArraySizes);
      if StaticFlag
         MsgID = 'Control:ltiobject:DispGainArray';
      elseif Data(1).Ts==0
         MsgID = 'Control:ltiobject:DispSS9';
      else
         MsgID = 'Control:ltiobject:DispSS10';
      end
      fprintf('%s\n',getString(message(MsgID,ArrayDims(1:end-1))))
   end
   try
      showModelProperties(sys)
   end
end

