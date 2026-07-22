classdef varyingGoal < TuningGoal.Generic
   %VARYINGGOAL  Specify tuning goal that varies with design point.
   %
   %   When tuning fixed or gain-scheduled controllers at multiple design
   %   points (operating conditions), you may need to adjust the tuning
   %   goals as a function of operating condition, for example, to relax
   %   performance in some regions of the operating range. The VARYINGGOAL
   %   object lets you construct tuning goals that depend implicitly or
   %   explicitly on the design point.
   %
   %   VG = varyingGoal(FH,P1,P2,...) specifies a variable goal VG using the
   %   template FH and the parameter values P1,P2,... The function handle
   %   FH specifies a function
   %      TG = FH(p1,p2,...)
   %   that evaluates to one of the TuningGoal objects. The numeric arrays
   %   P1,P2,... specify the values of the goal parameters p1,p2,... at
   %   each design point. These arrays must be commensurate with the model
   %   array used for tuning (input to SYSTUNE).
   %
   %   VG = varyingGoal(FH,P1,P2,...,'Prop1',Value1,'Prop2',Value2,...)
   %   specifies additional property name/value pairs for configuring the
   %   goal. For example,
   %      FH = @(w) TuningGoal.Gain('F','V',tf(w,[1 w]))
   %      VG = varyingGoal(FH,WDATA,...
   %                 'Focus',[0 pi/Ts],'Openings','OuterLoop')
   %   configures the varying "Gain" goal to be evaluated in the frequency 
   %   band [0 pi/Ts] with the outer loop opened.
   % 
   %   Note: To make VG inactive at a particular design point, set the
   %   corresponding entries of P1,P2,... to NaN.
   %
   %   Example 1: Suppose you use the following 5x5 grid of design points
   %   to tune your controller:
   %      [alpha,V] = ndgrid(linspace(0,20,5),linspace(700,1300,5))
   %   Suppose the desired gain and phase margins vary with the operating
   %   point (alpha,V). Given 5x5 arrays GM and PM of desired gain and
   %   phase margins, create a variable goal to enforce these margins at
   %   each design point:
   %      FH = @(gm,pm) TuningGoal.Margins('u',gm,pm)
   %      VG = varyingGoal(FH,GM,PM)
   %   To improve traceability, attach the design point information to VG:
   %      VG.SamplingGrid = struct('alpha',alpha,'V',V)
   %   You can use VG as a single tuning goal in SYSTUNE, and you can use
   %   VIEWGOAL to quickly home in on (alpha,V) points that fail to meet
   %   the target margins.
   %
   %   See also TuningGoal, tunableSurface, getGoal, evalGoal, viewGoal, systune.
   
   %   Author(s): P. Gahinet
   %   Copyright 1986-2015 The MathWorks, Inc.
   
   properties (SetAccess = protected)
      % Tuning goal template (function handle).
      %
      % Specifies the tuning goal as a function of one or more parameters
      % whose values change over the operating range. For example,
      %    @(gm,pm) TuningGoal.Margins('u',gm,pm)
      % specifies a stability margins goal with variable gain and phase
      % margin values. The goal parameters (gm,pm) are specified numerically
      % in the "Parameters" property.
      Template
   end
   
   properties (Dependent)
      % Tuning goal parameters (cell array).
      %
      % Numerically specifies tuning goal parameters at each design point.
      % For example, for a variable "margins" goal with template
      %    @(gm,pm) TuningGoal.Margins('u',gm,pm)
      % this property stores {GM,PM} where GM and PM are double arrays
      % containing the desired gain and phase margins at each design point.
      Parameters
   end
   
   properties
      % Property settings (cell array)
      %
      % Cell array of property name/value pairs to be applied to each goal
      % instance. Use this to configure the varying goal, for example, 
      % specify loop openings or the frequency focus.
      Settings = cell(0,1)
   end
   
   properties (Dependent)
      % Grid of design points used for tuning (struct).
      %
      % Structure specifying the design points as an array of values for
      % each sampling variable. Type "help lti.SamplingGrid" for details 
      % and examples. The design points need not lie on a rectangular grid 
      % and can be scattered throughout the operating range. The sizes of 
      % the arrays in "SamplingGrid" and "Parameters" must match.
      SamplingGrid
   end

   properties (Access = protected)
      Parameters_       % cell array
      SamplingGrid_     % ltipack.SamplingGrid
%      GridVectors_       % cached decomposition into rectangular grid
   end
          
   %% PUBLIC METHODS
   methods
      
      function this = varyingGoal(Template,varargin)
         if nargin>0
            if ~isa(Template,'function_handle') || nargin(Template)<=0
               error(message('Control:tuning:varyingGoal1'))
            end
            this.Template = Template;
            try
               % Process P/V pairs
               ipv = find(cellfun(@ischar,varargin),1);
               if ~isempty(ipv)
                  this.Settings = varargin(ipv(1):end);
                  varargin = varargin(1:ipv(1)-1);
               end
               % Store parameter values
               this.Parameters = varargin;
            catch ME
               throw(ME)
            end
         end
      end

      function Value = get.Parameters(this)
         Value = this.Parameters_;
      end
      
      function this = set.Parameters(this,Value)
         narg = nargin(this.Template);
         if ~iscell(Value)
            Value = {Value};
         end
         if numel(Value)~=narg
            error(message('Control:tuning:varyingGoal2',narg))
         elseif ~all(cellfun(@(M) isnumeric(M) && isreal(M),Value))
            error(message('Control:tuning:varyingGoal3'))
         end
         GS = size(Value{1});
         % Check size consistency
         for ct=2:narg
            if ~isequal(size(Value{ct}),GS)
               error(message('Control:tuning:varyingGoal4'))
            end
         end
         this.Parameters_ = Value;
         % Clear SamplingGrid if incompatible
         if ~(isempty(this.SamplingGrid_) || isequal(getSize(this.SamplingGrid_),GS))
            this.SamplingGrid_ = [];
         end
      end
                  
      function Value = get.SamplingGrid(this)
         % GET function for SamplingGrid property
         if isempty(this.SamplingGrid_)
            Value = struct;  % default
         else
            Value = getData(this.SamplingGrid_);
         end
      end
      
      function this = set.Settings(this,Value)
         % SET function for Settings property
         n = numel(Value);
         if n==0
            this.Settings = cell(0,1);
         elseif isa(Value,'cell') && rem(n,2)==0 && ...
               all(cellfun(@isvarname,Value(1:2:n)))
            this.Settings = reshape(Value,[1 n]);
         else
            error(message('Control:tuning:varyingGoal8'))
         end
      end

      function this = set.SamplingGrid(this,Value)
         % SET function for SamplingGrid property
%         this.GridVectors_ = [];
         if isequal(Value,[]) || isequal(Value,struct)
            this.SamplingGrid_ = [];
         else
            try
               G = ltipack.SamplingGrid(Value);
            catch ME
               throw(ME)
            end
            if ~isequal(getSize(G),size(this.Parameters_{1}))
               error(message('Control:tuning:varyingGoal5'))
            end
            this.SamplingGrid_ = G;
%             % Populate GridVectors_ if grid can be decomposed into
%             % rectangular grid without rearrangement
%             GridInfo = ltipack.SamplingGrid.getGridStructure(getData(G));
%             if all(cellfun(@(x) size(x,1),GridInfo.GridVectors)==1) && ...
%                   all(diff(GridInfo.SamplePerm)==1)
%                GV = cat(1,GridInfo.GridVectors{:});
%                this.GridVectors_ = GV(:,2);
%             end
         end
      end
      
      function S = getSize(this)
         % Size of design point grid
         if isempty(this.Parameters_)
            S = [0 0];
         else
            S = size(this.Parameters_{1});
         end
      end
      
   end
   
   methods (Access = protected)
      
      function boo = hasView_(this)
         try
            boo = hasView_(getGoal(this,'index',1));
         catch 
            boo = false;
         end
      end
      
      function [H,fObj] = evalSpec_(this,CL)
         % Evaluates varying requirement at each point in design grid
         % NOTE: CL is a genss or slTuner object with the same array size.
         no = nargout;
         GS = getSize(this);
         CL = genss(CL);
         if ~isequal(nmodels(CL),prod(GS))
            error(message('Control:tuning:TuningEval2'))
         end
         HC = cell(GS);
         fObj = NaN(GS);
         for k=1:numel(HC)
            TG = getGoal(this,'index',k);
            if ~isempty(TG)
               if no>1
                  [HC{k},fObj(k)] = evalSpec_(TG,CL);
               else
                  HC{k} = evalSpec_(TG,CL);
               end
            end
         end
         % Determine I/O size of H
         ix = find(~cellfun(@isempty,HC),1);
         if isempty(ix)
            error(message('Control:tuning:TuningEval3'))
         end
         ios = iosize(HC{ix});
         for k=1:numel(HC)
            if isempty(HC{k})
               HC{k} = NaN(ios);
            end
         end
         H = reshape(stack(1,HC{:}),GS);
         H.SamplingGrid = CL.SamplingGrid;
      end
      
      function viewSpec_(this,CL,ax)
          % Convert into viewSpec_(GoalArray,ModelArray)
          GS = getSize(this);
          nGoals = prod(GS);
          % Evaluate goals
          for ct=nGoals:-1:1
              Goals(ct,1) = getGoal(this,'index',ct);
          end
          Goals = reshape(Goals,GS);
          % Create plot
          if isequal(CL,[])
              % viewGoal(this)
              TGPlot = controllib.chart.internal.utils.TuningGoalPlotManager(Goals);
              setSamplingGrid(TGPlot,this.SamplingGrid)
          else
              % viewGoal(this,CL)
              CL = genss(CL);
              if ~isequal(nGoals,nmodels(CL))
                  error(message('Control:tuning:TuningEval2'))
              end
              % Reconcile sampling grids (plot reads it from CL)
              SG1 = this.SamplingGrid;
              SG2 = CL.SamplingGrid;
              if isequal(SG2,struct)
                  CL.SamplingGrid = SG1;
              elseif ~(isequal(SG1,struct) || isequal(SG1,SG2))
                  error(message('Control:tuning:TuningView4'))
              end
              TGPlot = controllib.chart.internal.utils.TuningGoalPlotManager(Goals,CL);
          end
          createPlot(TGPlot,ax);
      end

   end
   
end
