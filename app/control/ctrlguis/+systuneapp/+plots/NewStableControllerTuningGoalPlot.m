classdef NewStableControllerTuningGoalPlot < systuneapp.plots.NewTuningGoalPlot
   %StableControllerTuningGoalPlot Class for ControllerPoles tuning goal plots.
   
   %   Copyright 1986-2016 The MathWorks, Inc.
   
   
   %% Public methods
   methods
      
      % Constructor:
      function this = NewStableControllerTuningGoalPlot(TuningGoalWrapper,ControlDesignData)
         this@systuneapp.plots.NewTuningGoalPlot(TuningGoalWrapper,ControlDesignData);
      end     
      
      % Update System
      function updateSystem(this)
         % Called during CompensatorValueChanged and PlantValueChanged
         TG = this.TuningGoalWrapper.TuningGoal;
         Sys = getSystem(this);
         % Delete plot if the tuned block is removed
         try
            getBlockValue(Sys,TG.Block);
            this.TGPlot.System = Sys;            
         catch
            delete(this)
         end
      end
      
   end
   
   
end