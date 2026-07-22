function addconstr(Editor,Constr)
%ADDCONSTR  Add Root-Locus constraint to editor.

%   Copyright 1986-2024 The MathWorks, Inc. 

FreqUnitFlag = ~isempty(Constr.findprop('FrequencyUnits'));
Data = Editor.Data;

% Generic init (includes generic interface editor/constraint)
initconstr(Editor,Constr)

% Initialize editor-specific properties
Constr.Ts = Data.EditedBlock.Ts;

if FreqUnitFlag
  L = addlistener(Editor, 'FrequencyUnits', 'PostSet', ...
	      @(es,ed)LocalUpdateUnits(es,ed,Constr));
  Constr.addlisteners(L);
end

% Activate (initializes graphics and targets constr. editor)
Constr.Activated = 1;

% Update limits
% Editor.Axes.send('ViewChanged');

end


%-------------------- Local functions ---------------------------------

function LocalUpdateUnits(es,eventData,Constr)
% Syncs constraint props with related Editor props
Constr.TextEditor.setDisplayUnits('xunits',eventData.AffectedObject.(es.Name))
Constr.setDisplayUnits('xUnits',eventData.AffectedObject.(es.Name))
% Update constraint display (and notify observers)
update(Constr)
end

% LocalWords:  xunits
