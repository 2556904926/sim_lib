function disp(R)
% Display method.

%   Copyright 1986-2015 The MathWorks, Inc.
disp@TuningGoal.Generic(R)

% Footer
narg = nargin(R.Template);
F = functions(R.Template);
GS = sprintf('%dx',size(R.Parameters_{1}));
if strcmp(F.type,'anonymous')
   SF = F.function;
   T = regexp(SF,'@(\([^\)\(]+\))(.+)','tokens');
   V = T{1}{1};
   if narg==1
      V = V(2:end-1);
   end
   Msg = message('Control:tuning:varyingGoal6',GS(1:end-1),V);
else
   Msg = message('Control:tuning:varyingGoal7',GS(1:end-1));
end
fprintf('  %s\n\n',getString(Msg))
