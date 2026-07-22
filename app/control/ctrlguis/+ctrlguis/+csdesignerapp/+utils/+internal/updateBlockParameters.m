function Warning = updateBlockParameters(TunedBlocks,OptionsStruct)
% UPDATEBLOCKPARAMETERS  Update the Simulink block parameters. A warning
% message is returned when duplicated variable parameters are detected.
%
 
% Author(s): John W. Glass 04-Oct-2005
% Copyright 2005-2006 The MathWorks, Inc.

% Check whether duplicated variable parameters exist in tunable blocks
[Warning VariableInfo] = ctrlguis.csdesignerapp.utils.internal.checkVariableParameter(TunedBlocks);

% Evaluate the precision if needed
% REVISIT
% if ~OptionsStruct.UseFullPrecision
%     try
%         prec = linearize.linutil.evalScalarParam(OptionsStruct.CustomPrecision);
%     catch Ex
%         ctrlMsgUtils.error('Slcontrol:controldesign:InvalidCustomPrecisionExpression',OptionsStruct.CustomPrecision);
%     end
% else
%     prec = NaN;
% end
prec = NaN;
try
    % Write the parameters back to the block dialogs
    for ct = 1:length(TunedBlocks)
        blk = getPath(TunedBlocks(ct));
        Parameters = getParameters(TunedBlocks(ct));
        Tunable = {Parameters.Tunable};
        TunableIndex = find(strcmp(Tunable,'on'));
        len = length(TunableIndex);
        if len>0
            params = cell(len,1);
            strVal = cell(len,1);
            for ct2 = 1:len
                % get parameter value
                val = Parameters(TunableIndex(ct2)).Value;
                % Write the parameter value according to class type
                strvalue = linearize.linutil.computeParameterString(val,prec);
                % store in the cell
                params{ct2} = Parameters(TunableIndex(ct2)).Name;
                strVal{ct2} = strvalue;
            end
            % write numerical value back for duplicated variables
            VariableInfo(ct).IsVariable = VariableInfo(ct).IsVariable & ~VariableInfo(ct).IsDuplicated;
            % update block parameter
            slctrlguis.updateBlockParameter(blk,params,strVal,...
                struct('ShowWarningDlg',{false},'VariableInfo',{VariableInfo(ct)}));
        end
    end
catch Ex
    if strcmp(Ex.identifier,'Simulink:Commands:InvSimulinkObjectName')
        ctrlMsgUtils.error('Slcontrol:controldesign:ModelNotOpenToWriteBlockParameters',TunedBlocks(ct).Name);
    elseif strcmp(Ex.identifier,'MATLAB:MultipleErrors') || ...
            (strcmp(Ex.identifier,'Simulink:Masking:Bad_Init_Commands') && ~isempty(Ex.cause))
        ctrlMsgUtils.error('Slcontrol:controldesign:CannotWriteBlockParameters',TunedBlocks(ct).Name,Ex.cause{1}.message)
    else
        ctrlMsgUtils.error('Control:designerapp:errCannotWriteBlockParameters',TunedBlocks(ct).Name);
    end
end
