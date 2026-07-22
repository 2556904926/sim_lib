function CurrentErrorException = throwCSTunerError(ErrorException) %#ok<*STOUT>
% Passes Control System Tuner's error messages for command line error messages.

% Copyright 2013 The MathWorks, Inc.

CurrentID = '';
Identifier = '';
if isa(ErrorException,'MException') % Check that it's error message    
    Identifier = ErrorException.identifier;    
end

% replace identifier with Control System Tuner's identifier
switch Identifier
    case 'Slcontrol:sllinearizer:BadModelIndex'
        CurrentID = 'Control:lftmodel:getTransfer11';
    case 'Slcontrol:sltuner:GenssNoPoint'
        CurrentID = 'Control:systunegui:PolesTuningGoalNoPoint';
end

if ~isempty(CurrentID)
    % replace exception
    msg = message(CurrentID);    
    CurrentErrorException = MException(msg.Identifier,getString(msg));
    throw(CurrentErrorException);
else % same exception
    CurrentErrorException = ErrorException;
    if isempty(CurrentErrorException.stack)
        throw(CurrentErrorException);
    else
        rethrow(CurrentErrorException);
    end
end