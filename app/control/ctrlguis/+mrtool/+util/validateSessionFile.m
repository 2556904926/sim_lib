function S = validateSessionFile(SessionFileName)
arguments
    SessionFileName (1,1) string
end
sw = ctrlMsgUtils.SuspendWarnings;
S = load(SessionFileName);
delete(sw);

% validate session file
if isempty(S) ... % session is not empty
        || ~isfield(S,getString(message('Control:mrtool:SessionName'))) ... % Session Variable Name is correct
        || ~isa(S.ModelReducerSession,'mrtool.data.SessionData') % Session Class is correct    
    [~,FileName,~] = fileparts(SessionFileName);
    error(getString(message('Control:mrtool:InvalidSessionFile',FileName)));
end