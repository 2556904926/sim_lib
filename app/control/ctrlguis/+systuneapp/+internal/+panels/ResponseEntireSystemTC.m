classdef (Hidden) ResponseEntireSystemTC < controllib.widget.internal.tc.AtomicComponent & ...
        controllib.ui.internal.data.TransferToolComponentInterface
    % Tool component for Input-Output Transfer response
    
    % Copyright 2013-2021 The MathWorks, Inc
    properties(SetObservable,AbortSet)
        Openings = {}
    end    
    properties
        ResponseWrapper
        Create
        Type = 'IOTransfer'
    end
    properties (Transient)
        Listener
        ResponseDeletedListener
    end
    
    methods(Access = public)
        function this = ResponseEntireSystemTC(CDD,ResponseWrapper)
            this = this@controllib.widget.internal.tc.AtomicComponent;
            this = this@controllib.ui.internal.data.TransferToolComponentInterface;
            this.Create = false;
            this.CDD = CDD;
            
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
            view = systuneapp.internal.panels.ResponseEntireSystemGC(this);
        end
    end
    
    methods(Access = public)
        function setResponse(this,overwriteExistingResponse)
            arguments
                this
                overwriteExistingResponse = false
            end
            try
                % Check if response name is duplicate and overwrite flag is
                % false
                ResponseNames = getResponseName(this.CDD);
                if any(strcmp(ResponseNames,this.Name)) && ~overwriteExistingResponse
                    error(getString(message('Control:systunegui:ResponseNameConflict',this.Name)));
                    return;
                end
                % Create Response
                Response = systuneapp.data.response.IOTransferEntireSystem;
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
            Response = this.ResponseWrapper.Response;
            this.Name = Response.Name;
            this.Openings = Response.Openings;
            update(this);
            
        end
    end
   
    methods(Access = protected)
        function mUpdate(~)
        end
    end
end
