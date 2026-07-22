classdef (Hidden) DesignSnapshot < handle & matlab.mixin.Copyable 
    % Data Class for Design Object of Control System Tuner App
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = public, SetObservable)
        Name % Snapshot Name
        Data % Snapshot Data
        Info % Tuning info
    end
    
    properties(Transient, GetAccess = private, SetAccess = private)
        DisplayDialog 
    end
    
    methods
        function this = DesignSnapshot(Name,Data,Info)
            %Constructor
            this.Name=Name;
            this.Data=Data;
            this.Info=Info;
        end
        
        function Name = getName(this)
            Name = this.Name;
        end
        
        function Design = getDesign(this)
            Design = this.Data;
        end
               
        function openDisplayDialog(this, hAnchor, region)
            if nargin < 2
                hAnchor = [];
            end
            if nargin < 3
                region = 'SOUTH';
            end
            if isempty(this.DisplayDialog)
                if systuneapp.util.openJavaApp
                    this.DisplayDialog = systuneapp.dialogs.DesignDisplayDialog(this);
                else
                    this.DisplayDialog = systuneapp.internal.dialogs.DesignDisplayDialog(this);
                end
            end
            if systuneapp.util.openJavaApp
                this.DisplayDialog.show(hAnchor,true,region);
            else
                show(this.DisplayDialog,hAnchor,region)
            end
        end
        
        function DisplayText = getDisplayPreviewText(this)
            DisplayText = [ ...
                systuneapp.util.createDisplayText('type', ...
                    getString(message('Control:systunegui:DisplayDesign'))), ...
                systuneapp.util.createDisplayText('line', ...
                    getString(message('Control:systunegui:DisplayName')),this.Name), ...
                systuneapp.util.createDisplayText('line', ...
                    getString(message('Control:systunegui:DisplayTs')),getTs(this)), ...
                systuneapp.util.createDisplayText('design', ...
                    getString(message('Control:systunegui:DisplayValue')), ...
                    systuneapp.util.createDisplayDesign(this.Data)), ...                                        
                    ];            
        end        
        
        function Ts = getTs(this)
           % Returns sample time of design. Ts=[] when all blocks are REALP
           % (sample time immaterial for gains).
           Ts = [];
           for ct=1:numel(this.Data)
              BP = this.Data(ct).BlockParam;
              if isa(BP,'DynamicSystem')
                 Ts = BP.Ts;  break
              end
           end
        end

        function delete(this)
            delete(this.DisplayDialog);
        end
           
    end    
    
    methods(Hidden)
       function Dlg = getDisplayDialog(this)
            Dlg = this.DisplayDialog;
        end
    end


end
