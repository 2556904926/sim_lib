classdef (Hidden) TunableBlock < handle & matlab.mixin.Copyable
   % Configuration data for tunable blocks.
   
   % Copyright 2013 The MathWorks, Inc.
   
   properties(Access = public, SetObservable)
      Name
      Ts
      BlockPath
   end
   properties(Access = private, SetObservable)
      Data_
   end
   properties(Access = public, Hidden = true)
      SupportGenss = true;
   end
   methods (Access = public)
      
      %% Constructor
      function this = TunableBlock(sys)
         sysName = sys.Name;
         if ~isParametric(sys)
            sys = tunableSS(sysName,sys);
         end
         this.setParameterization(sys);
         this.Name = sysName;
         this.BlockPath = sysName;
         if isa(sys,'DynamicSystem')
            this.Ts = sys.Ts;
         else
            this.Ts = [];
         end
      end
      
      function Value = getValue(this)
         Value = getValue(this.Data_);
      end
      
      function setValue(this,S)
         this.Data_ = setBlockValue(this.Data_,S);
         this.notify('ParameterizationChanged');
      end
      
      function setParameterization(this,TC)
         this.Data_ = TC;
         this.notify('ParameterizationChanged');
      end
      
      function TC = getParameterization(this)
         TC = this.Data_;
      end
      
      function [ny,nu] = iosize(this)
         [ny, nu] = iosize(this.Data_);
         if nargout==1
            ny = [ny nu];
         end
      end
      
      function DisplayText = getDisplayPreviewText(this)
         DisplayText = [ ...
            systuneapp.util.createDisplayText('type', ...
            getString(message('Control:systunegui:DisplayTunableBlock'))), ...
            systuneapp.util.createDisplayText('line', ...
            getString(message('Control:systunegui:DisplayName')),this.Name), ...
            systuneapp.util.createDisplayText('line', ...
            getString(message('Control:systunegui:DisplayTs')),this.Ts), ...
            systuneapp.util.createDisplayText('line', ...
            getString(message('Control:systunegui:DisplayValue')), ...
            systuneapp.util.createDisplayBlock(this)), ...
            ];
      end
      
   end
   methods (Access = private)
      
   end
   
   events
      ParameterizationChanged
   end
end
