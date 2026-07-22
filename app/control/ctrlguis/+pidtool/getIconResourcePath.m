function pth = getIconResourcePath(iconType)
% GETICONRESOURCEPATH
%

% Author(s): A. Stothert 07-Sep-2011
% Copyright 2011 The MathWorks, Inc.

switch iconType
    case 'pidtuner'
        pth = fullfile(matlabroot,'toolbox','control','ctrlguis','+pidtool','+desktop','+pidtuner','resources');
    case 'simulationtool'
        pth = fullfile(matlabroot,'toolbox','ident','idguis','+iduis','+pid','+simulationtool','resources');
    case 'controllib'
        pth = fullfile(matlabroot,'toolbox','shared','controllib','general','resources');
    otherwise
        pth = fullfile(matlabroot,'toolbox','control','ctrlguis','+pidtool','+desktop','+pidtuner','resources');
end
end