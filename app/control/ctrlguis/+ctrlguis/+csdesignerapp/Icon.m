classdef Icon < handle
    % Icon component.
    %
    % Example:
    
    % Copyright 2010-2015 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    
    properties (Constant, Hidden, Access = public)
        % Path to resources directory for icons
        Path = fullfile(matlabroot, 'toolbox', 'control', ...
            'ctrlguis', '+ctrlguis', '+csdesignerapp', 'resources');
    end
    
    % ----------------------------------------------------------------------------
    methods (Static)
        function icon = getIcon(filename, Version)
            if nargin == 1
                % Default to version 2
                Version = 2;
            end
            % Helper method to get standard icons.
            iconfile = fullfile(ctrlguis.csdesignerapp.Icon.Path, filename);
            if Version == 2 || Version == 3
                icon = matlab.ui.internal.toolstrip.Icon(iconfile);
            else
                icon = [];
            end
        end
    end
    
    % Architecture icons
    methods (Sealed, Static)
        function icon = CONFIGURATION_1
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config1.png');
        end
        function icon = CONFIGURATION_1_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig1Thumb.png');
        end
        function icon = CONFIGURATION_2
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config2.png');
        end
        function icon = CONFIGURATION_2_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig2Thumb.png');
        end
        function icon = CONFIGURATION_3
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config3.png');
        end
        function icon = CONFIGURATION_3_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig3Thumb.png');
        end
        function icon = CONFIGURATION_4
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config4.png');
        end
        function icon = CONFIGURATION_4_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig4Thumb.png');
        end
        function icon = CONFIGURATION_5
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config5.png');
        end
        function icon = CONFIGURATION_5_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig5Thumb.png');
        end
        function icon = CONFIGURATION_6
            icon = ctrlguis.csdesignerapp.Icon.getIcon('Config6.png');
        end
        function icon = CONFIGURATION_6_THUMB
            icon = ctrlguis.csdesignerapp.Icon.getIcon('SISOConfig6Thumb.png');
        end
    end
end