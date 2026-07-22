function display(sys)
%DISPLAY   Pretty-print for LTI models.
%
%   DISPLAY(SYS) is invoked by typing SYS followed
%   by a carriage return.  DISPLAY produces a custom
%   display for each type of LTI model SYS.
%
%   See also LTIMODELS.

%   Author(s): A. Potvin, P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.

CWS = matlab.desktop.commandwindow.size;      % max number of char. per line
LineMax = round(.8*CWS(1));
Inames = sys.InputName;
Onames = sys.OutputName;
StaticFlag = isstatic(sys);
Data = sys.Data_;

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

% Handle various cases
if Ny==0 || Nu==0 || any(ArraySizes==0)
   fprintf('\n%s =\n\n  %s\n\n',VarName,...
      getString(message('Control:ltiobject:DispTF1')))
   
elseif nsys==1
   % Single TF model
   fprintf('\n%s =\n',VarName)
   dispsys(Data,Inames,Onames,LineMax,'  ',sys.Variable)
   % Metadata
   dispGroup(sys);
   % System name and sample time
   dispTs(sys,StaticFlag);
   % Last line
   if StaticFlag
      MsgID = 'Control:ltiobject:DispGain';
   elseif Data.Ts==0
      MsgID = 'Control:ltiobject:DispTF8';
   else
      MsgID = 'Control:ltiobject:DispTF9';
   end
   fprintf('%s\n',getString(message(MsgID)))
else
   % TF array
   G = sys.SamplingGrid;
   for k=1:nsys
      ltipack.dispHeader(VarName,indices(k,:),G)
      dispsys(Data(k),Inames,Onames,LineMax,'  ',sys.Variable);
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
      MsgID = 'Control:ltiobject:DispTF10';
   else
      MsgID = 'Control:ltiobject:DispTF11';
   end
   fprintf('%s\n',getString(message(MsgID,ArrayDims(1:end-1))))
end

try
   showModelProperties(sys)
end
