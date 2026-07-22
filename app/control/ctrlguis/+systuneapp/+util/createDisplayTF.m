function DisplayText = createDisplayTF(sys)
% Utility function for display text of TF Object.

% Copyright 2013 The MathWorks, Inc.

sys = tf(sys);

str = evalc('display(sys)');
str = strsplit(str,'=\n');
str = str{2};
str = strsplit(str,'\n');
indentation = max(strfind(str{3},' '));
if ~isempty(strfind(str{3},'-'))    
    DisplayText{1} = sprintf('%s',str{2}(indentation+1:end));
    DisplayText{2} = sprintf('%s',str{3}(indentation+1:end));
    DisplayText{3} = sprintf('%s',str{4}(indentation+1:end));
else
    indentation = max(strfind(str{2},' '));
    DisplayText{1} = sprintf('%s',str{2}(indentation+1:end));
end