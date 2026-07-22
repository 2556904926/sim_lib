function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.

% Variable name
Ts = blk.Ts_;
if isempty(Ts)
   fprintf('%s\n',getString(...
      message('Control:lftmodel:InvalidBlock','tunablePID')))
else
   if Ts==0
      MsgID = 'Control:lftmodel:ltiblockPID7c';
   else
      MsgID = 'Control:lftmodel:ltiblockPID7d';
   end
   fprintf('%s\n\n',getString(message(MsgID,blk.Name)))
   
   % Display formula
   StrI = ltipack.piddata.utGetStrI(Ts,blk.IFormula);
   StrD = ltipack.piddata.utGetStrD_Parallel(Ts,blk.DFormula);
   switch getType(blk)
      case 'P'
         disp(' ');
         disp('  Kp');
         disp(' ');
      case 'PI'
         disp([blanks(12) StrI(1,:)]);
         disp(['  Kp + Ki * ' StrI(2,:)]);
         disp([blanks(12) StrI(3,:)]);
      case 'PD'
         disp([blanks(12) StrD(1,:)]);
         disp(['  Kp + Kd * ' StrD(2,:)]);
         disp([blanks(12) StrD(3,:)]);
      case 'PID'
         disp([blanks(12) StrI(1,:) blanks(8) StrD(1,:)]);
         disp(['  Kp + Ki * ' StrI(2,:) ' + Kd * ' StrD(2,:)]);
         disp([blanks(12) StrI(3,:) blanks(8) StrD(3,:)]);
   end
   
   % Display tunable parameters
   TG = '';
   if blk.Kp.Free
      TG = [TG , 'Kp, '];
   end
   if blk.Ki.Free
      TG = [TG , 'Ki, '];
   end
   if blk.Kd.Free
      TG = [TG , 'Kd, '];
   end
   if (blk.Kd.Free || blk.Kd.Value~=0) && blk.Tf.Free
      TG = [TG , 'Tf, '];
   end
   if isempty(TG)
      fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockPID9')))
   else
      fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockPID8',TG(1:end-2))))
   end
   try
      showModelProperties(blk)
   end
   
   % Display suggested action
   VarName = inputname(1);
   if isempty(VarName)
      VarName = 'ans';
   end
   FootNote = getString(message('Control:lftmodel:ltiblockPID10',VarName));
   fprintf('\n%s\n',FootNote)
end
