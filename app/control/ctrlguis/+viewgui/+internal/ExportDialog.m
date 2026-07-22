classdef ExportDialog < controllib.ui.internal.dialog.AbstractExportDialog
    % Class for the dialog to export systems from a Linear System Analyzer
    % session
    
    % Copyright 2021-2024 The MathWorks, Inc.
    
    properties (Access = protected)
        App
        ExportToFileButton
    end

    methods
        function this = ExportDialog(app)
            name = 'LinearSystemAnalyzerExportDialog';
            title = getString(message('Control:viewer:strLTIViewerExport'));
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(name,title);
            this.App = app;
            this.ShowExportAsColumn = true;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.TableTitle = getString(message('Control:viewer:strSelectModelsToExport'));
            this.DialogSize = [530 320];
            this.NumberOfAdditionalCommitButtons = 1;
            this.ActionButtonLabel = getString(message('Control:viewer:strExportToWorkspace'));
            this.ButtonWidth = 120;
        end
    end

    %% Implementation of protected absract or overloaded methods
    methods(Access = protected)
        function buildCustomWidgets(this)
            % Create additional "Export To File" button
            buttonPanelWidget = getButtonPanelWidget(this);
            this.ExportToFileButton = uibutton(buttonPanelWidget,...
                "Text",getString(message('Control:viewer:strExportToDiskEllipsis')));
            this.ExportToFileButton.Layout.Row = 1;
            this.ExportToFileButton.Layout.Column = 3;
            this.ExportToFileButton.ButtonPushedFcn = @(es,ed) callbackExportToFileButton(this);
        end

        function value = getValueAt(this,idx)
            value = this.App.Systems{idx}.Model;
        end

        function tbl = getTableData(this)
            columnNames = {getString(message('Control:viewer:strModel')),...
                getString(message('Control:viewer:strSize')),...
                getString(message('Control:viewer:strClass'))};
            systemInfo = getSystemInfo(this);
            tbl = table({systemInfo.ModelName}',{systemInfo.Size}',{systemInfo.Class}',...
                'VariableNames',columnNames);
        end

        function callbackHelpButton(this) %#ok<MANU>
            helpview('control','viewer_export');
        end

        function callbackExportToFileButton(this)
            setSink(this,'','matfile');
            callbackActionButton(this);
            setSink(this,'base');
        end
    end

    methods (Access=private)
        function systemInfo = getSystemInfo(this)
            % Constructs systems list
            systemsInApp = this.App.Systems;
            systemInfo = struct(...
                'ModelName', '',...
                'Size',      '',...
                'Class',     '');
            if isempty(systemsInApp)
                return
            end
            systemInfo = repmat(systemInfo,length(systemsInApp),1);
            for ct = 1:length(systemsInApp)
                [size_str,class_str] = localCreateStr(systemsInApp{ct});
                systemInfo(ct) = struct(...
                    'ModelName', systemsInApp{ct}.Model.Name,...
                    'Size',      size_str,...
                    'Class',     class_str);
            end
            
            function [size_str,VarClass] = localCreateStr(system)
                VarClass=class(system.Model);
                wsize = size(system.Model);
                if any(strcmpi(VarClass,{'ss';'tf';'zpk';'frd';'sparss';'mechss'}))
                    if isequal(length(wsize),2)
                        s = mat2str(wsize);
                        s = strrep(s,' ','x');
                        size_str = s(2:end-1);
                    else
                        size_str = [num2str(length(wsize)),'-D'];
                    end
                elseif any(strcmpi(VarClass,{'idpoly';'idss';'idarx';'idfrd'}))
                    if isequal(wsize([1 2 4]),[1 1 1])
                        s = mat2str(wsize([1 2]));
                        s = strrep(s,' ','x');
                        size_str = s(2:end-1);
                    else
                        size_str = '4-D';
                    end
                end
            end
        end
    end

    methods(Hidden)
        function customWidgets = qeGetCustomWidgets(this)
            % Method "qeGetCustomWidgets":
            %   Overload this method to return a struct of custom widgets.
            customWidgets.ExportToFileButton = this.ExportToFileButton;
        end
    end
end