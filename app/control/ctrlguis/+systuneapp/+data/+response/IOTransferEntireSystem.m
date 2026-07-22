classdef (Hidden) IOTransferEntireSystem < systuneapp.data.response.Generic
   % Class for input output transfer responses
   
   % Copyright 2009-2013 The MathWorks, Inc.
   
   properties
   end
   
   methods
      % Constructor
      function this = IOTransferEntireSystem()
      end
      
      function T = getValue(this,CL)
         % Computes scaled closed-loop transfer from inputs to outputs
         if isa(CL,'slTuner')
            T = getIOTransfer(CL,CL.getPointNames,CL.getPointNames,this.Openings,this.Models);
         else
            T = CL;  % genss
         end
         T = sminreal(getValue(T,'usample'));
         T.Name = this.Name;
      end
      
      function DisplayText = getDisplayPreviewText(this)
         % I/O Transfer Function
         TypeSection = systuneapp.util.createDisplayText('type', ...
            getString(message('Control:systunegui:ResponseTypeIOTransferFunction')));
         % Name Label, Response Name
         NameSection = systuneapp.util.createDisplayText('line', ...
            getString(message('Control:systunegui:DisplayName')), this.Name);
         % Entire System label
         SystemSection = systuneapp.util.createDisplayText('type', ...
            getString(message('Control:systunegui:ResponseTypeEntireSystemTransferFunction')));
         % If exist, Opening Label, Openings
         OpeningsSection = systuneapp.util.createDisplayText('section', ...
            getString(message('Control:systunegui:DisplayOpening')),this.Openings);
         % Construct Display Text
         DisplayText = [  TypeSection, ...
            NameSection, ...
            SystemSection, ...
            OpeningsSection ];
      end
   end
end
