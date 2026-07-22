function display(sys) %#ok<DISPLAY>
% Display for LTVSS models

%   Copyright 2022 The MathWorks, Inc.
Name = sys.Name;
Ts = sys.Ts;
if ~isempty(Name)
   disp(getString(message('Control:ltiobject:sparss15',Name)))
end
sizes = iosize(sys);
nx = order(sys);
np = nparam(sys);
if Ts==0
   disp(getString(message('Control:ltiobject:DispLPVSS1',sizes(1),sizes(2),nx,np)))
else
   disp(getString(message('Control:ltiobject:DispLPVSS2',sizes(1),sizes(2),nx,np)))
end
try
   showModelProperties(sys)
end
