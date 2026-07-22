classdef (CaseInsensitiveProperties, TruncatedProperties, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      GriddedLPVSS < lpvss & GriddedLTVSS
   %GriddedLPVSS  Gridded LPV Model.

   %   Copyright 2022-2023 The MathWorks, Inc.

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)

      function T = toClosed(~)
         T = 'lpvss';
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
      
      function sys = GriddedLPVSS(varargin)
         sys = sys@lpvss(varargin{:});
         if nargin>0
            % Access grid info from function workspace
            S = functions(varargin{2});
            try
               INFO = S.workspace{1}.INFO;
               Grid = INFO.Grid;
               sys.Grid = Grid;
               sys.Interpolation = INFO.Interpolation;
               sys.Extrapolation = INFO.Extrapolation;
            catch
               error(message('Control:ltiobject:LTV13'))
            end
         end
      end

   end

   methods (Access = protected)

      function sysOut = ltvss_(sys)
         sysOut = ltvss_@lpvss(sys);
      end

      function sysOut = lpvss_(sys)
         sysOut = lpvss(sys.ParameterName_,sys.DataFunction_,...
            getTs_(sys),sys.t0_,sys.p0_);
         sysOut.StateName_ = sys.StateName_;
         sysOut.StatePath_ = sys.StatePath_;
         sysOut.StateUnit_ = sys.StateUnit_;
         sysOut.TimeUnit_ = sys.TimeUnit_;
      end

   end

   methods(Static, Hidden)

      function sys = loadobj(sys)
         if sys.Version_<29
            % Update data function
            sys.DataFunction_ = ltvpack.interp.upgradeDF(sys.DataFunction_,true,sys.Version_);
            if ~any(diff(sys.Grid.Time(:)))
               % No longer adding Time field when no dependent on time.
               sys.Grid = rmfield(sys.Grid,'Time');
            end
         end
         if isa(sys,'GriddedLPVSS')
            sys.Version_ = ltipack.ver();
         end
      end

   end

end


