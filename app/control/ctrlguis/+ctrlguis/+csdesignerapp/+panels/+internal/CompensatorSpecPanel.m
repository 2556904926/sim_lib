classdef CompensatorSpecPanel < controllib.ui.internal.dialog.AbstractContainer & ...
        matlab.mixin.SetGet
    
    properties
        Dlg
        Panel
        Widgets
        
        SpecData
        Response
        Compensator
        OpenLoopPlant
        
       
        Parent
        Row
        Column
        Layout
        
        UIListeners
        
%         Name
%         Title
    end
    
    events
        SpecDataChanged
    end
    
    methods
        
        function this = CompensatorSpecPanel(Parent)
            % Superclass constructor
            this = this@controllib.ui.internal.dialog.AbstractContainer;
            
            % resassign property values
            this.Parent = Parent;
        end
        
        function updateUI(this)
            disableUIListeners(this);
            
            if isempty(this.SpecData)
                createDefaultSpecData(this);
            end
            
            if ~isempty(this.Response) && ~isempty(this.Compensator) && isvalid(this.Response) && isvalid(this.Compensator)
                refreshUI(this);
            end
            this.notify('SpecDataChanged');
            enableUIListeners(this);
        end
        
        
        %% Set/Get Methods
        function SpecData = get.SpecData(this)
            SpecData = this.SpecData;
        end
        
        function set.SpecData(this, SpecData)
            % Get spec data from parent and set self
            this.SpecData = SpecData;
        end
        
        function set.Response(this, Response)
            % Recompute order when response changes
            this.Response = Response;
        
        end
        
        function set.Compensator(this, Compensator)
            % Recompute order when response changes
            this.Compensator = Compensator;
        end
        
        function OLNominal = get.OpenLoopPlant(this)
            OLNominal = [];
            if ~isempty(this.Response) && ~isempty(this.Compensator)
                OLNominal = utCreateLTI(getOpenLoopPlant(this.Response, this.Compensator));
            end
        end
        
        function pnl = get.Panel(this)
            pnl = this.Layout;
        end
    end
    
    methods (Access = protected)
        %% UI Methods
        function container = createContainer(this)
            
            % creating the container to be parented to a uipanel
            createLayout(this);
            
            % creating all relevant widgets - in respective subclasses
            createWidgets(this);
            
            container = this.Layout;            
        end
        
        function createLayout(this)
            % Creating a grid layout for the panel
            this.Layout = uigridlayout(this.Parent, [4, 3]);
            this.Layout.Padding = 10;
            this.Layout.Scrollable = 'on';
            this.Layout.RowHeight = {'fit', 22, 'fit', 'fit'};
            this.Layout.ColumnWidth = {'1x', '1x', 'fit'};
            this.Widgets.Layout = this.Layout;
        end        
    end
    methods (Abstract = true, Access = protected)
        refreshUI(this);
        createDefaultSpecData(this);
    end
end