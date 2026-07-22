classdef (CaseInsensitiveProperties, TruncatedProperties, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      GriddedLTVSS < ltvss & ltvpack.interp.GriddedModel
   %GriddedLTVSS  Interpolated LTV Model.

   %   Copyright 2022-2023 The MathWorks, Inc.

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)

      function T = toClosed(~)
         T = 'ltvss';
      end

      function A = getAttributes(A)
         % Override default attributes
         A.Structured = false;
         A.FRD = false;
         A.Sparse = false;
      end
            
      function T = toFRD()
         T = 'frd';
      end
            
   end


   methods
      
      function vsys = GriddedLTVSS(varargin)
         vsys = vsys@ltvss(varargin{:});
         if nargin>0
            % Access grid info from function workspace
            S = functions(varargin{1});
            try
               INFO = S.workspace{1}.INFO;
               vsys.Grid = INFO.Grid;
               vsys.Interpolation = INFO.Interpolation;
               vsys.Extrapolation = INFO.Extrapolation;
            catch
               error(message('Control:ltiobject:LTV13'))
            end
         end
      end

   end

   methods (Access = protected)

      function sysOut = ltvss_(vsys)
         sysOut = ltvss(vsys.DataFunction_,getTs_(vsys),vsys.t0_);
         sysOut.StateName_ = vsys.StateName_;
         sysOut.StatePath_ = vsys.StatePath_;
         sysOut.StateUnit_ = vsys.StateUnit_;
         sysOut.TimeUnit_ = vsys.TimeUnit_;
      end

      function [vsys,xkeep] = sminreal_(vsys,~)
         % State-consistent SMINREAL
         [ssarray,xkeep] = sminreal(psample(vsys),'uniform');
         vsys = ssInterpolant(ssarray,vsys.Interpolation,vsys.Extrapolation);
      end

      function vsys = xperm_(vsys,perm)
         % Permute state vector
         ssarray = xperm(psample(vsys),perm);
         vsys = ssInterpolant(ssarray,vsys.Interpolation,vsys.Extrapolation);
      end

      function [vsys,gic] = c2d_(vsys,Ts,options)
         % Pointwise discretization of gridded LTV models
         if ~any(strcmp(options.Method,{'zoh','impulse','tustin'}))
            error(message('Control:transformation:c2d24'))
         elseif options.ThiranOrder>0
            error(message('Control:transformation:c2d22'))
         end
         csys = psample(vsys);  % includes offsets
         % Enforce state and delay consistency in C2D
         options.Consistency = 'on';
         dsys = c2d(csys,Ts,options);
         % Map absolute time to sample k
         % Note: k can be fractional when discretizing at original grid
         % points (not a problem for interpolation).
         dsys.SamplingGrid.Time = dsys.SamplingGrid.Time/Ts;
         vsys = ssInterpolant(dsys,vsys.Interpolation,vsys.Extrapolation);
         gic = [];
      end

      function [vsys,gic] = d2c_(vsys,options)
         % Pointwise D2C conversion of gridded LTV models
         if ~any(strcmp(options.Method,{'zoh','tustin'}))
            error(message('Control:transformation:d2c11'))
         end
         dsys = psample(vsys,vsys.Grid);
         % Enforce state consistency in D2C
         options.Consistency = 'on';
         csys = d2c(dsys,options);
         % Map sample k to absolute time
         csys.SamplingGrid.Time = dsys.SamplingGrid.Time*vsys.Ts;
         vsys = ssInterpolant(csys,vsys.Interpolation,vsys.Extrapolation);
         gic = [];
      end

      function vsys = d2d_(vsys,Ts,options)
         % Pointwise D2D resampling of gridded LTV models (Tustin or ZOH)
         dsys = psample(vsys,vsys.Grid);
         % Enforce state consistency in D2D
         options.Consistency = 'on';
         dsys = d2d(dsys,Ts,options);
         % Map time relative to original Ts to time relative to target Ts
         dsys.SamplingGrid.Time = dsys.SamplingGrid.Time*(vsys.Ts/Ts);
         vsys = ssInterpolant(dsys,vsys.Interpolation,vsys.Extrapolation);
      end

   end

end


