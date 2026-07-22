classdef AxesView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    properties (Access = private)
        Axes
        MagPhase = 1;
        AxesListeners
    end
    
    methods (Access = public)
        function this = AxesView(Parent, Data, AxesGrid, ~)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            % Magnitude or Phase Line?
            if nargin == 4
                this.MagPhase = 2;
            end
            
            this.Axes = AxesGrid;
            Axes = AxesGrid.getAxes;
            for ct=1:numel(Axes)
                set(Axes(ct).XLabel,'Interpreter','none');
                set(Axes(ct).YLabel,'Interpreter','none');
                set(Axes(ct).Title,'Interpreter','none');
            end
            AxesGrid.qeGetStyle.Title.Interpreter = 'none';
            
            % this.AxesListeners = handle.listener(AxesGrid,'DataChanged',@(es,ed)LocalPostSetUnits(this));
        end
        
        function HG = getHG(this)
            HG = getAxes(this.Axes);
            HG = HG(this.MagPhase);
        end
    end
    
    methods (Access = public)
        function start(this)
            
            switch this.Parent.EditMode
                case 'addpz'
%                     setRefreshMode(this, 'normal');
                    PlotAxes = getAxes(this.Axes);
                    PlotAxes = PlotAxes(this.MagPhase);
                    addPZ(this.Parent, PlotAxes);
            end
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            switch this.Parent.EditMode
                case 'addpz'                    
                    setptr(getHGParent(this.Parent),'hand');
            end
            % this.Axes.send('ViewChanged');
        end
  
        function [HoverCursor, Status] = hover(this, varargin)
            Status = '';
            HoverCursor = 'Arrow';
            if strcmpi(this.Parent.EditMode, 'addpz')
                switch this.Parent.EditModeData.Group
                    case {'Real','Complex'}
                        HoverCursor = sprintf('add%s',lower(this.Parent.EditModeData.Root));
                        if strcmpi(this.Parent.EditModeData.Root,'pole')
                            Status = getString(message('Control:compDesignTask:msgLeftClickToAddPole'));
                        else
                            Status = getString(message('Control:compDesignTask:msgLeftClickToAddZero'));
                        end
                    case 'Lead'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddLead'));
                    case 'Lag'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddLag'));
                    case 'Notch'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddNotch'));
                    otherwise
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddPZ'));
                end
            end
        end     
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalPostSetUnits %%%
%%%%%%%%%%%%%%%%%%%%%%%%
function LocalPostSetUnits(Editor)
% Called when changing units 
% Update labels
setlabels(Editor.Axes);

% Redraw plot 
update(Editor.Parent);

end