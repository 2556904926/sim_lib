function setmenu(this,OnOff,Tag)
% Enables/disables editor menus.

%   Copyright 1986-2010 The MathWorks, Inc.

% RE: Menus must be disabled when Editor.SingularLoop=1
PlotAxes = getAxes(this.Axes);
uic = get(PlotAxes(1),'uicontextmenu');
if this.Data.SingularLoop
    set(get(uic,'Children'),'Enable','off')
else
    if nargin == 3
        % Enable/Disable Particular Menu
        hmenu = findobj(get(uic,'Children'),'Tag',Tag);
        set(hmenu,'Enable',OnOff)
    else
        set(get(uic,'Children'),'Enable',OnOff)
    end
end
end