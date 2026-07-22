function schema = controlmenus( fncname, cbinfo, eventData )
%

%   Copyright 2010-2017 The MathWorks, Inc.
    fnc = str2func( fncname );
    
    if nargout(fnc)
        schema = fnc( cbinfo );
    else
        schema = [];
        if nargin == 3
            fnc( cbinfo, eventData);
        else
            fnc( cbinfo );
        end
    end
end

function res = LocalCheckLicense()
    res = license('test','Control_Toolbox');
end

function state = LocalGetControlDesignItemState(~)
    if LocalCheckLicense()
        state = 'Enabled';
    else
        state = 'Disabled';
    end
end

function bool = isSlcontrolInstalled()
    bool = license('test','Simulink_Control_Design') && ~isempty(ver('slcontrol'));
end

function schema = SimulinkControlDesignerMenu(cbinfo) %#ok<DEFNU> % ( cbinfo )
    schema = sl_container_schema;
    schema.tag = 'Simulink:SimulinkControlDesignerMenu';
    schema.label    = DAStudio.message('Simulink:studio:SimulinkControlDesignerMenu');
    schema.state = LocalGetControlDesignItemState( cbinfo );
    schema.generateFcn = @generateControlDesignMenuChildren;
    schema.autoDisableWhen = 'Busy';
end
function children = generateControlDesignMenuChildren( cbinfo )
    % generate children
    im = DAStudio.InterfaceManagerHelper( cbinfo.studio,'Simulink');
    if isSlcontrolInstalled()
        children = {...
            im.getAction('Slcontrol:SteadyState'), ...
            im.getAction('Slcontrol:LinearAnalysis'), ...
            im.getAction('Slcontrol:FrequencyResponseEstimation'), ...
            im.getAction('Slcontrol:CompensatorDesign'), ...
            im.getAction('Slcontrol:ControlSystemTuner'), ...
            im.getAction('Simulink:ModelDiscretizer'), ...
            'separator', ...
            im.getAction('Slcontrol:LinearizeBlock'), ...
            im.getAction('Slcontrol:BlockLinearizeSpecification'), ...
            'separator', ...
            im.getSubmenu('Simulink:LinearizeSignalMenu')
            };
    else
        children = {im.getAction('Simulink:ModelDiscretizer')};
    end
end
function schema = ModelDiscretizer( cbinfo ) %#ok<DEFNU>
    schema = sl_action_schema;
    schema.tag      = 'Simulink:ModelDiscretizer';
    schema.label    = DAStudio.message('Simulink:studio:ModelDiscretizer');
    schema.obsoleteTags = { 'Simulink:MdlDisc' }; 
    schema.state = LocalGetControlDesignItemState( cbinfo );
    schema.callback = @ModelDiscretizerCB;
    schema.autoDisableWhen = 'Busy';
end

function ModelDiscretizerCB( cbinfo )
    slmdldiscui( cbinfo.model.Name );
end

%EOF