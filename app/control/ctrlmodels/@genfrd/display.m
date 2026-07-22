function display(sys)
% Display method.

%   Copyright 1986-2014 The MathWorks, Inc.

% Variable name
VarName = inputname(1);
if isempty(VarName)
   VarName = 'ans';
end

s = size(sys);
ArraySize = getArraySize(sys);
if isct(sys)
   Domain = 'c';
else
   Domain = 'd';
end
nf = nfreqs(sys);
nsys = prod(ArraySize);
if nsys==0
   % Empty array
   AS = sprintf('%dx',ArraySize);
   fprintf('%s\n',getString(message('Control:lftmodel:genfrd4',AS(1:end-1),s(1),s(2))))
else
   if nsys==1
      % Single model
      BD = getSummary(sys.Data_.Blocks);
      nblk = numel(BD);
      if nblk==0
         MsgID = sprintf('Control:lftmodel:genfrd1%s',Domain);
         fprintf('%s\n',getString(message(MsgID,s(1),s(2),nf)))
      else
         MsgID = sprintf('Control:lftmodel:genfrd2%s',Domain);
         fprintf('%s\n',getString(message(MsgID,s(1),s(2),nf)))
         for ct=1:nblk
            disp(['  ' BD{ct}]);
         end
      end
   else
      % GENFRD array
      AS = sprintf('%dx',ArraySize);
      fprintf('%s\n',getString(message(sprintf('Control:lftmodel:genfrd3%s',Domain),AS(1:end-1))))
      if isequal(sys.Data_.Blocks)
         % All models have same block set
         BD = getSummary(sys.Data_(1).Blocks);
         nblk = numel(BD);
         if nblk==0
            fprintf('%s\n',getString(message('Control:lftmodel:genfrd5',s(1),s(2),nf)))
         else
            fprintf('%s\n',getString(message('Control:lftmodel:genfrd6',s(1),s(2),nf)))
            for ct=1:nblk
               disp(['  ' BD{ct}]);
            end
         end
      else
         nblk = nblocks(sys);
         if all(nblk==nblk(1))
            fprintf('%s\n',getString(message('Control:lftmodel:genfrd7',s(1),s(2),nf,nblk(1))))
         else
            fprintf('%s\n',getString(message('Control:lftmodel:genfrd8',s(1),s(2),nf,min(nblk(:)),max(nblk(:)))))
         end
      end
   end
   try
      showModelProperties(sys)
   end
   fprintf('\n%s\n',getString(message('Control:lftmodel:genfrd9',VarName,VarName)))
end
