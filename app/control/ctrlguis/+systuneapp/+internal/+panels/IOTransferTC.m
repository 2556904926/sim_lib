classdef (Hidden) IOTransferTC < controllib.widget.internal.tc.AtomicComponent
    % Tool component for Input-Output Transfer signals
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties
        Name
        InputListPanel
        OutputListPanel
        OpeningListPanel
        Data
        CDD
        Create
        Listener
    end
    
    methods(Access = public)
        function this = IOTransferTC(CDD,Data)
            import controllib.widget.internal.signallist.SignalListPanel

            this = this@controllib.widget.internal.tc.AtomicComponent;
            this.CDD = CDD;
            this.Data = Data;
            % Standard signal types for IOTransfer are 'Input','Output','Openings'
            % Looptune uses the IOTransfer structure but the signal types are
            % 'Location','Location','Openings' 
            %  passivity, weighted passivity and conic sector allows,
            %  input and output signals under output section
            if strcmp(this.Data.Type,'Looptune')
                this.InputListPanel = SignalListPanel(Data,'Location','Input',this.Data.InputSignalLabel);
                this.OutputListPanel = SignalListPanel(Data,'Location','Output',this.Data.OutputSignalLabel);  
            elseif strcmp(this.Data.Type,'ConicSector')
                this.InputListPanel = SignalListPanel(Data,'Input','Input',this.Data.InputSignalLabel);
                this.OutputListPanel = SignalListPanel(Data,'All','Output',this.Data.OutputSignalLabel);                
            else
                this.InputListPanel = SignalListPanel(Data,'Input','Input',this.Data.InputSignalLabel);
                this.OutputListPanel = SignalListPanel(Data,'Output','Output',this.Data.OutputSignalLabel);                  
            end
            this.OpeningListPanel = SignalListPanel(Data,'Openings','Openings',this.Data.OpeningSignalLabel);   
            
            weakInputListPanel = matlab.lang.WeakReference(this.InputListPanel);
            weakOutputListPanel = matlab.lang.WeakReference(this.OutputListPanel);
            weakOpeningListPanel = matlab.lang.WeakReference(this.OpeningListPanel);

            registerDataListeners(this.InputListPanel, ...
                addlistener(Data,'Output','PostSet', ...
                @(src,data)createFlatContextMenu(weakInputListPanel.Handle)));
            registerDataListeners(this.InputListPanel, ...
                addlistener(Data,'Openings','PostSet', ...
                @(src,data)createFlatContextMenu(weakInputListPanel.Handle)));
            
            registerDataListeners(this.OutputListPanel, ...
                addlistener(Data,'Input','PostSet', ...
                @(src,data)createFlatContextMenu(weakOutputListPanel.Handle)));
            registerDataListeners(this.OutputListPanel, ...
                addlistener(Data,'Openings','PostSet', ...
                @(src,data)createFlatContextMenu(weakOutputListPanel.Handle)));
            
            registerDataListeners(this.OpeningListPanel, ...
                addlistener(Data,'Input','PostSet', ...
                @(src,data)createFlatContextMenu(weakOpeningListPanel.Handle)));
            registerDataListeners(this.OpeningListPanel, ...
                addlistener(Data,'Output','PostSet', ...
                @(src,data)createFlatContextMenu(weakOpeningListPanel.Handle)));            
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = controllib.widget.internal.responseplot.IOTransferGC(this);
        end
        function delete(this)
           delete(this.InputListPanel);
           delete(this.OutputListPanel);
           delete(this.OpeningListPanel);
           delete(this.Listener);
        end        
    end
    
    methods(Access = protected)
        function mUpdate(this)
            updateUI(this.InputListPanel);
            updateUI(this.OutputListPanel);
            updateUI(this.OpeningListPanel);
        end
    end
end
