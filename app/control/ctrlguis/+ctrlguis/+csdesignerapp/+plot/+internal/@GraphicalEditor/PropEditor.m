function hEditor = PropEditor(this,CurrentFlag)
%PROPEDITOR  Returns instance of Property Editor for response plots.
%
%   PropEdit = PROPEDITOR(GraphEditor) returns the (unique) instance of
%   Property Editor for the SISO Tool's graphical editors, and creates
%   it if necessary.
%
%   PropEdit = PROPEDITOR(GraphEditor,'current') returns [] if no Property
%   Editor exists.
%
%   PropEdit = PROPEDITOR(GraphEditor,'reset') deletes the existing
%   instance of Property Editor and creates and returns a new one.
%
%   PropEdit = PROPEDITOR(GraphEditor,'delete') deletes the existing
%   instance of Property Editor and returns [].

%  Copyright 2015-2020 The MathWorks, Inc.

persistent hPropEdit
createNew = false;

if nargin == 2 && contains(CurrentFlag,{'reset','delete'})
    delete(hPropEdit);
    hPropEdit = [];
    if strcmp(CurrentFlag,'reset')
        createNew = true;
    end
end

if nargin==1 && isempty(hPropEdit)
    createNew = true;
end

if createNew
    % Create and target prop editor if it does not yet exist
    hPropEdit = ctrlguis.csdesignerapp.dialogs.internal.PropertyEditorDialog(...
        {getString(message('Control:compDesignTask:strLabels')), ...
        getString(message('Control:compDesignTask:strLimits')), ...
        getString(message('Control:compDesignTask:strOptions'))});
end

hEditor = hPropEdit;
end