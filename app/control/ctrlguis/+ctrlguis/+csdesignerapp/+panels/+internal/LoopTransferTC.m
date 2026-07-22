classdef LoopTransferTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for Loop transfer signals
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties
        Name
        LocationListPanel
        OpeningListPanel
        Data
        CDD
        Create
        Listener
    end
    
    methods(Access = public)
        function this = LoopTransferTC(CDD,Data)
            import controllib.widget.internal.signallist.SignalListPanel

            this = this@controllib.widget.internal.tc.AtomicComponent;
            this.CDD = CDD;
            this.Data = Data;
            this.LocationListPanel = SignalListPanel(Data,'Location','Location',this.Data.LocationSignalLabel);
            this.OpeningListPanel = SignalListPanel(Data,'Openings','Openings',this.Data.OpeningSignalLabel);       

            registerDataListeners(this.LocationListPanel, ...
                addlistener(Data,'Openings','PostSet', ...
                @(src,data)createFlatContextMenu(this.LocationListPanel)));
            registerDataListeners(this.OpeningListPanel, ...
                addlistener(Data,'Location','PostSet', ...
                @(src,data)createFlatContextMenu(this.OpeningListPanel)));
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = controllib.widget.internal.responseplot.LoopTransferGC(this);
        end
        function delete(this)
           delete(this.LocationListPanel);
           delete(this.OpeningListPanel);
           delete(this.Listener);
        end        
    end   
   
    methods(Access = protected)
        function mUpdate(this)
            updateUI(this.LocationListPanel);
            updateUI(this.OpeningListPanel);
        end
    end
end
