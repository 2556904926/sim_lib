classdef ResponseInputOutputTransferTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Tool component for Input-Output Transfer response
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(SetObservable,AbortSet)
        Input = {}
        Output = {}
        Openings = {}
    end    
    properties
        IOTransferTC
        ResponseWrapper
        Create
        Type = 'IOTransfer'
        % Dialog labels for signals
        InputSignalLabel = getString(message('Control:designerapp:SignalListInputLabelIOTransfer'));
        OutputSignalLabel = getString(message('Control:designerapp:SignalListOutputLabelIOTransfer'));
        OpeningSignalLabel = getString(message('Control:designerapp:SignalListOpeningLabelIOTransfer'));        
    end
    properties (Transient)
        Listener
    end
    
    methods(Access = public)
        function this = ResponseInputOutputTransferTC(CDD,ResponseWrapper)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.Create = false;
            this.CDD = CDD;

            this.IOTransferTC = ctrlguis.csdesignerapp.panels.internal.IOTransferTC(this.CDD,this); 
            
            if nargin == 1
                this.Create = true;
                ResponseWrapper =  ctrlguis.csdesignerapp.data.responses.internal.Response;
                this.ResponseWrapper=ResponseWrapper;
            else
                this.ResponseWrapper=ResponseWrapper;
                syncData(this)
                weakThis = matlab.lang.WeakReference(this);
                this.Listener = addListenerToSyncData(this.ResponseWrapper,@(es,ed) syncData(weakThis.Handle));
            end
            
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = controllib.widget.internal.responseplot.ResponseInputOutputTransferGC(this);
        end
    end
    
    methods(Access = public)
        function setResponse(this,overwriteExistingResponse)
            arguments
                this
                overwriteExistingResponse = false
            end
            try
                if isempty(this.Input) || isempty(this.Output)
                    error(getString(message(['Control:systunegui:' 'Response' this.Type 'Error'])));
                    return;
                end
                ResponseNames = getResponseName(this.CDD);
                % Check if response name is duplicate and overwrite flag is
                % false
                if any(strcmp(ResponseNames,this.Name)) && ~overwriteExistingResponse
                    error(getString(message('Control:systunegui:ResponseNameConflict',this.Name)));
                    return;
                end
                % Create Response
                Response = ctrlguis.csdesignerapp.data.responses.internal.IOTransfer(this.Input,this.Output);
                Response.Openings = this.Openings;
                Response.Name = this.Name;
                delete(this.Listener)
                setDefinition(this.ResponseWrapper,Response);
                if this.Create
                    addResponse(this.CDD,this.ResponseWrapper);
                end
                delete(this)
            catch ME
                rethrow(ME)
            end

        end
        
        function syncData(this)
            if isvalid(this)
                Response = getDefinition(this.ResponseWrapper);
                this.Name = Response.Name;
                this.Input = Response.Input;
                this.Output = Response.Output;
                this.Openings = Response.Openings;
                update(this);
            end
            
        end
    end
   
    methods(Access = protected)
        function mUpdate(this)
            update(this.IOTransferTC);
        end
    end
    
    methods(Hidden)
        function qeAddInputSignal(this,signalName)
            addSignal(this.IOTransferTC.InputListPanel,signalName);
        end
        
        function qeAddOutputSignal(this,signalName)
            addSignal(this.IOTransferTC.OutputListPanel,signalName);
        end
        
        function qeAddLoopOpeningLocation(this,signalName)
            addSignal(this.IOTransferTC.OpeningListPanel,signalName);
        end
    end
end
