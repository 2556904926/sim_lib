function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.
if isempty(blk.Ts_)
   fprintf('%s\n',getString(...
      message('Control:lftmodel:InvalidBlock','tunableSS')))
else
   ios = size(blk);
   if isct(blk)
      MsgID = 'Control:lftmodel:ltiblockSS10';
   else
      MsgID = 'Control:lftmodel:ltiblockSS11';
   end
   fprintf('%s\n',getString(message(MsgID,blk.Name)))
   fprintf('%s\n',getString(message('Control:lftmodel:ltiblockSS12',...
      ios(1),ios(2),order(blk),nparams(blk,'free'))))
   try
      showModelProperties(blk)
   end
   VarName = inputname(1);
   if isempty(VarName)
      VarName = 'ans';
   end
   fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockSS13',VarName)))
end
