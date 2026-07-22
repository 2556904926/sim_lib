function display(sys) %#ok<DISPLAY>
% Display for SPARSS models

%   Copyright 2020 The MathWorks, Inc.
Name = sys.Name;
Ts = sys.Ts;
if ~isempty(Name)
   disp(getString(message('Control:ltiobject:sparss15',Name)))
end
sizes = [iosize(sys) getArraySize(sys)];
nx = order(sys);
if isempty(nx)
   nx = 0;
end
if prod(sizes(3:end))==1
   if Ts==0
      disp(getString(message('Control:ltiobject:sparss16c',sizes(1),sizes(2),nx)))
   else
      disp(getString(message('Control:ltiobject:sparss16d',sizes(1),sizes(2),nx)))
   end
else
   ArrayDims = sprintf('%dx',sizes(3:end));
   if Ts==0
      if all(nx(:)==nx(1))
         disp(getString(message('Control:ltiobject:sparss17c',...
            ArrayDims(1:end-1),sizes(1),sizes(2),nx(1))))
      else
         disp(getString(message('Control:ltiobject:sparss18c',...
            ArrayDims(1:end-1),sizes(1),sizes(2),min(nx(:)),max(nx(:)))))
      end
   else
      if all(nx(:)==nx(1))
         disp(getString(message('Control:ltiobject:sparss17d',...
            ArrayDims(1:end-1),sizes(1),sizes(2),nx(1))))
      else
         disp(getString(message('Control:ltiobject:sparss18d',...
            ArrayDims(1:end-1),sizes(1),sizes(2),min(nx(:)),max(nx(:)))))
      end
   end
end
try
   showModelProperties(sys)
end
disp(getString(message('Control:ltiobject:sparss14')))
