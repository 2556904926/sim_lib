classdef DesignDisplayDialog < controllib.ui.internal.dialog.AbstractDialog
    % Class for display designs.    
    
    % Copyright 2013-2020 The MathWorks, Inc.
    
    properties
        Parent
        Widgets
    end
    
    methods
        function this = DesignDisplayDialog(Design)
            this.Parent = Design;
            % Store it in the tear off dialog
            this.Name = string(Design.Name) + matlab.lang.internal.uuid;
            this.Title = getString(message('Control:designerapp:DesignDisplayTitle'));
        end
        
        function updateUI(this)
            updateContent(this);
        end
        
%         function delete(this)
%             delete@controllib.ui.internal.dialog.AbstractDialog(this);
%         end
        
        %% Text content
        function updateContent(this)
            DisplayText = getDisplayPreviewText(this.Parent);
            this.Widgets.txtDesignSnapshot.Value = DisplayText;
        end
    end
    
    methods (Access = protected)
        function buildUI(this)
            
            gridLayout = uigridlayout(this.UIFigure,[1 1]);
            gridLayout.Scrollable = 'on';
            txtDesignSnapshot = uitextarea(gridLayout,'FontName','Courier New');
            txtDesignSnapshot.WordWrap = 'off';
            txtDesignSnapshot.Editable = 'off';
                        
            %Populate widgets
            this.Widgets = struct(...
                'txtDesignSnapshot', txtDesignSnapshot, ...
                'Panel',             gridLayout);
            
            this.UIFigure.Scrollable = 'on';
            this.UIFigure.Position(3:4) = [400 320];
        end
        
    end
end
