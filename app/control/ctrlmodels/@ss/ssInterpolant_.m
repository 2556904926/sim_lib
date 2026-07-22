function vsys = ssInterpolant_(asys,IMETHOD,EMETHOD)
% see ssInterpolant.

%   Copyright 2022 The MathWorks, Inc.
arguments
   asys
   IMETHOD (1,:) char = 'linear';
   EMETHOD (1,:) char = 'clip';
end

IMETHOD = lower(IMETHOD);
EMETHOD = lower(EMETHOD);

try
   % Process incoming data
   [Dsys,INFO] = processLPVData(asys);
   INFO.Interpolation = IMETHOD;
   INFO.Extrapolation = EMETHOD;
   ParamNames = fieldnames(INFO.Grid);

   % Dependence on time
   tidx = find(strcmp(ParamNames,'Time'));
   INFO.tidx = tidx;
   if ~isempty(tidx)
      ParamNames(tidx,:) = [];
   end

   % Create interpolating model
   if INFO.pdim==numel(INFO.GridVectors)
      % Interpolation on rectangular grid
      if any(strcmp(IMETHOD,{'nearest','linear'})) && ...
            any(strcmp(EMETHOD,{'clip','nearest','linear'}))
         % Rectangular grid, fast interpolation
         S = ltvpack.interp.structurizeData(Dsys,INFO);
         if isempty(ParamNames)
            F = @(t) ltvpack.interpolateR(t,[],S,INFO);
            vsys = GriddedLTVSS(F,asys.Ts);
         else
            F = @(t,p) ltvpack.interpolateR(t,p,S,INFO);
            vsys = GriddedLPVSS(ParamNames,F,asys.Ts);
         end
      else
         % Rectangular grid, general case
         V = ltvpack.interp.vectorizeData(Dsys,INFO);
         if strcmp(EMETHOD,'clip')
            % REVISIT: Currently done in soft, should be supported.
            EMETHOD = 'none';
         end
         gI = griddedInterpolant(INFO.GridVectors,V,IMETHOD,EMETHOD);
         if isempty(ParamNames)
            F = @(t) ltvpack.interpolateG(t,[],gI,INFO);
            vsys = GriddedLTVSS(F,asys.Ts);
         else
            F = @(t,p) ltvpack.interpolateG(t,p,gI,INFO);
            vsys = GriddedLPVSS(ParamNames,F,asys.Ts);
         end
      end
   else
      % Scattered interpolation (up to 3D for now)
      if INFO.pdim>3
         error(message('Control:ltiobject:ssInterpolant7'))
      end
      C = struct2cell(INFO.Grid);
      X = cat(2,C{:});
      V = ltvpack.interp.vectorizeData(Dsys,INFO);
      EMETHOD = strrep(EMETHOD,'clip','boundary');
      gI = scatteredInterpolant(X,V,IMETHOD,EMETHOD);
      if isempty(ParamNames)
         F = @(t) ltvpack.interpolateG(t,[],gI,INFO);
         vsys = GriddedLTVSS(F,asys.Ts);
      else
         F = @(t,p) ltvpack.interpolateG(t,p,gI,INFO);
         vsys = GriddedLPVSS(ParamNames,F,asys.Ts);
      end
   end
catch ME
   throw(ME)
end

% Inherit metadata except Name,Notes,UserData
vsys = feedbackMetaData(vsys,asys,[]);
vsys.StateName = asys.StateName;
vsys.StateUnit = asys.StateUnit;
vsys.StatePath = asys.StatePath;
vsys.TimeUnit = asys.TimeUnit;
