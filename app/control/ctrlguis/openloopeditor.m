function out = openloopeditor(parent,optionalLoopEditorInputs,optionalUIComponentInputs,optionalViewInputs)
%OPENLOOPEDITOR Open loop editor for linear systems.
%
%   OPENLOOPEDITOR provides a command line interface for graphical frequency
%   domain loop shaping.
%
%   OLE = OPENLOOPEDITOR() returns the handle to the open loop editor.
%   You can use this handle to obtain the tuned compensator, customize the
%   editor properties, or connect the editor to other components.
%
%   OLE = OPENLOOPEDITOR(PARENT) creates an open loop editor in the specified
%   parent container.
%
%   OLE = OPENLOOPEDITOR(PLANT=PLANT) creates an open loop editor for the
%   specified plant.
%
%   OLE = OPENLOOPEDITOR(..., NAME=VALUE) specifies the open loop editor using
%   one or more name-value arguments.
%
%   Example:
%       ole = openloopeditor(Plant=rss(5));
%       % Add a compensator pole at -1
%       ole.Compensator.P{1,1} = -1;
%
%   See also BODEPLOT, NICHOLSPLOT, RLOCUSPLOT, CONTROLSYSTEMDESIGNER.

%   Copyright 2024 The MathWorks, Inc.

arguments (Input)
    parent {mustBeScalarOrEmpty,mustBeA(parent,["matlab.ui.Figure","matlab.ui.container.Panel","matlab.ui.container.Tab","matlab.ui.container.GridLayout"])} = matlab.ui.Figure.empty
    optionalLoopEditorInputs.Plant DynamicSystem = ss(NaN)
    optionalLoopEditorInputs.NominalPlantIndex (1,1) double {mustBeInteger,mustBePositive} = 1
    optionalLoopEditorInputs.Compensator DynamicSystem = ss(NaN)
    optionalLoopEditorInputs.ViewType (1,1) string {mustBeMember(optionalLoopEditorInputs.ViewType,["bode","nichols","rlocus"])} = "bode"
    optionalLoopEditorInputs.CompensatorChangedFcn = function_handle.empty
    optionalLoopEditorInputs.CompensatorChangingFcn = function_handle.empty
    optionalUIComponentInputs.?matlab.ui.componentcontainer.ComponentContainer
    optionalViewInputs.ViewOptions plotopts.PlotOptions {mustBeScalarOrEmpty} = plotopts.PlotOptions.empty
end
arguments (Output)
    out (1,1) ctrlguis.uicomponent.OpenLoopEditor
end
try
    % Resolve Parent NV
    if ~isfield(optionalUIComponentInputs,"Parent") && ~isempty(parent)
        optionalUIComponentInputs.Parent = parent;
    end

    % Get default compensator
    if isequaln(optionalLoopEditorInputs.Compensator,ss(NaN))
        optionalLoopEditorInputs.Compensator = zpk([],[],1,optionalLoopEditorInputs.Plant.Ts,TimeUnit=optionalLoopEditorInputs.Plant.TimeUnit);
    end

    % Check options
    if ~isempty(optionalViewInputs.ViewOptions)
        switch optionalLoopEditorInputs.ViewType
            case "bode"
                if ~isa(optionalViewInputs.ViewOptions,"plotopts.BodeOptions")
                    error(message('Control:design:loopEditorErrorViewOptions','bode'))
                end
                optionalViewInputs.ViewOptions.FreqScale = 'log';
            case "nichols"
                if ~isa(optionalViewInputs.ViewOptions,"plotopts.NicholsOptions")
                    error(message('Control:design:loopEditorErrorViewOptions','nichols'))
                end
            case "rlocus"
                if ~isa(optionalViewInputs.ViewOptions,"plotopts.PZOptions")
                    error(message('Control:design:loopEditorErrorViewOptions','pz'))
                end
        end
    end

    % Check models
    ctrlguis.uicomponent.OpenLoopEditor.validatePlant(optionalLoopEditorInputs.Plant);
    ctrlguis.uicomponent.OpenLoopEditor.validateCompensator(optionalLoopEditorInputs.Compensator);
    ctrlguis.uicomponent.OpenLoopEditor.validatePlantWithCompensator(optionalLoopEditorInputs.Plant,optionalLoopEditorInputs.Compensator);
    ctrlguis.uicomponent.OpenLoopEditor.validatePlantWithView(optionalLoopEditorInputs.Plant,optionalLoopEditorInputs.ViewType);
    ctrlguis.uicomponent.OpenLoopEditor.validateNominalPlantIndex(optionalLoopEditorInputs.NominalPlantIndex,optionalLoopEditorInputs.Plant);

    % Build widget
    optionalLoopEditorInputsCell = namedargs2cell(optionalLoopEditorInputs);
    optionalUIComponentInputsCell = namedargs2cell(optionalUIComponentInputs);
    wdgt = ctrlguis.uicomponent.OpenLoopEditor(optionalLoopEditorInputsCell{:},optionalUIComponentInputsCell{:});

    % Apply view options
    if ~isempty(optionalViewInputs.ViewOptions)
        setoptions(wdgt,optionalViewInputs.ViewOptions);
    end

    % Resize for default parent
    if ~isfield(optionalUIComponentInputs,"Parent")
        wdgt.Units = "normalize";
        wdgt.Position = [0 0 1 1];
        wdgt.Units = "pixels";
        if isfield(optionalUIComponentInputs,"Units")
            wdgt.Units = optionalUIComponentInputs.Units;
        end
        if isfield(optionalUIComponentInputs,"Position")
            wdgt.Position = optionalUIComponentInputs.Position;
        end
    end

    % Output widget
    if nargout
        out = wdgt;
    end
catch ME
    throw(ME)
end
end