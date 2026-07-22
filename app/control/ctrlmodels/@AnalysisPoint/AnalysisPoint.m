classdef (CaseInsensitiveProperties, TruncatedProperties, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      AnalysisPoint < DynamicBlock
   %ANALYSISPOINT  Mark points of interest for linear analysis.
   %
   %   AP = AnalysisPoint(NAME) creates a single-channel analysis point. This
   %   is a unit-gain block AP that can be inserted anywhere in a block diagram
   %   to mark a point of interest for linear analysis (see getIOTransfer
   %   and getLoopTransfer) and controller tuning (see TuningGoal). The
   %   string NAME specifies the block name.
   %
   %   AP = AnalysisPoint(NAME,N) creates a multi-channel analysis point with
   %   N channels. This can be used to select a vector-valued signal or bundle
   %   several points of interest together.
   %
   %   Analysis points implicitly create additional input and output signals
   %   as well as locations where to open feedback loops:
   %
   %                  +--> out         in -->+
   %                  |                      |
   %              ----+------>[opening]----->O------>
   %
   %   When analyzing or tuning your system, use the name(s) in AP.Location
   %   to access these signals or open loops at these locations. By default,
   %   the names in AP.Location are derived from the block name, NAME. For
   %   example, {'X(1)' ; 'X(2)' ; ...} for an analysis point named 'X'.
   %   Use getPoints to get the list of analysis point locations.
   %
   %   Example: Model the feedback loop
   %
   %                            u
   %          r --->O--->[ C ]----->[ G ]---+---> y
   %              - |                       |
   %                +-----------------------+
   %
   %   where G=1/(s+2) is the plant model, C is a tunable PI controller, and
   %   the control signal "u" is a point of interest.
   %
   %      G = tf(1,[1 2])
   %      C = tunablePID('C','pi')
   %      AP = AnalysisPoint('u')
   %      T = feedback(G*AP*C,1)   % closed loop r->y
   %
   %   To compute the open-loop response L=C*G measured at "u", use
   %
   %      L = getLoopTransfer(T,'u',-1)
   %
   %   Similarly, to specify the desired loop shape for L when tuning C,
   %   use
   %
   %      R = TuningGoal.LoopShape('u',tf(1,[1 0]))
   %
   %   See also getPoints, getIOTransfer, getLoopTransfer, TuningGoal,
   %   ControlDesignBlock, genlti.
   
   %   Author(s): P. Gahinet
   %   Copyright 1986-2014 The MathWorks, Inc.
   
   properties (Dependent)
      % Points of interest (string vector).
      %
      % This property identifies the point(s) of interest by name. Its
      % value is a cell array of strings with one name per channel.
      % The default names are derived from the block name, for example,
      % {'X(1)' ; 'X(2)' ; ...} for an analysis point named 'X'. Use
      % these names to refer to the input and output signals associated
      % with the analysis point, or to open feedback loops at the
      % corresponding locations. See getIOTransfer, getLoopTransfer, and
      % TuningGoal for details.
      Location
      
      % Flag for loop openings (default=false).
      %
      % This property tracks when a loop is open at the analysis point.
      % For example, consider the feedback loop
      %
      %          r --->O--->[ C ]--->[ G ]---+---> y
      %              - |                     |
      %                +--------[ X ]<-------+
      %
      % modeled by
      %
      %      G = tf(1,[1 2])
      %      C = tunablePID('C','pi')
      %      X = AnalysisPoint('X')
      %      T = feedback(G*C,X);
      %
      % You can get the transfer function from r to y with the feedback loop
      % open at X using:
      %
      %      Try = getIOTransfer(T,'r','y','X')
      %
      % In the resulting GENSS model, the analysis point "X" is marked
      % open, that is, Try.Blocks.X.Open is true.
      %
      % For multi-channel analysis points, this property contains a logical
      % vector with as many entries as channels.
      Open
   end

   properties (Access=protected)
      Location_ = strings(0,1);
      Open_;
   end
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genss';
      end

   end

   %% PUBLIC METHODS
   methods
      
      function blk = AnalysisPoint(name,N)
         ni = nargin;
         if ni==0
            blk.IOSize_ = [0 0];
         else
            if ~isvarname(name)
               error(message('Control:lftmodel:BlockName1'))
            end
            blk.Name = name;
            if ni<2
               N = 1;
            elseif ~(isnumeric(N) && isscalar(N) && isreal(N) && ...
                  N>=0 && N<Inf && rem(N,1)==0)
               error(message('Control:lftmodel:AnalysisPoint9'))
            end
            blk.IOSize_ = [N N];
            blk.Ts_ = 0;
            blk.Open_ = false(N,1);
         end
      end
      
      function Value = get.Location(blk)
         Value = blk.Location_;
         if isempty(Value)
            % Default: Channels named after block
            Value = localMakeID(blk.Name,blk.IOSize_(1));
         end
         Value = cellstr(Value);
      end
      
      function Value = get.Open(blk)
         Value = blk.Open_;
      end
      
      function blk = set.Location(blk,Value)
         % SET method for Location property
         N = blk.IOSize_(1);
         if isempty(Value)
            % Resetting name to default
            blk.Location_ = strings(0,1);
         else
            if ischar(Value) && isrow(Value)
               Value = localMakeID(Value,N);
            elseif isstring(Value) || iscellstr(Value)
               Value = string(Value(:));
               if any(Value=="")
                  error(message('Control:lftmodel:AnalysisPoint5'))
               elseif isscalar(Value)
                  Value = localMakeID(Value,N);
               elseif numel(Value)~=N
                  error(message('Control:lftmodel:AnalysisPoint3'))
               elseif N>1 && numel(unique(Value))~=N
                  error(message('Control:lftmodel:AnalysisPoint4'))
               end
            else
               error(message('Control:lftmodel:AnalysisPoint3'))
            end
            blk.Location_ = Value;
         end
      end
      
      function blk = set.Open(blk,Value)
         % SET method for Open property
         if isnumeric(Value)
            Value = (Value ~= 0);
         end
         if ~(islogical(Value) && isvector(Value))
            error(message('Control:lftmodel:AnalysisPoint12'))
         end
         N = blk.IOSize_(1);
         if isscalar(Value)
            Value = Value(ones(N,1),1);
         elseif numel(Value)~=N
            error(message('Control:lftmodel:AnalysisPoint12'))
         end
         blk.Open_ = Value(:);
      end
   end
   

   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)
      
      function displaySize(~,sizes)
         % Display for "size(M)"
         if all(sizes==1)
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeAP1'))
         else
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeAP2',sizes(1)))
         end
      end
      
   end
   
   %% PROTECTED METHODS
   methods (Access = protected)
      
      % Indexing operations (see RedefinesParen)
      function M = parenReference(blk, indexingOperation)
         % Indexing forces conversion to GENSS
         M = parenReference(genss(blk), indexingOperation);
      end

      function M = createLHS(~)
         % Creates LHS in assignment.
         M = genss();
      end
            
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      %% CHARACTERISTICS
      function ns = order_(~)
         % Get number of states.
         ns = 0;
      end
      
      function [a,b,c,d,Ts] = ssdata_(blk,varargin)
         % Quick access to explicit state-space data
         if ~isequal(1,1,varargin{:})
            error(message('Control:ltiobject:access2'))
         end
         N = blk.IOSize_(1);
         M = diag(double(~blk.Open_));
         a = [];  b = zeros(0,N);  c = zeros(N,0);  d = M;  Ts = blk.Ts_;
      end
      
      function sys = getValue_(blk)
         % Returns current value
         sys = ss(blk);
      end
            
      %% ANALYSIS
      function p = pole_(~,varargin)
         p = zeros(0,1);
      end
      
      %% TRANSFORMATIONS
      function blk = chgTimeUnit_(blk,newUnits)
         % Rescale time vector: tnew = sf * told
         if blk.Ts_>0
            blk.Ts_ = tunitconv(blk.TimeUnit,newUnits) * blk.Ts_;
         end
         blk.TimeUnit = newUnits; % direct set
      end
      
      function blk = setValue_(blk,g)
         % G can be a diagonal matrix or static dynamic system
         if isnumeric(g) || (isa(g,'DynamicSystem') && isstatic(g))
            try
               if isnumeric(g)
                  g = double(g);
               else
                  sys = ss(g);   g = sys.d;
               end
            catch %#ok<CTCH>
               error(message('Control:lftmodel:AnalysisPoint10',blk.Name))
            end
         else
            error(message('Control:lftmodel:AnalysisPoint10',blk.Name))
         end
         dg = diag(g);
         if ~(isequal(g,diag(dg)) && isfinite(norm(dg,1)))
            error(message('Control:lftmodel:AnalysisPoint11',blk.Name))
         end
         blk.Open_ = (dg==0);
      end
      
      function blk = conj_(blk)
      end
      
      function sys = uminus_(blk)
         sys = uminus_(genss(blk));
      end
      
      function sys = repmat_(blk,s)
         sys = repmat_(genss(blk),s);
      end
      
   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      % CONTROLDESIGNBLOCK
      function Offset = getOffset(blk)
         % Ensure LFT model is well-posed with all loops open
         % Note: Offset should be zero to support structural analysis (see SMFREAL).
         Offset = zeros(blk.IOSize_);
      end
      
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         str = getString(message('Control:lftmodel:AnalysisPoint6',blk.Name,blk.IOSize_(1),ncopies));
      end
      
      function CS = randSample_(blk,N)
         % Randomly samples AP state. Returns N-by-1 cell array of 
         % logical vectors.
         nch = blk.IOSize_(1);
         States = (rand(nch,N)>0.5);
         CS = cell(N,1);
         for ct=1:N
            CS{ct} = diag(double(States(:,ct)));
         end
      end
      
   end
   
   
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter
         blk = DynamicSystem.updateMetaData(s);
         blk.Location_ = string(s.Location_(:));
         blk.Version_ = ltipack.ver();
      end
      
   end

end


function ID = localMakeID(Name,N)
% Turns string "a" into a(1),a(2),...
ID = string(Name);
if N>1
   ID = (ID + "(") + (1:N)' + ")";
end
end
