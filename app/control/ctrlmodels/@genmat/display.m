function display(M)
% Display method.

%   Copyright 1986-2022 The MathWorks, Inc.

% Variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

s = size(M);
ArraySize = getArraySize(M);
nModel = prod(ArraySize);
if nModel==0
   % Empty array
   AS = sprintf('%dx',ArraySize);
   fprintf('%s\n',getString(...
      message('Control:lftmodel:genmat10',AS(1:end-1),s(1),s(2))))
else
   if nModel==1
      % Single matrix
      BD = getSummary(M.Data_.Blocks);
      nblk = numel(BD);
      if nblk==0
         fprintf('%s\n',getString(message('Control:lftmodel:genmat4',s(1),s(2))))
      else
         fprintf('%s\n',getString(message('Control:lftmodel:genmat5',s(1),s(2))))
         for ct=1:nblk
            disp(['  ' BD{ct}]);
         end
      end
   else
      % GENMAT array
      AS = sprintf('%dx',ArraySize);
      if isequal(M.Data_.Blocks)
         % All models have same block set
         BD = getSummary(M.Data_(1).Blocks);
         nblk = numel(BD);
         if nblk==0
            fprintf('%s\n',getString(message('Control:lftmodel:genmat6',AS(1:end-1),s(1),s(2))))
         else
            fprintf('%s\n',getString(message('Control:lftmodel:genmat7',AS(1:end-1),s(1),s(2))))
            for ct=1:nblk
               disp(['  ' BD{ct}]);
            end
         end
      else
         nblk = nblocks(M);
         if all(nblk==nblk(1))
            fprintf('%s\n',getString(message('Control:lftmodel:genmat8',AS(1:end-1),s(1),s(2),nblk(1))))
         else
            fprintf('%s\n',getString(message('Control:lftmodel:genmat9',AS(1:end-1),s(1),s(2),...
               min(nblk(:)),max(nblk(:)))))
         end
      end
   end
   try
      showModelProperties(M)
   end
   fprintf('\n%s\n',getString(message('Control:lftmodel:genmat11',VarName,VarName)))
end
