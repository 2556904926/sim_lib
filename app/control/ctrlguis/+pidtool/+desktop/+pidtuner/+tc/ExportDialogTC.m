classdef ExportDialogTC < handle
    %EXPORTDIALOGTC
    
    % Author(s): Baljeet Singh 18-Nov-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        TableModel
    end
    properties (Constant = true)
        TableSize = [4 4]
    end
    properties
        TunerTC
    end
    methods
        function this = ExportDialogTC(tunertc)
            %EXPORTDIALOGTC
            this.TunerTC = tunertc;
        end
        function refreshTableData(this)
            %REFRESHTABLEDATA
            VarNames = this.TunerTC.PlantList.PlantNames;
            VarData = this.TunerTC.PlantList.Plants;
            data = createTableData(VarNames, VarData);
            this.TableModel.setData(data);
        end
        function closedlg = exportControllerAndSelectedPlants(this, controllername, plantids)
            %EXPORTCONTROLLERANDSELECTEDPLANTS
            if ~isempty(controllername)
                [dupC, closedlg] = this.TunerTC.ControllerList.exportTunedController(controllername, false);
                if ~closedlg
                    return;
                end
            else
                dupC = {};
                closedlg = true;
            end
            % plantids can be indeces or names
            if ~isempty(plantids)
                [dupNames, dupIDs] = this.TunerTC.PlantList.exportPlants(plantids, false);
            else
                dupNames = {};
                dupIDs = [];
            end
            dupnames = [dupC; dupNames];
            if ~isempty(dupnames)
                dialogname = getString(message('MATLAB:uistring:export2wsdlg:DuplicateVariableNames'));
                if (length(dupnames) == 1)
                    queststr = getString(message('MATLAB:uistring:export2wsdlg:OverWriteQuestionOneVariable',dupnames{1}));
                    dialogname = getString(message('MATLAB:uistring:export2wsdlg:DuplicateVariableName'));
                elseif (length(dupnames) == 2)
                    queststr = getString(message('MATLAB:uistring:export2wsdlg:OverWriteQuestionTwoVariables',dupnames{1}, dupnames{2}));
                else
                    queststrpart1 = sprintf('"%s", ', dupnames{1:end-2});
                    queststr = getString(message('MATLAB:uistring:export2wsdlg:OverWriteQuestionThreeVariables',queststrpart1, dupnames{end-1}, dupnames{end}));
                end
                buttonName = questdlg(queststr, dialogname, getString(message('MATLAB:uistring:export2wsdlg:Yes')), getString(message('MATLAB:uistring:export2wsdlg:No')), getString(message('MATLAB:uistring:export2wsdlg:Yes')));
                if ~strcmp(buttonName, getString(message('MATLAB:uistring:export2wsdlg:Yes')))
                    closedlg = false;
                    return;
                end
            end
            if ~isempty(controllername)
                this.TunerTC.ControllerList.exportTunedController(controllername, true);
            end
            if ~isempty(dupIDs)
                this.TunerTC.PlantList.exportPlants(dupIDs, true);
            end
        end
        function idx = getSelectedPlants(this)
            %GETSELECTEDPLANTS
            idx = [];
            for i = 1:this.TableModel.getRowCount
                selected = logical(this.TableModel.getValueAt(i-1,0));
                if selected
                    idx = [idx; i]; %#ok<AGROW>
                end
            end
        end
    end
end
