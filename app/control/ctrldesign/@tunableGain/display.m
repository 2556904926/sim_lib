function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.
if isempty(blk.Ts_)
   fprintf('%s\n',getString(...
      message('Control:lftmodel:InvalidBlock','tunableGain')))
else
   ios = iosize(blk);
   ModelInfo = getString(message('Control:lftmodel:ltiblockGain6',...
      blk.Name,ios(1),ios(2),nparams(blk,'free')));
   VarName = inputname(1);
   if isempty(VarName)
      VarName = 'ans';
   end
   fprintf('%s\n',ModelInfo)
   try
      showModelProperties(blk)
   end
   FootNote = getString(message('Control:lftmodel:ltiblockSS13',VarName));
   fprintf('\n%s\n',FootNote)
end
