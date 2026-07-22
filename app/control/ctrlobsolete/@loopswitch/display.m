function display(blk)
% Display method.

%   Copyright 1986-2012 The MathWorks, Inc.


% Variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

% Footer
Msg = getString(message('Control:lftmodel:ltiblockSS13',VarName));

% Data
if all(blk.Open)
   fprintf('%s\n\n%s\n',getString(message('Control:lftmodel:LoopSwitch3',blk.IOSize_(1))),Msg)
elseif ~any(blk.Open)
   fprintf('%s\n\n%s\n',getString(message('Control:lftmodel:LoopSwitch4',blk.IOSize_(1))),Msg)
else
   iOpen = find(blk.Open);
   if numel(iOpen)==1
      fprintf('%s\n\n%s\n',getString(message('Control:lftmodel:LoopSwitch5',...
         blk.IOSize_(1),iOpen)),Msg)
   else
      chStr = sprintf('%d,',iOpen);
      fprintf('%s\n\n%s\n',getString(message('Control:lftmodel:LoopSwitch6',...
         blk.IOSize_(1),chStr(1:end-1))),Msg)
   end
end
