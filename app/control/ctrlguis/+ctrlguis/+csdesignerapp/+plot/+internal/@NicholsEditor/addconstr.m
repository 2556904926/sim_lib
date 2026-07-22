function addconstr(Editor, Constr)
%ADDCONSTR  Add constraint to editor.

%   Copyright 1986-2024 The MathWorks, Inc.

% REVISIT: should call grapheditor::addconstr to perform generic init
Axes = Editor.Axes;

% Generic init (includes generic interface editor/constraint)
initconstr(Editor,Constr)

% Add related listeners 
L2 = addlistener(Axes,{'FrequencyUnit','MagnitudeUnit','PhaseUnit'},'PostSet',@(es,ed) LocalSetUnits(es,ed,Constr));

% Activate (initializes graphics and targets constr. editor)
Constr.Activated = 1;

updatelims(Editor);
% Update limits
% Editor.Axes.send('ViewChanged');

% --------------------------- Local Functions ----------------------------------%

function LocalSetUnits(eventSrc,eventData,Constr)

whichUnits = eventSrc.Name;
NewValue = eventData.AffectedObject.(whichUnits);
switch whichUnits
    case 'PhaseUnit'
        whichUnits = 'xUnits';
    case 'MagnitudeUnit'
        whichUnits = 'yUnits';
end
Constr.setDisplayUnits(whichUnits,NewValue)
Constr.TextEditor.setDisplayUnits(lower(whichUnits),NewValue)

% Update constraint display (and notify observers)
update(Constr)


