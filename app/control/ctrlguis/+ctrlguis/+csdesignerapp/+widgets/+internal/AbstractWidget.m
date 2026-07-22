classdef (Abstract = true) AbstractWidget < handle &  matlab.mixin.Heterogeneous
    % Abstract class to provide interface for moveable widgets on graphical
    % editors

    % Copyright 2022 The MathWorks, Inc.
    
    properties
        % Graphical Editor object
        Parent      
        % Preference related properties
        ShowSystemPZ = 'on'
    end

    properties (Access = protected)       
        % Graphical Editor Data object
        Data                 
        
        % Transaction to determine undo and redo of widget movements
        Transaction
    end
    
    methods
        %% Public API
        function this = AbstractWidget(Parent, Data)
            % Set parent, data and axes
            this.Parent = Parent;
            
            this.Data = Data;
        end
    end
    
    methods (Access = public)
        function start(~)
            % Default implementation for widgets that do not want to move
        end
        
        function stop(~)
            % Default implementation for widgets that do not want to move
        end
        
        function move(~)
            % Default implementation for widgets that do not want to move
        end
        
        function hover(~)
            % Default implementation for widgets that do not want to move
        end
        
        function setRefreshMode(this, RefreshMode)
            setRefreshMode(this.Parent,RefreshMode);
        end
    end
    
    methods (Abstract = true)
        % Each widget should implement this method that returns handles to
        % the HG objects that make up the widget
        getHG(this)
    end
end