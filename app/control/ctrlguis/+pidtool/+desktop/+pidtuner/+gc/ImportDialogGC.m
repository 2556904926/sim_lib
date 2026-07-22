classdef ImportDialogGC < controllib.ui.internal.dialog.AbstractImportDialog
    %IMPORTDIALOGGC
    
    % Copyright 2013-2021 The MathWorks, Inc.
    
    properties
        TC
        NUPTextField
    end
    
    methods
        function this = ImportDialogGC(tc)
            %IMPORTDIALOGGC
            this = this@controllib.ui.internal.dialog.AbstractImportDialog;
            this.TC = tc;
            
            %Abstract Dialog Properties
            this.ShowRefreshButton = true;
            this.AllowMultipleRowSelection = false;
            this.Name = 'PIDTUNER_IMPORTDIALOG';
            this.Title = pidtool.utPIDgetStrings('cst','importdlg_title');
            this.HeaderText = pidtool.utPIDgetStrings('cst','strImportPlant');
            this.DialogSize = [540 240];

        end
    end
    
      methods(Access = protected)
            function buildCustomWidgets(this)
                
                % Number of Unstable Poles
                belowTableGrid = uigridlayout('Parent',[]);
                belowTableGrid.RowHeight = {22};
                belowTableGrid.ColumnWidth = {'fit','1x'};
                belowTableGrid.RowSpacing = 3;
                
                NUPTextFieldLabel = uilabel(belowTableGrid,'Text',pidtool.utPIDgetStrings('cst','importdlg_nuplabel'));
                NUPTextFieldLabel.Layout.Row = 1;
                NUPTextFieldLabel.Layout.Column = 1;
                this.NUPTextField = uieditfield(belowTableGrid,'numeric','limits',[0 inf],'roundfractionalvalues','on');
                this.NUPTextField.Tag = 'NUPTEXTFIELD';
                this.NUPTextField.Enable = false;
                this.NUPTextField.Layout.Row = 1;
                this.NUPTextField.Layout.Column = 2;
                this.addWidget(belowTableGrid,'belowtable','fit')
            end
            function tableData = getTableData(this)
                % Return the table to be displayed by AbstractImportDialog
                % Available Data,Type,Order
                filteredData = getFilteredData();
                if ~isempty(filteredData)
                    systemType = cellfun(@(x) class(x), filteredData.Data, 'UniformOutput',false);
                    systemOrder = cellfun(@(x) size(x,'order'), filteredData.Data);
                    tableData = table(filteredData.Name,...
                        systemType,systemOrder,...
                        'VariableNames',...
                        {pidtool.utPIDgetStrings('cst','importdlg_colname1'),...
                        pidtool.utPIDgetStrings('cst','importdlg_colname2'),...
                        pidtool.utPIDgetStrings('cst','importdlg_colname3')});
                else
                    tableData = table([],[],[],...
                        'VariableNames',...
                        {pidtool.utPIDgetStrings('cst','importdlg_colname1'),...
                        pidtool.utPIDgetStrings('cst','importdlg_colname2'),...
                        pidtool.utPIDgetStrings('cst','importdlg_colname3')});
                end
            end
            
            function callbackActionButton(this)
                selectedData = getSelectedData(this);
                % Error dialog if selection is empty
                if isempty(selectedData)
                    %NOTE: Add error message?
                    return;
                end  
                sys = selectedData{1,2};
                sysname = selectedData{1,1};
                switch class(sys)
                    case {'idarx','idgrey'}
                        sys = ss(sys);
                    case 'idfrd'
                        sys = frd(sys); % protects for -ve freq
                end
                convertFRD = false;
                if isa(sys,'ss') && hasInternalDelay(sys)
                    try
                        zpk(sys);
                    catch %#ok<CTCH>
                        convertFRD = true;
                    end
                end
                if convertFRD || isa(sys,'frd')
                    NUP = this.NUPTextField.Value;
                else
                    NUP = 0;
                end
                this.TC.PlantList.addPlant(sys,NUP, [], sysname);
                this.close();
            end

            function callbackHelpButton(this) %#ok<*MANU>
                %CBHELPBUTTON
                helpview('control','pidtool_importdlgV2','CSHelpWindow');
            end

            function connectUI(this)
                L1 = addlistener(this, 'SelectionChanged', @(~,evt) localTableRowSelected(this,evt));
                registerUIListeners(this,L1); 
            end
      end
end
    function localTableRowSelected(this,evt)
    %LOCALTABLEROWSELECTED
    selectedRow = evt.Data;
    if ~isempty(selectedRow) && selectedRow>0
        data = getSelectedData(this);
        sys = data{2};
        convertFRD = false;
        if isa(sys,'ss') && hasInternalDelay(sys)
            hw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
            try
                zpk(sys);
            catch %#ok<CTCH>
                convertFRD = true;
            end
        end
        if convertFRD || isa(sys,'frd') || isa(sys,'idfrd')
            this.NUPTextField.Enable = true;
        else
            this.NUPTextField.Enable = false;
        end
    else
        this.NUPTextField.Enable = false;
    end
    end

    function Widgets = qeGetCustomWidgets()
        Widgets = struct('NUPTextField',this.NUPTextField);
    end

    function filteredData = getFilteredData()
            %FILTERDATA
            Vars = evalin('base','whos');
            Nvars = length(Vars);
            
            % Filter vars based on class type
            isValidType = false(Nvars,1);
            for ct=1:Nvars
                var = Vars(ct);
                if any(strcmp(var.class,{'tf','zpk','ss','frd','idss',...
                        'idarx','idgrey','idproc','idpoly','idfrd','idtf'})) %,'pid','pidstd'
                    isvalid = true;
                else
                    isvalid = false;
                end
                isValidType(ct) = isvalid;
            end
            sysvar = {Vars(isValidType).name}.';
            Nsys = length(sysvar);
            DataModels = cell(Nsys,1);
            for ct=1:Nsys
                DataModels(ct) = {evalin('base',sysvar{ct})};
            end
            
            if Nsys > 0
                % Filter vars based on size
                isValidType = false(length(sysvar),1);
                for ct=1:length(sysvar)
                    var = DataModels{ct};
                    if isa(var,'ltipack.SingleRateSystem')
                        sz = size(var);
                        isvalid = issiso(var) && isequal(sz,[1 1]) && var.Ts>=0;
                    else
                        isvalid = false;
                    end
                    isValidType(ct) = isvalid;
                end
                ind = find(isValidType);
				if isempty(ind)
					filteredData = [];
				else
					varnames = sysvar(ind);
					vardata = DataModels(ind);
					filteredData.Data = vardata;
					for i = 1:length(vardata)
						filteredData.Name{i,1} = varnames{i};
					end
				
				end
            else
                filteredData = [];
            end
    end
