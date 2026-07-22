classdef (Hidden) LoopTransfer < systuneapp.data.response.Generic
    % Class for loop transfer responses
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    properties
      % Locations where open-loop transfer is measured (string or string vector).
      %
      % This property specifies which open-loop transfer function the requirement
      % applies to. In MATLAB, use LOOPSWITCH blocks to mark the loop opening 
      % locations of interest and refer to these locations by name to identify
      % a particular open-loop transfer function. In Simulink, use the signal 
      % names in Controls, Measurements, and Switches to refer to a particular 
      % open-loop transfer function (see slTunable).
      %
      % Example: If the plant has two measurements q and alpha and you register
      % them as loop opening locations, you can specify the maximum loop gain
      % for the "q" loop with the "alpha" loop open using
      %    R = TuningGoal.MaxLoopGain('q',MaxGain)
      %    R.Openings = 'alpha';
      Location = cell(0,1);

    end
    
    methods
        
        function this = LoopTransfer(Location)
            narginchk(1,1)
            try
                this.Location = Location;
            catch ME
                throw(ME)
            end
        end
        
        function this = set.Location(this,Value)
            % SET function for Location
            [ok,this.Location] = ltipack.isNameList(Value);
            if ~ok
                ctrlMsgUtils.error('Control:tuning:LoopShapeReq7')
            end
        end
        function L = getValue(this,CL)
            % Computes scaled closed-loop transfer from inputs to outputs
            LoopChannels = this.Location;
            if isempty(LoopChannels)
                % Grab all loop channels
                error(message('Control:tuning:LoopShapeReq11'))
            end
            L = getLoopTransfer(CL,LoopChannels,+1,this.Openings,this.Models);
            L = sminreal(getValue(L,'usample'));
            L.Name = this.Name;
        end
       
       function DisplayText = getDisplayPreviewText(this)
           % Loop Transfer Function
           TypeSection = systuneapp.util.createDisplayText('type', ... 
               getString(message('Control:systunegui:ResponseTypeLoopTransferFunction')));           
           % Name Label, Response Name
           NameSection = systuneapp.util.createDisplayText('line', ...
               getString(message('Control:systunegui:DisplayName')), this.Name);           
           % Location Label, Locations
           LocationSection = systuneapp.util.createDisplayText('section', ...               
               getString(message('Control:systunegui:DisplayLocation')),this.Location);
           % If exist, Opening Label, Openings
           OpeningsSection = systuneapp.util.createDisplayText('section', ...
                    getString(message('Control:systunegui:DisplayOpening')),this.Openings);                      
           % Construct Display Text
           DisplayText = [  TypeSection, ...
                            NameSection, ...
                            LocationSection, ...
                            OpeningsSection ];         
       end                           
    end   
end
