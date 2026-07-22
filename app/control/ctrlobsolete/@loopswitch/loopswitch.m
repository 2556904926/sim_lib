classdef (CaseInsensitiveProperties, TruncatedProperties, ...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      loopswitch < AnalysisPoint
   %LOOPSWITCH  Create switch for opening and closing feedback loops.
   %
   %   This function is obsolete, use AnalysisPoint instead.
   %
   %   S = LOOPSWITCH(NAME) creates a switch block S for opening/closing a
   %   single-input, single-output feedback loop. The string NAME specifies
   %   the block name.
   %
   %   S = LOOPSWITCH(NAME,N) creates a switch for a MIMO feedback loop
   %   with N channels.
   %
   %   You can combine S with ordinary LTI models and with parametric blocks
   %   to build tunable models of control systems (see GENLTI). By default
   %   the switch S is closed. Set S.Open=true to open the loop at the
   %   switch location. For N-channel switches, you can also set S.Open to
   %   a logical vector with N entries to open only a subset of the feedback
   %   loops. Loop switch blocks are useful to mark loop opening sites and
   %   specify tuning requirements on open-loop responses (see TUNINGGOAL).
   %
   %   Example: Model the feedback loop
   %
   %          r --->O--->[ C ]--->[ G ]---+---> y
   %              - |                     |
   %                +--------[ X ]<-------+
   %
   %   where G=1/(s+2) is the plant model, C is a tunable PI controller, and
   %   X is an open/closed switch.
   %
   %      G = tf(1,[1 2])
   %      C = ltiblock.pid('C','pi')
   %      X = loopswitch('X')
   %      T = feedback(G*C,X)   % closed loop r->y
   %
   %   To open the feedback loop, access the switch block by name and toggle
   %   its "Open" state:
   %
   %      T.Blocks.X.Open = true
   %
   %   See also AnalysisPoint.
   
%   Author(s): P. Gahinet
%   Copyright 1986-2013 The MathWorks, Inc.

   properties (Hidden, Dependent, Transient)
      % Obsoleted in R2013b
      LoopID
   end

   %% PUBLIC METHODS
   methods
      function blk = loopswitch(varargin)
         blk@AnalysisPoint(varargin{:})
      end
      
      % Obsolete properties
      function this = set.LoopID(this,Value)
         this.Location = Value;
      end
      function Value = get.LoopID(this)
         Value = this.Location;
      end
   end
   

   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)
      function displaySize(~,sizes)
         % Display for "size(M)"
         if all(sizes==1)
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeLOOPSWITCH1'))
         else
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeLOOPSWITCH2',sizes(1)))
         end
      end
   end
   
  
   %% HIDDEN INTERFACES
   methods (Hidden)
      % CONTROLDESIGNBLOCK
      function str = getDescription(blk,ncopies)
         % Short description for block summary in LFT model display
         str = getString(message('Control:lftmodel:LoopSwitch2',blk.Name,blk.IOSize_(1),ncopies));
      end
   end
   
   
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for @loopswitch objects
         s = DynamicSystem.updateMetaData(s);
         if isstruct(s)
            % R2013b: LoopID_ -> Location_
            blk = loopswitch(s.Name_,s.IOSize_(1));
            blk.Location_ = string(s.LoopID_(:));
            f = setdiff(fieldnames(s),{'LoopID_','IOSize_','Name_','Version_'});
            for ct=1:numel(f)
               blk.(f{ct}) = s.(f{ct});
            end
         else
            blk = s;
            blk.Location_ = string(s.Location_(:));
            blk.Version_ = ltipack.ver();
         end
      end
      
   end

end
