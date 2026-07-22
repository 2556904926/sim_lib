function addTagsToWidgets(dlg)
% Helper to add tags to widgets

% Copyright 2020 The MathWorks, Inc.
widgets = qeGetWidgets(dlg);
if ~isempty(widgets)
    for widgetName = fieldnames(widgets)'
        w = widgets.(widgetName{1});
        if isprop(w,'Tag')
            w.Tag = widgetName{1};
        end
    end
end
end