classdef DesignDataInterface < handle
    %% Common data interface mixin.
    
    %  Copyright 2021 The MathWorks, Inc.
    
    %% Abstract public methods
    methods(Abstract)
        name = getArchitectureName(this)
        fcn = getAddSignalFcnName(this)
        point = resolveSignalID(this,signalId,varargin)
        tunedBlockNames = getTunedBlockNames(this)
        tunableBlock = getTunableBlock(this)
        tunableBlockPath = getTunableBlockPath(this)
    end

    %% Template public methods
    methods
        function icon = getArchitectureIcon(this) %#ok<MANU> 
            icon = [];
        end
    end
end