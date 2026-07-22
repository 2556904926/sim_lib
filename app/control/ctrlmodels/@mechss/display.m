function display(sys) %#ok<DISPLAY>
% Display for SPARSS models

%   Copyright 2020 The MathWorks, Inc.
Name = sys.Name;
Ts = sys.Ts;
if ~isempty(Name)
   disp(getString(message('Control:ltiobject:sparss15',Name)))
end
sizes = [iosize(sys) getArraySize(sys)];
nq = numq(sys);
if isempty(nq)
   nq = 0;
end
if prod(sizes(3:end))==1
   if Ts==0
      disp(getString(message('Control:ltiobject:mechss4c',sizes(1),sizes(2),nq)))
   else
      disp(getString(message('Control:ltiobject:mechss4d',sizes(1),sizes(2),nq)))
   end
else
   ArrayDims = sprintf('%dx',sizes(3:end));
   if Ts==0
      if all(nq(:)==nq(1))
         disp(getString(message('Control:ltiobject:mechss5c',...
            ArrayDims(1:end-1),sizes(1),sizes(2),nq(1))))
      else
         disp(getString(message('Control:ltiobject:mechss6c',...
            ArrayDims(1:end-1),sizes(1),sizes(2),min(nq(:)),max(nq(:)))))
      end
   else
      if all(nq(:)==nq(1))
         disp(getString(message('Control:ltiobject:mechss5d',...
            ArrayDims(1:end-1),sizes(1),sizes(2),nq(1))))
      else
         disp(getString(message('Control:ltiobject:mechss6d',...
            ArrayDims(1:end-1),sizes(1),sizes(2),min(nq(:)),max(nq(:)))))
      end
   end
end
try
   showModelProperties(sys)
end
disp(getString(message('Control:ltiobject:mechss3')))
