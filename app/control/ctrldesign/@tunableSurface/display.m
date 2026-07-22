function display(blk)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.

% Data
ios = blk.IOSize_;
gridSize = sprintf('%dx',getSize(blk.SamplingGrid_));
if all(ios==1)
   Msg1 = message('Control:lftmodel:tunableSurface13',blk.Name);
else
   Msg1 = message('Control:lftmodel:tunableSurface14',blk.Name,ios(1),ios(2));
end
SV = getVariable(blk.SamplingGrid_); % scheduling variables
SVList = sprintf('%s,',SV{:});  SVList = SVList(1:end-1);
BFList = localGetExpression(blk.BasisFunctions_,SV);
Msg2 = message('Control:lftmodel:tunableSurface15',SVList);
Msg3 = message('Control:lftmodel:tunableSurface16',BFList);
if numel(SV)>1
   SVList = sprintf('(%s)',SVList);
end
Msg4 = message('Control:lftmodel:tunableSurface17',gridSize(1:end-1),SVList);
if isempty(blk.Normalization_)
   Msg5 = message('Control:lftmodel:tunableSurface21');
else
   Msg5 = message('Control:lftmodel:tunableSurface22');
end
fprintf('%s\n  * %s\n  * %s\n  * %s\n  * %s\n',...
   getString(Msg1),getString(Msg2),getString(Msg3),getString(Msg4),getString(Msg5))
try
   showModelProperties(blk)
end

%-----------------------------------------------

function BFList = localGetExpression(F,SV)
% Tries to write basis function formulae in terms of actual scheduling
% variables
if isempty(F)
   BFList = getString(message('Control:lftmodel:tunableSurface20'));
else
   F = functions(F);
   BFList = F.function;
   if strcmp(F.type,'anonymous')
      T = regexp(F.function,'@(\([^\)\(]+\))(\[.+\])','tokens');
      if ~isempty(T) && numel(T{1})==2
         V = regexp(T{1}{1},'([^,\(\)]+)','tokens');
         V = cat(1,V{:});
         if ~isequal(V,SV) && numel(V)==numel(SV)
            BFList = regexprep(T{1}{2},strcat('(?<!\w)',V,'(?!\w)'),SV);
            BFList = strrep(BFList(2:end-1),';',',');
         end
      end
   end
end
      
      
      

