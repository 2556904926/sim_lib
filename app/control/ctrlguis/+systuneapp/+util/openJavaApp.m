function yes = openJavaApp(varargin)
%

% This is a temporary function for switching between Java and JS app. By
% default, it returns true to open the existing Java-based app container.
% Provide input flag to change it to JS app.

%  Copyright 2021 The MathWorks, Inc.

yes = controllib.internal.util.openJavaApp(varargin{:});
end