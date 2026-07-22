function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.
Ts = blk.Ts_;
if isempty(Ts)
   fprintf('%s\n\n',getString(...
      message('Control:lftmodel:InvalidBlock','tunablePID2')))
else
   if Ts==0
      MsgID = 'Control:lftmodel:ltiblockPID2DOF7c';
   else
      MsgID = 'Control:lftmodel:ltiblockPID2DOF7d';
   end
   fprintf('%s\n\n',getString(message(MsgID,blk.Name)))
   
   % Display formula
   StrI = ltipack.piddata.utGetStrI(Ts,blk.IFormula);
   StrD = ltipack.piddata.utGetStrD_Parallel(Ts,blk.DFormula);
   switch getType(blk)
      case 'P'
         disp(' ');
         disp('  u = Kp (b*r-y)');
         disp(' ');
      case 'PI'
         disp([blanks(22) StrI(1,:)]);
         disp(['  u = Kp (b*r-y) + Ki ' StrI(2,:) ' (r-y)']);
         disp([blanks(22) StrI(3,:)]);
      case 'PD'
         disp([blanks(22) StrD(1,:)]);
         disp(['  u = Kp (b*r-y) + Kd ' StrD(2,:) ' (c*r-y)']);
         disp([blanks(22) StrD(3,:)]);
      case 'PID'
         disp([blanks(22) StrI(1,:) blanks(12) StrD(1,:)]);
         disp(['  u = Kp (b*r-y) + Ki ' StrI(2,:) ' (r-y) + Kd ' StrD(2,:) ' (c*r-y)']);
         disp([blanks(22) StrI(3,:) blanks(12) StrD(3,:)]);
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
   if blk.b.Free
      TG = [TG , 'b, '];
   end
   if (blk.Kd.Free || blk.Kd.Value~=0) && blk.c.Free
      TG = [TG , 'c, '];
   end
   if isempty(TG)
      fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockPID2DOF9')))
   else
      fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockPID2DOF8',TG(1:end-2))))
   end
   try
      showModelProperties(blk)
   end
   
   % Display suggested action
   VarName = inputname(1);
   if isempty(VarName)
      VarName = 'ans';
   end
   FootNote = getString(message('Control:lftmodel:ltiblockPID2DOF10',VarName));
   fprintf('\n%s\n',FootNote)
end
