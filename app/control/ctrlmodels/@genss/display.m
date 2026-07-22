function display(sys)
% Display method.

%   Copyright 1986-2011 The MathWorks, Inc.

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
nsys = prod(ArraySize);
if nsys==0
   % Empty array
   AS = sprintf('%dx',ArraySize);
   fprintf('%s\n',getString(message('Control:lftmodel:genss4',AS(1:end-1),s(1),s(2))))
else
   if nsys==1
      % Single model
      BD = getSummary(sys.Data_.Blocks);
      nblk = numel(BD);
      nx = order(sys);
      if nblk==0
         MsgID = sprintf('Control:lftmodel:genss1%s',Domain);
         fprintf('%s\n',getString(message(MsgID,s(1),s(2),nx)))
      else
         MsgID = sprintf('Control:lftmodel:genss2%s',Domain);
         fprintf('%s\n',getString(message(MsgID,s(1),s(2),nx)))
         for ct=1:nblk
            disp(['  ' BD{ct}]);
         end
      end
   else
      % GENSS array
      AS = sprintf('%dx',ArraySize);
      nx = order(sys);  nx = nx(:);
      fprintf('%s\n',getString(message(sprintf('Control:lftmodel:genss3%s',Domain),AS(1:end-1))))
      % Model info
      if isequal(sys.Data_.Blocks)
         % All models have same block set
         BD = getSummary(sys.Data_(1).Blocks);
         nblk = numel(BD);
         if nblk==0
            if all(nx==nx(1))
               fprintf('%s\n',getString(message('Control:lftmodel:genss5',s(1),s(2),nx(1))))
            else
               fprintf('%s\n',getString(message('Control:lftmodel:genss6',s(1),s(2),min(nx),max(nx))))
            end
         else
            if all(nx==nx(1))
               fprintf('%s\n',getString(message('Control:lftmodel:genss7',s(1),s(2),nx(1))))
            else
               fprintf('%s\n',getString(message('Control:lftmodel:genss8',s(1),s(2),min(nx),max(nx))))
            end
            for ct=1:nblk
               disp(['  ' BD{ct}]);
            end
         end
      else
         nblk = nblocks(sys); nblk = nblk(:);
         if all(nblk==nblk(1))
            if all(nx==nx(1))
               fprintf('%s\n',getString(message('Control:lftmodel:genss9',s(1),s(2),nx(1),nblk(1))))
            else
               fprintf('%s\n',getString(message('Control:lftmodel:genss10',s(1),s(2),min(nx),max(nx),nblk(1))))
            end
         else
            if all(nx==nx(1))
               fprintf('%s\n',getString(message('Control:lftmodel:genss11',s(1),s(2),nx(1),min(nblk),max(nblk))))
            else
               fprintf('%s\n',getString(message('Control:lftmodel:genss12',s(1),s(2),min(nx),max(nx),min(nblk),max(nblk))))
            end
         end
      end
   end
   try
      showModelProperties(sys)
   end
   fprintf('\n%s\n',getString(message('Control:lftmodel:genss13',VarName,VarName)))
end
