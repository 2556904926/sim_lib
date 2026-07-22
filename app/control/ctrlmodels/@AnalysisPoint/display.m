function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.

% Variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

% Description
Loc = blk.Location;
Open = blk.Open;
if numel(Loc)==1
   if Open
      fprintf('%s\n',getString(message('Control:lftmodel:AnalysisPoint7',Loc{1})))
   else
      fprintf('%s\n',getString(message('Control:lftmodel:AnalysisPoint1',Loc{1})))
   end
else
   fprintf('%s\n',getString(message('Control:lftmodel:AnalysisPoint2')));
   fprintf('   %s\n',Loc{:});
   if any(Open)
      fprintf('%s\n',getString(message('Control:lftmodel:AnalysisPoint8')));
      fprintf('   %s\n',Loc{Open});
   end
end

% Footnote
try
   showModelProperties(blk)
end
fprintf('\n%s\n',getString(message('Control:lftmodel:ltiblockSS13',VarName)))
