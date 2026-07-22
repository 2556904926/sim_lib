function S = loadValidateSessionFile(SessionFileName)
w = warning('off'); %#ok<WNOFF>
[msgOriginal,msgIDOriginal] = lastwarn;
S = load(SessionFileName);
[msg,msgID] = lastwarn;
warning(w); lastwarn(msgOriginal,msgIDOriginal);

% validate session file
if isempty(S) ... % session is not empty
        || ~isfield(S,getString(message('Control:systunegui:CSTSessionName'))) ... % Session Variable Name is correct
        || ~isa(S.ControlSystemTunerSession,'systuneapp.data.SessionData') % Session Class is correct
    error(getString(message('Control:systunegui:InvalidSessionFile')));
elseif (~license('test','Simulink_Control_Design') || isempty(ver('slcontrol'))) % no SCD
    % if SCD do not exist, error for slTuner session
    if ( strcmp(msgID,'MATLAB:load:classNotFound') || strcmp(msgID,'MATLAB:load:classError') ) ...
            &&  ~isempty(strfind(msg,'slTuner')) % but session contains slTuner
        error(getString(message('Control:systunegui:OpenCSTSesssionSCDRequired')));
    end
elseif isa(S.ControlSystemTunerSession.ControlDesignData.Architecture,'slTuner')
    % In Simulink case, make sure the model is on the path
    Architecture = S.ControlSystemTunerSession.ControlDesignData.Architecture;
    if Architecture.BadConstruction
        ex = Architecture.ConstructionError;
        switch ex.identifier
            case 'Simulink:Commands:OpenSystemUnknownSystem'
                error(message('Control:systunegui:OpenCSTSesssionNoSimulinkModel',Architecture.Model));
            otherwise
                throw(ex);
        end
    end
end
end
