function varargout = modelReducer(varargin)
% modelReducer  Model Reducer App.
%
%   modelReducer opens the Model Reducer App.  This Graphical User
%   Interface lets you to reduce LTI models using various model reduction
%   techniques. You can reduce the order and capture the dynamics of a
%   system on a certain time or frequency interval. You can select desired
%   modes of your system or do pole/zero simplification.
%
%   modelReducer(MODEL1,...,MODELN) opens the App with LTI models MODEL1,
%   ...,MODELN. Models are single, proper dynamic system without delay,
%   with inputs and outputs.
%
%   modelReducer(SESSIONFILE) opens the App and loads a previously saved
%   session SESSIONFILE.

%   Copyright 2015-2020 The MathWorks, Inc.

    App = [];
    switch nargin
        case 0
            App = mrtool.internal.ModelReducerApp();
        otherwise        
            if ischar(varargin{1}) || isStringScalar(varargin{1})
                % session file                       
                FileName = appendMATExtension(varargin{1});
                if exist(FileName,'file')
                    SessionFile = mrtool.util.validateSessionFile(FileName);
                    App = modelReducer();
                    [~,Name,~] = fileparts(FileName);
                    preLoadSession(App,SessionFile.ModelReducerSession,Name);
                end
            else
                % model            
                [isValid,Models,InvalidType] = mrtool.util.isValidSystem(varargin);
                if all(isValid)
                    VarNames = cell(size(varargin));
                    for ct=1:length(varargin)
                        VarNames{ct}=inputname(ct);
                    end                
                    ModelWrappers = mrtool.util.createModelWrapper(Models,VarNames);
                    App = mrtool.internal.ModelReducerApp(ModelWrappers);
                else
                    switch InvalidType
                        case 'ltiarray'
                            error(message( ...
                                'Control:mrtool:ErrorLtiArrayModel'));
                        case 'improper'
                            error(message( ...
                                'Control:mrtool:ErrorImproperModel'));
                        case 'io'
                            error(message( ...
                                'Control:mrtool:ErrorIOModel'));
                        case 'delay'
                            error(message( ...
                                'Control:mrtool:ErrorDelayModel'));
                        case 'static'
                            error(message( ...
                                'Control:mrtool:ErrorStaticModel'));
                        otherwise
                            error(message( ...
                                'Control:mrtool:InvalidModel'));                                                
                    end                        
                end                                    
            end
    end
    if isempty(App)
        error(message('Control:general:InvalidSyntaxForCommand', ...
            'modelReducer','modelReducer'))
    end
    if nargout
        varargout{1} = App;
    end
end

function FileName = appendMATExtension(Param)
    FileName = Param;
    if ~contains(FileName,'.mat')
        if isstring(FileName)
            FileName = FileName+".mat";
        else
            FileName = [FileName '.mat'];
        end
    end
end