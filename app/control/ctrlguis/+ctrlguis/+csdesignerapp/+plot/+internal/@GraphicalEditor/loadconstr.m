function loadconstr(this,SavedData)
%LOADCONSTR  Reloads saved constraint data.

%   Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc. 

% Clear existing constraints
delete(this.findconstr);

% Create and initialize new constraints
for ct=1:length(SavedData),
    % Use Editor.newconstr to recreate the constraint, this creates a 
    % constraint editor
    cEditor = this.newconstr(SavedData(ct).Type);
    hC = cEditor.Requirement.getView(this);
    hC.PatchColor = this.Preferences.RequirementColor;
    hC.load(SavedData(ct).Data);
	% Add to constraint list (includes rendering)
	this.addconstr(hC);
    % Unselect
    hC.Selected = 'off';
end

