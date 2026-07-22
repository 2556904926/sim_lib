function openUIAlert(AnchorObject,ErrorMessage)
% Utilitiy function to create uialert dialog

% Copyright 2024 The MathWorks, Inc.

uialert(AnchorObject,ErrorMessage,getString(message('Control:systunegui:toolName')));
