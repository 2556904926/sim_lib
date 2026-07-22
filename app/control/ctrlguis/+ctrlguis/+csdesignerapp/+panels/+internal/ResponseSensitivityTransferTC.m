classdef ResponseSensitivityTransferTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Tool component for Sensitivity Transfer response
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(SetObservable,AbortSet)
        Location = {}
        Openings = {}
    end    
    properties
        SensitivityTransferTC
        ResponseWrapper
        Create
        Type = 'SensitivityTransfer'
        % Dialog labels for signals
        LocationSignalLabel = getString(message('Control:designerapp:SignalListLocationLabelSensitivityTransfer'));
        OpeningSignalLabel = getString(message('Control:designerapp:SignalListOpeningLabelSensitivityTransfer'));         
    end
    properties (Transient)
        Listener
    end
    
    methods(Access = public)
        function this = ResponseSensitivityTransferTC(CDD,responseWrapper)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.Create = false;
            this.CDD = CDD;
            this.SensitivityTransferTC = ctrlguis.csdesignerapp.panels.internal.LoopTransferTC(this.CDD,this); 
            
            if nargin == 1
                this.Create = true;
                responseWrapper = ctrlguis.csdesignerapp.data.responses.internal.Response;
                this.ResponseWrapper=responseWrapper;
            else
                this.ResponseWrapper=responseWrapper;
                syncData(this)
                weakThis = matlab.lang.WeakReference(this);
                this.Listener = addListenerToSyncData(this.ResponseWrapper,@(es,ed) syncData(weakThis.Handle));
            end
            
        end
    end
    
    
    %% Tool-Component API
    methods(Access = public)
        function view = createView(this)
            view = controllib.widget.internal.responseplot.ResponseSensitivityTransferGC(this);
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
                ResponseNames = getResponseName(this.CDD);
                % Check if response name is duplicate and overwrite flag is
                % false
                if any(strcmp(ResponseNames,this.Name)) && ~overwriteExistingResponse
                    error(getString(message('Control:systunegui:ResponseNameConflict',this.Name)));
                    return;
                end
                % Create Response
                response = ctrlguis.csdesignerapp.data.responses.internal.SensitivityTransfer(this.Location);
                response.Openings = this.Openings;
                response.Name = this.Name;
                delete(this.Listener)
                setDefinition(this.ResponseWrapper,response);
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
                response = getDefinition(this.ResponseWrapper);
                this.Name = response.Name;
                this.Location = response.Location;
                this.Openings = response.Openings;
                update(this);
            end
            
        end
    end
   
    methods(Access = protected)
        function mUpdate(this)
            update(this.SensitivityTransferTC);
        end
    end
    
    methods(Hidden)
        function qeAddSensitivityResponseLocation(this,signalName)
            addSignal(this.SensitivityTransferTC.LocationListPanel,signalName);
        end
        
        function qeAddLoopOpeningLocation(this,signalName)
            addSignal(this.SensitivityTransferTC.OpeningListPanel,signalName);
        end
    end
end
