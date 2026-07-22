function edit(this,propEdit)
%EDIT  Configures Property Editor for Bode editors.

%   Copyright 1986-2020 The MathWorks, Inc. 

if isLoopTransfer(getResponse(this))
   propEdit.Title = sprintf('%s %s', ...
       getString(message('Control:compDesignTask:lblPropertyEditor')),...
       getString(message('Control:compDesignTask:strOpenLoopBode')));
else
   propEdit.Title = sprintf('%s %s', ...
       getString(message('Control:compDesignTask:lblPropertyEditor')),...
       getString(message('Control:compDesignTask:strFilterBode')));
end   

% Labels tab
buildtab(propEdit,1,getLabelTabWidgets(propEdit,this.Axes))

% Limits tab
buildtab(propEdit,2,getLimitTabWidgets(propEdit,this.Axes,{...
    getString(message('Control:compDesignTask:strFrequency')), ...
    getString(message('Control:compDesignTask:strMagnitude')), ...
    getString(message('Control:compDesignTask:strPhase')) ...
    }))

% No Options tab
end