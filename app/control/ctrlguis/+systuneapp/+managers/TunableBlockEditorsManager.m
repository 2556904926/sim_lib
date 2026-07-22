classdef (Hidden) TunableBlockEditorsManager < handle
    % Tunable Block Editor Manager class

    % Copyright 2013-2021 The MathWorks, Inc.
    properties
        ControlDesignData
        TunableBlockEditors
        Widgets
        CleanupListeners
        TBListChangedListener
    end
    
    methods
    
        function this = TunableBlockEditorsManager(CDD)
            this.ControlDesignData = CDD;
            this.TBListChangedListener = addlistener(this.ControlDesignData, 'ArchitectureChanged', @(es, ed)cbBlockListChanged(this));
        end
        
        function EditTunableBlock(this, Block,hAnchor,Region)
            
            if nargin < 3
                hAnchor = [];
            end
            if nargin < 4 
                Region = 'SOUTH';
            end
            
            % Does the block have an open editor?
            fl = false;
            for ct = 1:numel(this.TunableBlockEditors)
                if isequal(Block, this.TunableBlockEditors{ct}.TunableBlock)
                    if systuneapp.util.openJavaApp
                        show(this.TunableBlockEditors{ct}, hAnchor, true, Region);
                    else
                        show(this.TunableBlockEditors{ct}, hAnchor, Region);
                    end
                    this.Widgets{ct} = this.TunableBlockEditors{end}.qeGetWidgets;
                    fl = true;
                end
            end
            % If not, create a new editor.
            if ~fl
                if isa(Block, 'controldesign.blockconfig.slBlockConfig')
%                     this.TunableBlockEditors{end+1} = ctrluis.slTunableBlockEditor(Block);
%                     show(this.TunableBlockEditors{end}, hAnchor, true, Region);
%                     this.Widgets{end+1} = this.TunableBlockEditors{end}.getWidgets;

                    % #CSTunerDialogManagement
                    this.TunableBlockEditors{end+1} = ...
                        systuneapp.internal.dialogs.blockeditors.SLTunableBlockEditor(Block);
                    if systuneapp.util.openJavaApp
                        show(this.TunableBlockEditors{end});
                    else
                        show(this.TunableBlockEditors{end},hAnchor,Region);
                    end                    
                    this.Widgets{end+1} = this.TunableBlockEditors{end}.qeGetWidgets;
                    
                    this.CleanupListeners{end+1} = addlistener(this.TunableBlockEditors{end},...
                        'ObjectBeingDestroyed', @(es,ed)cbCleanup(this, es));  
                else

                    % #CSTunerDialogManagement
                    this.TunableBlockEditors{end+1} = ...
                        systuneapp.internal.dialogs.blockeditors.MLTunableBlockEditor(Block);
                    if systuneapp.util.openJavaApp
                        show(this.TunableBlockEditors{end});
                    else
                        show(this.TunableBlockEditors{end},hAnchor,Region);
                    end
                    
                    this.Widgets{end+1} = this.TunableBlockEditors{end}.qeGetWidgets;
                    
                    this.CleanupListeners{end+1} = addlistener(this.TunableBlockEditors{end},...
                        'ObjectBeingDestroyed', @(es,ed)cbCleanup(this, es)); 
                end
                
                
            end
        end
        
        function cbCleanup(this, es)
            % Delete the listeners and the widgets associated with the
            % deleted tunable block editor
            if isvalid(this)
                for ct = 1:numel(this.TunableBlockEditors)
                    if isequal(es.TunableBlock, this.TunableBlockEditors{ct}.TunableBlock)
                        delete(this.CleanupListeners{ct});
                        this.CleanupListeners(ct) = [];
                        this.TunableBlockEditors(ct) = [];
                        this.Widgets(ct) = [];
                        return;
                    end
                end
            end
        end
        
        function cbBlockListChanged(this)
            % Delete the listeners and the widgets associated with the
            % deleted tunable block editor
            TBList = this.ControlDesignData.getTunableBlock;
            
            for ct = numel(this.TunableBlockEditors):-1:1
                ListIndex = arrayfun(@(x) eq(x,this.TunableBlockEditors{ct}.TunableBlock),TBList);
                isInList = any(ListIndex);
                if ~isInList
                    delete(this.CleanupListeners{ct});
                    this.CleanupListeners(ct) = [];
                    delete(this.TunableBlockEditors{ct});
                    this.TunableBlockEditors(ct) = [];
                    this.Widgets(ct) = [];
                end
            end
            
        end
        function wdgts = getWidgets(this, TunableBlock)
            % Return the widgets associated with the tunable block
            for ct = 1:numel(this.TunableBlockEditors)
                if isequal(TunableBlock, this.TunableBlockEditors{ct}.TunableBlock)
                    wdgts = this.Widgets{ct};
                    return;
                else
                    wdgts = [];
                end
            end
        end

        function delete(this)
            for ct = 1:numel(this.TunableBlockEditors)
                delete(this.TunableBlockEditors{ct});
            end
        end
    end
    
    
end
