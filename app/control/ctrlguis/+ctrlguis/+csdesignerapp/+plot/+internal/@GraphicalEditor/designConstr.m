function designConstr(this, ActionType)
% Opens dialogs to add/edit design constraints

%   Copyright 2020 The MathWorks, Inc.

switch ActionType
    case 'new'
        % Add new constraint
        editconstr.newdlg.getInstance(this, getHGParent(this));
    case 'edit'
        % Edit constraints in editor if there are constraints to edit.
        Constr = this.findconstr;
        if isempty(Constr)
            % No constraints to show in this View
            warnstr = getString(message('Control:designerapp:msgNoRequirementToEdit'));
            uialert(getAppContainer(this.EventManager),warnstr,...
                getString(message('Control:designerapp:strEditRequirementWarning')),...
                'Icon','warning');
        else
            this.ConstraintEditor.show(this);
        end
end
end
