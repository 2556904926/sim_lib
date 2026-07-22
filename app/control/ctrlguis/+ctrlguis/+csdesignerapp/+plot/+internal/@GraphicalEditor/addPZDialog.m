function C = addPZDialog(this, GroupType, PZType)
% ADDPZDialog  Dialog to select which tunedfactor to add a pole/zero to

%   Copyright 1986-2011 The MathWorks, Inc.
ValidTF = getValidCompensators(this.Data,GroupType,PZType);

nTF = length(ValidTF);

if nTF == 0
    C = [];
    error(getString(message('Control:compDesignTask:errAddPoleZero')));
else
    if nTF == 1
        C = ValidTF;
    else
        %create dialog here
        [Selection,~] = listdlg('ListString',getIdentifier(ValidTF),...
            'SelectionMode','single', 'Name', ...
            getString(message('Control:compDesignTask:strAddPoleZero')));
        C = ValidTF(Selection);
    end
end