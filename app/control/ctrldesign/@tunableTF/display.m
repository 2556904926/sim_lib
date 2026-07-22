function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.
if isempty(blk.Ts_)
   fprintf('%s\n',getString(...
      message('Control:lftmodel:InvalidBlock','tunableTF')))
else
   if isct(blk)
      MsgID = 'Control:lftmodel:ltiblockTF12';
   else
      MsgID = 'Control:lftmodel:ltiblockTF13';
   end
   fprintf('%s\n',getString(message(MsgID,blk.Name)))
   fprintf('%s\n',getString(message('Control:lftmodel:ltiblockTF14',...
      blk.Nz_,blk.Np_,nparams(blk,'free'))));
   try
      showModelProperties(blk)
   end
   VarName = inputname(1);
   if isempty(VarName)
      VarName = 'ans';
   end
   fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockTF15',VarName)))
end
