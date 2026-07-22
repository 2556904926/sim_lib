classdef (Hidden) ScaledLoop < TuningGoal.GenericLoop
   % Manages feedback loop scaling option in tuning goals.
   
   %   Copyright 2009-2014 The MathWorks, Inc.
   
   properties
      % Automatic scaling of feedback loop signals ('on'/'off', default='on').
      %
      % When set to 'on', the feedback channels in MIMO feedback loops are 
      % automatically rescaled to equalize the off-diagonal terms (loop 
      % interactions) in the open-loop response or sensitivity function. 
      % Set this property to 'off' to disable such scaling and work with  
      % the raw open-loop response or sensitivity function.
      LoopScaling = 'on';
   end
   
   methods
      
      function this = set.LoopScaling(this,Value)
         % SET function for LoopScaling
         Value = ltipack.matchKey(Value,{'on','off'});
         if isempty(Value)
            error(message('Control:tuning:LoopScaling1'))
         end
         this.LoopScaling = Value;
      end
      
      function [Ls,ShowScaled] = applyLoopScaling(this,L,Info)
         % When necessary and possible, applies loop scaling from tuning
         % to loop transfer L or some related transfer function such as
         % the sensitivity function.
         ShowScaled = false;
         Ls = L;
         if size(L,1)>1 && ~isempty(Info) && strcmp(this.LoopScaling,'on')
            try %#ok<TRYNC>
               % Note: Info.LoopScaling may contain full signal paths in Simulink
               iL = ltipack.resolveSignalID(this.Location,Info.LoopScaling.InputName,true);
               D = Info.LoopScaling(iL,iL).d;
               Ls = D\L*D;
               ShowScaled = true;
            end
         end
      end
   

   end
   
   methods (Static)
      
      function Color = getUnscaledColor()
         % Light-blue color for plotting response without loop scaling
         hsvcolor = rgb2hsv([0 0 1]);
         Color = hsv2rgb(hsvcolor.*[1,.2,1]);
      end
      
   end
   
end
