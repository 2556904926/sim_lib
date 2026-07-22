classdef PlantSelector < handle
   %PLANTSELECTOR
   
   % Copyright 2013-2021 The MathWorks, Inc.
   
   properties
      ButtonTPComponent
   end
   properties (Access = private)
      PlantList
      ExistingItemsHeader
      CreateNewItemsHeader
      ExistingItems
      CreateNewItems
      VarIcon
      SimulateIcon
   end
   properties (Access = private, Dependent = true)
      PopupItems
   end
   methods
      function this = PlantSelector(plantlist)
        %PLANTSELECTOR
        this.PlantList = plantlist;
        addlistener(this.PlantList, 'PlantsEvent', @(~,~) this.updatePopupItems());
        addlistener(this.PlantList, 'SelectedPlantIndex', 'PostSet', @(src,evnt) this.updateButtonLabel());
        this.ButtonTPComponent = matlab.ui.internal.toolstrip.SplitButton(matlab.ui.internal.toolstrip.Icon('import_data'));
        this.ButtonTPComponent.DynamicPopupFcn = @(x,y) updatePopupItems(this);
        this.ButtonTPComponent.ButtonPushedFcn = @(x,y) importPlantCallback(this);
        this.SimulateIcon = matlab.ui.internal.toolstrip.Icon('workspace_ws3d');
        this.VarIcon = matlab.ui.internal.toolstrip.Icon('ws3d');
        
        this.ButtonTPComponent.Popup = this.updatePopupItems();
        this.updateButtonLabel();
      end
      
      function popup = updatePopupItems(this)
            import matlab.ui.internal.toolstrip.*
            % Create popup list
            popup = PopupList();
            
            % Existing Plants Header
            header = PopupListHeader(pidtool.utPIDgetStrings('cst','strExistingPlants'));
            popup.add(header);
            
            % Create List of Existing Plants
            for i = 1:this.PlantList.NumPlants
                item = ListItem(this.PlantList.PlantNames{i}, this.VarIcon);
                item.ItemPushedFcn = @(x,y) plantSelectionCallback(this,i);
                item.ShowDescription = false;
                popup.add(item);
            end
            
            % Create New Plants Header
            header = PopupListHeader(pidtool.utPIDgetStrings('cst','strCreateNewPlant'));
            popup.add(header);
            
            % Import New Plant
            item = ListItem(pidtool.utPIDgetStrings('cst','strImport'), Icon('import_ws3d'));
            item.ItemPushedFcn = @(x,y) importPlantCallback(this);
            item.Description = pidtool.utPIDgetStrings('cst','strImportDesc');
            popup.add(item);
            
            % Identify New Plant
            item = ListItem(pidtool.utPIDgetStrings('cst','strIdentifyNewPlant'), this.SimulateIcon);
            item.ItemPushedFcn = @(x,y) identifyPlantCallback(this);
            item.Description = pidtool.utPIDgetStrings('cst','strIdentifyNewPlantDesc');
            popup.add(item);

            this.updateButtonLabel();
      end
      
      function updateButtonLabel(this)
         %UPDATEBUTTONLABEL
         
         if isempty(this.PlantList.SelectedPlantName)
            this.ButtonTPComponent.Text = 'Create...';
         else
            this.ButtonTPComponent.Text = this.PlantList.SelectedPlantName;
         end
      end
      
      %% Callbacks
      function plantSelectionCallback(this,idx)
          % Plant menu item selection      
         if (this.PlantList.SelectedPlantIndex ~=0)
            % Existing plant selected.
            if (this.PlantList.SelectedPlantIndex ~= idx)
               this.PlantList.SelectedPlantIndex = idx;
            end
         end
      end
      
      function importPlantCallback(this)
          notify(this.PlantList, 'ImportRequested');
      end
      
      function identifyPlantCallback(this)
          notify(this.PlantList, 'PlantIdentificationRequested');
      end
      
   end
end
