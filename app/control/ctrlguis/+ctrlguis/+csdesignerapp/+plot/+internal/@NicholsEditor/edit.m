function edit(this,propEdit)
%EDIT  Configures Property Editor for Nichols editors.

%   Copyright 1986-2020 The MathWorks, Inc. 

propEdit.Title = sprintf('%s %s', ...
       getString(message('Control:compDesignTask:lblPropertyEditor')),...
       getString(message('Control:compDesignTask:strOpenLoopNichols')));

% Labels tab
buildtab(propEdit,1,getLabelTabWidgets(propEdit,this.Axes))

% Limits tab
buildtab(propEdit,2,getLimitTabWidgets(propEdit,this.Axes,{...
    getString(message('Control:compDesignTask:strOpenLoopPhase')), ...
    getString(message('Control:compDesignTask:strOpenLoopGain')) ...
    }))

% No Options tab
end