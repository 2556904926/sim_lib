classdef (Hidden,Abstract) AbstractTool < handle
    % Abstract Tool consisting its tab, figure and data
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc.
    
    %% Properties
    properties (Dependent,SetAccess=private)
        Target
    end

    properties (SetAccess=protected)
        ToolData
    end

    properties (SetAccess=immutable)
        ID
    end

    properties (Abstract,SetAccess=immutable)
        Tab
        Document
        DocumentGroupTag
    end

    properties (Access=protected,Transient)
        ToolDataListeners
    end

    %% Events
    events
        CreateReducedModel
        ComputingTargetSystem
        ComputingReducedSystem
        PrintToApp
    end

    %% Constructor/destructor
    methods
        %% Constructor
        function this = AbstractTool(ToolData,Tag)
            arguments
                ToolData (1,1) mrtool.data.AbstractData
                Tag (1,1) string
            end
            this.ToolData = ToolData;
            this.DocumentGroupTag = Tag;
            this.ID = matlab.lang.internal.uuid;

            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.ToolData,'ComputingTargetSystem', ...
                @(es,ed) notify(weakThis.Handle,'ComputingTargetSystem'));
            L2 = addlistener(this.ToolData,'ComputingReducedSystem', ...
                @(es,ed) notify(weakThis.Handle,'ComputingReducedSystem'));
            L3 = addlistener(this.ToolData,'PrintToApp', ...
                @(es,ed) notify(weakThis.Handle,'PrintToApp',ed));
            L4 = addlistener(this.ToolData,'CreateReducedModel', ...
                @(es,ed) notify(weakThis.Handle,'CreateReducedModel',ed));
            this.ToolDataListeners = [L1;L2;L3;L4];
        end

        function delete(this)
            delete(this.ToolDataListeners);
            delete(this.ToolData);
        end
    end

    %% Get/Set
    methods
        % Target
        function Target = get.Target(this)
            Target = this.ToolData.Target;
        end
    end

    %% Public methods
    methods
        % save/load
        function loadSession(this,SessionData)
            % loading the session for tool
            loadSession(this.ToolData,SessionData);  
        end

        function SessionData = saveSession(this)
            % saving the session for tool
            SessionData = saveSession(this.ToolData);
        end
    end

    %% Hidden methods
    methods (Hidden)
        function wdgts = qeGetWidgets(this)
            wdgts.ToolData = this.ToolData;
            wdgts.ToolTab = this.Tab;
            wdgts.ToolPlot = this.Document;     
        end
    end
end