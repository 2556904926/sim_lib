classdef (Hidden) Generic < matlab.mixin.Heterogeneous
   % Base class for tuning requirements.

%   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Requirement name (string).
      Name = '';
   end
   
   methods
      
      function this = set.Name(this,Value)
         % SET function for Name
         if ischar(Value) && (isempty(Value) || isrow(Value))
            this.Name = Value;
         else
            error(message('Control:tuning:TuningReq1'))
         end
      end
      
   end
   
   methods (Sealed)
      
      function value = get(this,prop)
         % GET method for tuning goals.
         if isstring(prop) || (ischar(prop) && isrow(prop))
            try
               value = this.(prop);
            catch ME
               throw(ME)
            end
         else
            error(message('Control:tuning:TuningReq20'))
         end
      end
      
      function this = set(this,varargin)
         % SET method for tuning goals.
         narg = numel(varargin);
         if rem(narg,2)>0
            error(message('Control:tuning:TuningReq21'))
         end
         for ct=1:2:narg
            prop = varargin{ct};
            if isstring(prop) || (ischar(prop) && isrow(prop))
               try
                  this.(prop) = varargin{ct+1};
               catch ME
                  throw(ME)
               end
            else
               error(message('Control:tuning:TuningReq20'))
            end
         end
      end
      
      function varargout = evalGoal(this,T)
         %EVALGOAL  Evaluates tuning goal for a given design.
         %
         %   [HSPEC,FVAL] = EVALGOAL(R,CL) evaluates the requirement R for the control
         %   system design CL. The first input R can be any TuningGoal object and the
         %   second input CL is a @genss or @slTuner model of the control system
         %   (typically the result of tuning the control system parameters with
         %   SYSTUNE). EVALGOAL returns the normalized value FVAL of the requirement
         %   and the transfer function HSPEC used to compute this value. For example,
         %   if R limits the gain of some transfer function H(s) according to
         %       || H(jw) || <= | gmax(jw) |
         %   then HSPEC(s) is related to H(s) and the max gain profile gmax(s) by
         %       HSPEC(s) = (1/gmax(s)) H(s)
         %   and FVAL is the peak gain of HSPEC. The goal R is met if and only if
         %   FVAL<=1.
         %
         %   Note: For MIMO feedback loops, the LoopShape, MinLoopGain, MaxLoopGain,
         %   Margins, Sensitivity, and Rejection goals are sensitive to the relative
         %   scaling of each SISO loop. SYSTUNE tries to balance the overall loop
         %   transfer matrix while enforcing such goals. The optimal loop scaling
         %   is cached in the tuned closed-loop model CL returned by SYSTUNE. For
         %   consistency, EVALGOAL(R,CL) applies the same scaling when evaluating
         %   the goals above. To ignore this scaling, use
         %      [HSPEC,FVAL] = EVALGOAL(R,clearTuningInfo(CL))
         %   Note that modifying CL may compromise the scaling validity.
         %
         %   See also viewGoal, TuningGoal, systune, genss, slTuner.
         narginchk(2,2)
         if ~isscalar(this)
            error(message('Control:tuning:TuningEval1'))
         elseif ~(isa(T,'genss') || isa(T,'slTuner') || isa(T,'slTunable'))
            error(message('Control:tuning:TuningView1'))
         end
         try
            [varargout{1:nargout}] = evalSpec_(this,T);
         catch ME
            throw(ME)
         end
      end
      
      function viewGoal(this,T)
         %VIEWGOAL  View tuning goal and validate design against tuning goals.
         %
         %   VIEWGOAL(R) shows a graphical view of the requirement R. The input
         %   R can be any tuning goal object (see TuningGoal). You can also
         %   specify a vector of tuning goal objects, in which case all goals
         %   are shown in a single figure.
         %
         %   VIEWGOAL(R,CL) validates the design CL against the tuning goal(s) R.
         %   CL is a @genss or @slTuner model of the control system and is
         %   typically the result of tuning the control system parameters with
         %   SYSTUNE.
         %
         %   Note: For MIMO feedback loops, the LoopShape, MinLoopGain, MaxLoopGain,
         %   Margins, Sensitivity, and Rejection goals are sensitive to the relative
         %   scaling of each SISO loop. SYSTUNE tries to balance the overall loop
         %   transfer matrix while enforcing such goals. The optimal loop scaling
         %   is cached in the tuned closed-loop model CL returned by SYSTUNE. For
         %   consistency, VIEWGOAL(R,CL) takes this scaling into account and plots
         %   the scaled open-loop response or sensitivity. To omit this scaling, use
         %      VIEWGOAL(R,clearTuningInfo(CL))
         %   Note that modifying CL may compromise the scaling validity.
         %
         %   See also evalGoal, TuningGoal, systune, genss, slTuner.
         narginchk(1,2)
         ni = nargin;
         if ni<2
            T = [];
         end
         % Find requirements without view
         hasPlot = arrayfun(@hasView_,this);
         if ~all(hasPlot)
            warning(message('Control:tuning:TuningView3'))
         end
         this = this(hasPlot);
         % Determine number of plots
         nViews = numel(this);
         if nViews ~= 0
             f = gcf;
             clf(f);
             t = tiledlayout(f,'flow');
         end
         for ct=1:nViews
             ReqObj = this(ct);
             if isempty(ReqObj.Name)
                 ReqObj.Name = getString(message('Control:tuning:strLoopView6',ct));
             end
             viewSpec_(ReqObj,T,nexttile(t));
         end
      end
   end
   
   methods (Access = protected)
      
      function boo = hasView_(~)
         boo = true;
      end
      
      function viewSpec_(this,CL,ax)
          % Default implementation
          TGPlot = controllib.chart.internal.utils.TuningGoalPlotManager(this,CL);
          createPlot(TGPlot,ax);
      end
      
      [H,fObj] = evalSpec_(this,T)
      
   end
   
   methods (Hidden)
       
      % Get the type to set Style (For Tuning Goal Plot API)
      function Type = getComparisonStyleType(~)
         Type = 'LineStyle';
      end

      function L = addLocalPlotListeners(~,~,~)
          L = [];
      end
 
      
      function this = checkGoal(this,varargin)
         % Check/update goal before running SYSTUNE
      end
      
      function S = getID(this)
         % Construct string that helps identify requirement for debugging purposes
         if isempty(this.Name)
            [~,Type] = strtok(class(this),'.');
            S = getString(message('Control:tuning:TuningReq9',Type(2:end)));
         else
            S = getString(message('Control:tuning:TuningReq10',this.Name));
         end
      end
      
      % OBSOLETE
      function show(this)
         viewGoal(this)
      end
      
      function Msg = resolveSignalError(this,ErrID,MisMatch,SignalList)
         % Manages errors related to unresolved or ambiguous identifiers in
         % tuning goals.
         if isempty(MisMatch)
            Msg = '';
         else
            iMatch = MisMatch.iMatch;
            if isempty(iMatch)
               % No match
               Msg = message([ErrID '1'],getID(this),MisMatch.ID);
            else
               % Multiple matches. List the first two
               Matches = strrep(SignalList(iMatch(1:2)),'[]','');
               Msg = message([ErrID '2'],getID(this),MisMatch.ID,Matches{:});
            end
         end
      end
      
   end
   
   methods (Hidden, Sealed)
      % OBSOLETE
      function varargout = evalSpec(this,T,Info)
         narginchk(2,3)
         if ~isscalar(this)
            error(message('Control:tuning:TuningEval1'))
         elseif ~(isa(T,'genss') || isa(T,'slTuner') || isa(T,'slTunable'))
            error(message('Control:tuning:TuningView1'))
         end
         if nargin==3
            if ~isempty(Info)
               if isstruct(Info) && isfield(Info,'Runs')
                  % INFO struct from LOOPTUNE
                  Info = Info.Runs;
               elseif ~(isstruct(Info) && isfield(Info,'LoopScaling'))
                  error(message('Control:tuning:TuningView2'))
               end
               % Select best result
               Info = TuningGoal.selectBestRun(Info);
            end
            % Cache scaling data in T
            if isa(T,'genss')
               T = setTuningInfo(T,Info);
            else
               setTuningInfo(T,Info)
            end
         end
         % Check array compatibility
         try
            [varargout{1:nargout}] = evalSpec_(this,T);
         catch ME
            throw(ME)
         end
      end
      
      function viewSpec(this,T,Info)
         narginchk(1,3)
         ni = nargin;
         if ni<2
            T = [];
         else
            if ~(isa(T,'genss') || isa(T,'slTuner') || isa(T,'slTunable'))
               error(message('Control:tuning:TuningView1'))
            end
            if ni==3
               if ~isempty(Info)
                  if isstruct(Info) && isfield(Info,'Runs')
                     % INFO struct from LOOPTUNE
                     Info = Info.Runs;
                  elseif ~(isstruct(Info) && isfield(Info,'LoopScaling'))
                     error(message('Control:tuning:TuningView2'))
                  end
                  % Select best result
                  Info = TuningGoal.selectBestRun(Info);
               end
               % Cache scaling data in T
               if isa(T,'genss')
                  T = setTuningInfo(T,Info);
               else
                  setTuningInfo(T,Info)
               end
            end
         end
         try
            viewGoal(this,T)
         catch ME
            throw(ME)
         end
      end
      
   end
   
end
