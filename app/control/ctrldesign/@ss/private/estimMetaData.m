function est = estimMetaData(est,plant,known,sensors,stoch)
% Sets I/O names and groups and state names for state observers
% (used by ESTIM and KALMAN).

%   Copyright 1986-2009 The MathWorks, Inc.

% Use default name uj if all plant inputs are unnamed
Nu = numel(known);
Nw = numel(stoch);
if isempty(plant.InputName_)
   Uname = "u" + known(:);
   Wname = "w" + stoch(:);
else
   Uname = plant.InputName_(known,:);
   Wname = plant.InputName_(stoch,:);
end

% Use default name yj if all plant outputs are unnamed
Ny = numel(sensors);
if isempty(plant.OutputName_)
   Yname = "y" + sensors(:);
else
   Yname = plant.OutputName_(sensors,:);
end

% Use default name xj if all plant states are unnamed
Xname = string(plant.StateName);  Nx = length(Xname);
if all(strcmp(Xname,''))
   Xname = "x" + (1:Nx)';
end

% Gives names to estimated states and outputs by
% appending _e to state and measurement names
if Nw>0
   % Estimator outputs [w_e;x_e] ('lqg' option in KALMAN)
   YeName = LocalAddSuffix(Wname);
else   
   % Estimator outputs [y_e;x_e]
   YeName = LocalAddSuffix(Yname);
end
XeName = LocalAddSuffix(Xname);
est.StateName = XeName;
est.InputName_ = [Uname ; Yname];
est.OutputName_ = [YeName ; XeName];

% Set input groups to 'KnownInput' and 'Measurement'
% Note: Use full assign to remove empty groups
est.InputGroup = struct('KnownInput',1:Nu,'Measurement',Nu+1:Nu+Ny); 

% Set output groups to 'OutputEstimate' and 'StateEstimate'
if Nw>0
   est.OutputGroup = struct('NoiseEstimate',1:Nw,'StateEstimate',Nw+1:Nw+Nx); 
else
   est.OutputGroup = struct('OutputEstimate',1:Ny,'StateEstimate',Ny+1:Ny+Nx); 
end


%------------------
function Names = LocalAddSuffix(Names)
% Adds "_e" suffix to a set of input, output, or state names.
idx = find(Names~="");
Names(idx) = Names(idx) + "_e";
