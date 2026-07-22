function edit(this,propEdit)
%EDIT  Configures Property Editor for Root Locus editors.

%   Copyright 1986-2020 The MathWorks, Inc. 

propEdit.Title = sprintf('%s %s', ...
       getString(message('Control:compDesignTask:lblPropertyEditor')),...
       getString(message('Control:compDesignTask:strRootLocus')));

% Labels tab
buildtab(propEdit,1,getLabelTabWidgets(propEdit,this.Axes))

% Limits tab
buildtab(propEdit,2,getLimitTabWidgets(propEdit,this.Axes,{...
    getString(message('Control:compDesignTask:strRealAxis')), ...
    getString(message('Control:compDesignTask:strImaginaryAxis')) ...
    }))

% No Options tab
end