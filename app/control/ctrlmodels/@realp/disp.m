function disp(blk)
% Display method.

%   Copyright 1986-2015 The MathWorks, Inc.
s = get(blk);
s = orderfields(s,[5 1:4]); %#ok<NASGU>
fprintf('%s\n\n',deblank(evalc('disp(s)')))  % to support format compact/loose
s = size(blk);
if all(s==1)
   fprintf('%s\n\n',getString(message('Control:lftmodel:realp6')))
else
   IOS = sprintf('%dx',s);
   fprintf('%s\n\n',getString(message('Control:lftmodel:realp7',IOS(1:end-1))))
end
