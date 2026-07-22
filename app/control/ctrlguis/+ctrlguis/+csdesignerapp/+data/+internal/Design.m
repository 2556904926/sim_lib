classdef Design < handle & matlab.mixin.Copyable 
    % Design Class that manages a stored design
    
    % Copyright 2014 The MathWorks, Inc.
    
    properties(Access = public, SetObservable)
        Name = 'Design'
    end
    
    properties(Access = private)
         Data
    end
    
    properties(Transient, GetAccess = private, SetAccess = private)
        DisplayDialog 
    end
    
    
    %% Public methods
    methods (Access = public)
        
        function this = Design(Data,Name)
            this.Data = Data;
            if nargin == 2;
                this.Name = Name;
            end
        end
        
        function delete(this)
            delete(this.DisplayDialog);
        end
        
        function S = getValueStructure(this)
            S = this.Data;
        end
        
        function setName(this,Name)
            this.Name = Name;
        end
        
        function Name = getName(this)
            Name = this.Name;
        end
        
        function openDisplayDialog(this, hAnchor, Region)
            if nargin < 2
                hAnchor = [];
            end
            if nargin < 3
                Region = 'CENTER';
            end
            if isempty(this.DisplayDialog)
                this.DisplayDialog = ctrlguis.csdesignerapp.dialogs.internal.DesignDisplayDialog(this);
                registerDialog(hAnchor,this.DisplayDialog);
            end
            this.DisplayDialog.show(hAnchor,Region);
        end
        
        function DisplayText = getDisplayPreviewText(this)
            fn = fieldnames(this.Data);
            DisplayText = [ ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('type', ...
                getString(message(['Control:designerapp:DisplayDesign']))), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayName')),this.Name), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayTs')),this.Data.(fn{1}).Ts), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('design', ...
                getString(message('Control:designerapp:DisplayValue')), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayDesign(this.Data)), ...
                ];
        end
        
        function DisplayText = createDisplayDesign(DesignData)
            % Utility function for display text of Design Object.
            
            % Copyright 2013 The MathWorks, Inc.
            DisplayText = [];
            for ct = 1:length(DesignData)
                str = evalc('showBlockValue(DesignData(ct).BlockParam)');
                str = strsplit(str,'-----------------------------------');
                for ct2=1:length(str)
                    str2 = strsplit(str{ct2},'Name:');
                    aDisplayText{ct2}=str2{1};
                end
                DisplayText = [DisplayText,aDisplayText];
            end
        end
        
        function S = saveSession(this)
            S.Data = this.Data;
            S.Name = this.Name;
        end
    end
    
    methods (Hidden)
        function dlg = qeGetDisplayDialog(this)
            dlg = this.DisplayDialog;
        end
    end
end
