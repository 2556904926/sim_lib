classdef DeleteDialog < controllib.ui.internal.dialog.AbstractExportDialog
    % Class for the dialog to delete systems from a Linear System Analyzer
    % session

    % Copyright 2021-2024 The MathWorks, Inc.

    properties (Access=protected)
        App
    end

    methods
        function this = DeleteDialog(app)
            name = 'LinearSystemAnalyzerDeleteDialog';
            title = getString(message('Control:viewer:strLTIViewerDelete'));
            this = this@controllib.ui.internal.dialog.AbstractExportDialog(name,title);
            this.App = app;
            this.ShowExportAsColumn = false;
            this.AllowColumnSorting = true;
            this.AddTagsToWidgets = true;
            this.TableTitle = getString(message('Control:viewer:strSelectModelsToDelete'));
            this.ActionButtonLabel = getString(message('Control:viewer:strDelete'));
            this.SelectColumnName = getString(message('Controllib:gui:strSelect'));
            this.DialogSize = [420 280];
        end
    end

    %% Implementation of protected absract or overloaded methods
    methods(Access = protected)
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

        % Overload for deleting systems instead of exporting
        function callbackActionButton(this)
            % Get model names to delete
            idx = getSelectedIdx(this);
            if isempty(idx)
                uialert(getWidget(this),getString(message('Control:viewer:DeleteDialogNoneSelectedError')),...
                    getString(message('Control:viewer:strDeleteError')));
                return;
            end
            try
                for ii = length(idx):-1:1
                    removeSystem(this.App,idx(ii));
                end
                close(this);
                postStatus(this.App,getString(message('Control:viewer:msgNSystemsDeleted',length(idx))));
            catch ME
                uialert(getWidget(this),ME.message,...
                    getString(message('Control:viewer:strDeleteError')));
            end
        end

        function callbackHelpButton(this) %#ok<MANU>
            helpview('control','viewer_delete');
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
end