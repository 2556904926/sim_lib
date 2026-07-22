classdef (Hidden) SensitivityTransfer < ctrlguis.csdesignerapp.data.responses.internal.ResponseConfiguration
    % Class for sensitivity transfer responses
    
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
        % them as loop opening locations, you can specify the minimum loop gain
        % for the "q" loop with the "alpha" loop open using
        %    R = TuningGoal.MinLoopGain('q',MinGain)
        %    R.Openings = 'alpha';
        Location = cell(0,1);
    end
    
    
    %% Public Methods
    methods
        
        function this = SensitivityTransfer(Location)
            narginchk(1,1)
            try
                this.Location = Location;
            catch ME
                throw(ME)
            end
        end
    end
    
    %% Set/Get Methods
    methods
        
        function this = set.Location(this,Value)
            % SET function for Location
            [ok,this.Location] = ltipack.isNameList(Value);
            if ~ok
                 error(message('Controllib:general:UnexpectedError','Invalid location channel name specified.'));
            end
        end
        
    end
    
    %% Implementation of abstract methods
    methods (Access = protected)
               
        function L = getResponse_(this,CL)
            % Computes scaled senesitivty transfer from location
            SensLoc = this.Location;
            L = getSensitivity(CL,SensLoc,this.Openings,this.Models);
        end
        
        function DisplayText = getDisplayPreviewText_(this)
            % Sensitivity Transfer Function
            TypeSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('type', ...
                getString(message('Control:designerapp:ResponseTypeSensitivityTransferFunction')));
            % Name Label, Response Name
            NameSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayName')), this.Name);
            % Location Label, Locations
            LocationSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('section', ...
                getString(message('Control:designerapp:DisplayLocation')),this.Location);
            % If exist, Opening Label, Openings
            OpeningsSection = ctrlguis.csdesignerapp.utils.internal.createDisplayText('section', ...
                getString(message('Control:designerapp:DisplayOpening')),this.Openings);
            % Construct Display Text
            DisplayText = [  TypeSection, ...
                NameSection, ...
                LocationSection, ...
                OpeningsSection ];
        end
        
    end
    %% LOAD/SAVE
    methods 
        function S = saveSession(this)
            S.Name = this.Name;
            S.Location = this.Location;
            S.Models = this.Models;
            S.Openings = this.Openings;
            S.Type = 'SensitivityTransfer';
        end
    end
end
