function Data = wrapperToData(Type,Wrapper)
% Utility function to convert wrapper to data. Type can be 'TuningGoal' or
% 'Response'. Data is cell array vector of TuningGoals or Responses.
% Wrapper contains Data in TuningGoal or Response fields for TuningGoals
% and Responses. MetaData contains extra information.

% Copyright 2013 The MathWorks, Inc.

if isempty(Wrapper)
    Data = [];
else
    for ct=1:length(Wrapper)
        Data(ct,1)=Wrapper(ct).(Type);
    end    
end
end