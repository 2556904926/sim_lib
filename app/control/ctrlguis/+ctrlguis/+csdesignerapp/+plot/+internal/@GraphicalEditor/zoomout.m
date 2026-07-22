function zoomout(Editor)
%ZOOMOUT  Manages Zoom Out action.

%   Author(s): P. Gahinet  
%   Copyright 1986-2023 The MathWorks, Inc. 


% Exit zoom mode
% RE: Allow zoom out in add/delete modes without aborting mode
if strcmp(Editor.EditMode,'zoom')
    % Revert to idle (abort global modes)
    Editor.EditMode = 'idle';
end

% Reset limit modes (triggers limit update)
% REVISIT: for max efficiency, push LimitManager='off', set lim mode, pop LimitManager, and call updatelims
Editor.Axes.XLimitsMode = "auto";
% REVISIT: replace next line by commented one
% Editor.Axes.YlimMode = repmat({'auto'},[Editor.Axes.Size(1) 1]);
Editor.Axes.YLimitsMode = "auto";

Editor.updatelims;
% Update status 
Editor.EventManager.postActionStatus('off',...
    sprintf('%s. %s', ...
    getString(message('Control:compDesignTask:msgZoomedOut')),...
    getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
    
   
end