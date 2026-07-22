classdef (Hidden) ResponseLoopTransferTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Tool component for Loop Transfer response
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(SetObservable,AbortSet)
        Location = {}
        Openings = {}
    end    
    properties
        LoopTransferTC
        ResponseWrapper
        Create
        Type = 'LoopTransfer'
        % Dialog labels for signals
        LocationSignalLabel = getString(message('Control:systunegui:SignalListLocationLabelLoopTransfer'));
        OpeningSignalLabel = getString(message('Control:systunegui:SignalListOpeningLabelLoopTransfer'));        
    end
    properties (Transient)
        Listener
        ResponseDeletedListener
    end
    
    methods(Access = public)
        function this = ResponseLoopTransferTC(CDD,ResponseWrapper)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.Create = false;
            this.CDD = CDD;
            this.LoopTransferTC = systuneapp.internal.panels.LoopTransferTC(this.CDD,this); 
            
            if nargin == 1
                this.Create = true;
                ResponseWrapper = systuneapp.data.response.ResponseWrapper;
                this.ResponseWrapper=ResponseWrapper;
            else
                this.ResponseWrapper=ResponseWrapper;
                syncData(this)
                this.Listener = addListenerToSyncData(this.ResponseWrapper,@(es,ed) syncData(this));
                this.ResponseDeletedListener = addlistener(this.ResponseWrapper,'ObjectBeingDestroyed',@(s,e) delete(this));
            end            
        end

        function delete(this)
            delete(this.Listener)
            delete(this.ResponseDeletedListener)
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = controllib.widget.internal.responseplot.ResponseLoopTransferGC(this);
        end
    end
    
    methods(Access = public)
        function setResponse(this,overwriteExistingResponse)
            arguments
                this
                overwriteExistingResponse = false
            end
            try
                if isempty(this.Location)
                    error(getString(message(['Control:systunegui:' 'Response' this.Type 'Error'])));
                    return;
                end
                % Check if response name is duplicate and overwrite flag is
                % false
                ResponseNames = getResponseName(this.CDD);
                if any(strcmp(ResponseNames,this.Name)) && ~overwriteExistingResponse
                    error(getString(message('Control:systunegui:ResponseNameConflict',this.Name)));
                    return;
                end
                % Create Response
                Response = systuneapp.data.response.LoopTransfer(this.Location);
                Response.Openings = this.Openings;
                Response.Name = this.Name;
                this.ResponseWrapper.Response = Response;
                if this.Create
                    addResponse(this.CDD,this.ResponseWrapper);
                end
            catch ME
                rethrow(ME)
            end

        end
        
        function syncData(this)
            if isvalid(this)
                Response = this.ResponseWrapper.Response;
                this.Name = Response.Name;
                this.Location = Response.Location;
                this.Openings = Response.Openings;
                update(this);
            end
            
        end
    end
   
    methods(Access = protected)
        function mUpdate(this)
            update(this.LoopTransferTC);
        end
    end
    
    methods(Hidden)
        function qeAddLoopResponseLocation(this,signalName)
            addSignal(this.LoopTransferTC.LocationListPanel,signalName);
        end
        
        function qeAddLoopOpeningLocation(this,signalName)
            addSignal(this.LoopTransferTC.OpeningListPanel,signalName);
        end
    end
end
