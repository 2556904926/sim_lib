function xylabelvis(Editor,Xvis,Yvis)
% Low-level utility for hiding X/Y labels.

%   Copyright 1986-2014 The MathWorks, Inc. 
if nargin>1
   % Update label visibility state (private)
   Editor.XlabelVisible = Xvis;
   Editor.YlabelVisible = Yvis;
end   
% Visible axes
visax = getaxes(Editor.Axes);

% Set label visibility
for ct=1:length(visax)
    if strcmp(get(visax,'Visible'),'on');
        set(get(visax(ct),'XLabel'),'Visible','on')
        set(get(visax(ct),'YLabel'),'Visible','on')
    else
        % Make labels not visible if axes is not visible
        set(get(visax(ct),'XLabel'),'Visible','off')
        set(get(visax(ct),'YLabel'),'Visible','off')
    end
end
end