classdef (Abstract) AbsPulseTrain < handle
   %ABSTRAIN Abstract class representing test signal specs.
   
   % Author(s): Baljeet Singh 20-Sep-2013
   % Copyright 2013 The MathWorks, Inc.
   
   properties (Access = protected)
      BreakPoints_ = [0 0; 1 1; 4 0; 6 3; 8 1];
   end
   
   events
      StateChanged
   end
   
   methods      
      function val = getTimeSeries(this, offset, T0, Tonset, Ts, Tend)
         % Construct timeseries object representing the input signal.
         % offset: input signal offset to be added.
         % [T0:Ts:Tend]: time vector specs.
         % Tonset: onset of input profile.
         val = pidtool.utPIDcreatePiecewiseConstantSignal(...
            this.BreakPoints_, offset, T0, Tonset, Ts, Tend);
      end
      
      function set.BreakPoints_(this, val)
         this.BreakPoints_ = val;
         notify(this, 'StateChanged');
      end
   end
end
