classdef IMCSpecPanel < ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel

    methods
        function this = IMCSpecPanel(Dialog, Parent, SpecData, varargin)
            % Superclass constructor
            this = this@ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel(Parent);

            % resassign property values
            this.Dlg = Dialog;
            this.Parent = Parent;
            this.Name = 'CSD_IMCSpecPanel';
            set(this, 'SpecData', SpecData);
            this.SpecData = SpecData;

            % build panel
            buildContainer(this)
        end

        function createWidgets(this)
            % Widgets for LQG specification
            % reset layout ColumnWidth to ensure we pack all components
            %             this.Layout.RowHeight{1} = 22;
            this.Layout.ColumnWidth = {'fit', 'fit', 'fit'};

            % create widgets for time constant
            createTimeConstant(this);

            % create widgets for desired order
            createOrderSpinner(this);

            % set values for default data
            createDefaultSpecData(this);

        end



        function OLNominal = overloadOpenLoopPlant(this)
            % Overloaded getOpenLoopPlant for IMC
            Arch = getArchitecture(this.Dlg.ControlDesignData);
            if getConfiguration(Arch) == 5
                OLNominal = getLoopSign(Arch)*getValue(getFixedBlocks(Arch,'G2'));
            else
                OLNominal = [];
                if ~isempty(this.Response) && ~isempty(this.Compensator)
                    OLNominal = utCreateLTI(getOpenLoopPlant(this.Response, this.Compensator));
                end
            end
        end

        function localResetCompensatorOrder(this, Order)
            % Order is double
            this.Widgets.OrderSpinner.Limits(1) = 1;
            if Order > 1
                this.Widgets.OrderSpinner.Limits(2) = Order;
            end
            if this.SpecData.DesiredOrder < Order
                this.Widgets.OrderSpinner.Value = this.SpecData.DesiredOrder;
            else
                if Order >= 1
                    this.Widgets.OrderSpinner.Value = Order;
                    this.SpecData.DesiredOrder = Order;
                    this.notify('SpecDataChanged');
                end
            end
        end
    end

    methods (Access = protected)
        function createDefaultSpecData(this)
            if isempty(this.Response) || isempty(this.Compensator)
                Tau = 1;
                DesiredOrder = 1;
            else
                OpenLoopPlant = overloadOpenLoopPlant(this);
                %get(this, 'OpenLoopPlant');
                Model = this.Dlg.utApproxDelay(-OpenLoopPlant);
                if ~isa(Model,'frd') && isstable(Model)
                    s = stepinfo(Model);
                    Tau = s.SettlingTime/20;
                    if isnan(Tau) || (Tau<=0)
                        Tau = 1;
                    end
                else
                    % REVISIT: need to initializ to the minimum tau value to make
                    % sure that C is stable
                    Tau = 1;
                end
                if ~isa(Model,'frd')
                    DesiredOrder = localCalcOrder(Model);
                else
                    DesiredOrder = 1;
                end
            end

            this.SpecData.Tau = Tau;
            this.SpecData.DesiredOrder = DesiredOrder;
        end

        % create UI components for the panel
        function createTimeConstant(this)
            % create components for time constant (label and textarea)
            timeConstantLabel = uilabel(this.Layout, 'Text', ...
                getString(message(...
                'Control:compDesignTask:IMCTuningTimeConstantLabel')));
            timeConstantLabel.Layout.Row = 1;
            timeConstantLabel.Layout.Column = 1;

            timeConstantText = uieditfield(this.Layout, 'numeric');
            timeConstantText.Layout.Row = 1;
            timeConstantText.Layout.Column = [2 3];
            timeConstantText.Value = 1;

            % add to Widgets
            this.Widgets.TimeConstantLabel = timeConstantLabel;
            this.Widgets.TimeConstantText = timeConstantText;
        end

        function createOrderSpinner(this)
            % create components for desired order (label and uispinner)
            orderLabel = uilabel(this.Layout, 'Text', ...
                getString(message('Control:designerapp:AutomatedTuningDesiredOrderLabel')));
            orderLabel.Layout.Row = 2;%5;
            orderLabel.Layout.Column = 1;

            orderSpinner = uispinner(this.Layout);
            orderSpinner.Layout.Row = 2;%5;
            orderSpinner.Layout.Column = [2 3];
            orderSpinner.Value = 3;
            orderSpinner.Limits = [1 10];

            % add to Widgets
            this.Widgets.OrderLabel = orderLabel;
            this.Widgets.OrderSpinner = orderSpinner;
        end

        % callbacks for listeners
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            timeConstantListener = addlistener(this.Widgets.TimeConstantText, ...
                'ValueChanged', ...
                @(es, ed)updateTimeConstant(weakThis.Handle, es.Value));
            orderListener = addlistener(this.Widgets.OrderSpinner, ...
                'ValueChanged', ...
                @(es, ed)updateOrder(weakThis.Handle, es.Value));

            % add to UIListeners
            this.UIListeners{end+1} = timeConstantListener;
            this.UIListeners{end+1} = orderListener;
        end

        % update the panel UI
        function refreshUI(this)

            if this.Panel.Visible
                compensator = this.Compensator;

                % refresh tau
                this.Widgets.TimeConstantText.Value = this.SpecData.Tau;
                % refresh order
                if isTunable(compensator) && ~isempty(compensator.Constraints) ...
                        && ~isinf(compensator.Constraints.MaxPoles)
                    localResetCompensatorOrder(this, ...
                        compensator.Constraints.MaxPoles);
                else
                    order = calcOrder(this);
                    localResetCompensatorOrder(this, order);
                end

            end
        end

        % callback functions
        function updateTimeConstant(this, Value)
            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                try
                    tau = Value;
                    if (isscalar(tau) && isnumeric(tau) && isreal(tau) ...
                            && isfinite(tau) && tau > 0)
                        this.SpecData.Tau = tau;
                        this.notify('SpecDataChanged');
                    else
                        eMessage = getString(message(...
                            'Control:compDesignTask:IMCTauRequirement'));

                        uialert(getWidget(this.Dlg), eMessage, this.Dlg.Title, Icon='error');
                        updateUI(this);
                    end
                catch ME
                    uialert(getWidget(this.Dlg), ME.message, this.Dlg.Title, Icon='error');
                    updateUI(this);
                end
            end
        end

        function updateOrder(this, Value)

            if isempty(Value) || all(isspace(Value))
                updateUI(this);
            else
                spinnerMinValue = this.Widgets.OrderSpinner.Limits(1);
                spinnerMaxValue = this.Widgets.OrderSpinner.Limits(2);
                if isnumeric(Value) && isreal(Value)
                    this.SpecData.DesiredOrder = Value;
                    if Value <= spinnerMaxValue && ...
                            Value >= spinnerMinValue
                        this.SpecData.DesiredOrder = Value;
                        this.Widgets.OrderSpinner.Value = Value;
                    elseif Value > spinnerMaxValue
                        this.SpecData.DesiredOrder = spinnerMaxValue;
                        this.Widgets.OrderSpinner.Value = spinnerMaxValue;
                    elseif  Value < spinnerMinValue
                        this.SpecData.DesiredOrder = spinnerMinValue;
                        this.Widgets.OrderSpinner.Value = spinnerMinValue;
                    end
                    this.notify('SpecDataChanged');
                else
                    updateUI(this);
                end

            end

        end

        function Order = calcOrder(this)
            OL = overloadOpenLoopPlant(this);
            Model = this.Dlg.utApproxDelay(OL);
            Order = 1;
            if ~isa(Model,'frd')
                [Zero, Pole, Gain, Ts] = zpkdata(Model,'v');
                Ts = abs(Ts);
                if Ts==0
                    % indices of open RHP zeros
                    indRHPzero = (real(Zero) >0);
                    % indices of open RHP poles
                    indRHPpole = (real(Pole)>0);
                    % indices of integrators
                    indIntegrator = (real(Pole)==0)&(imag(Pole)==0);
                    % number of open RHP zeros
                    NumRHPzeros = sum(indRHPzero);
                    % number of open RHP poles
                    NumRHPpoles = sum(indRHPpole);
                    % number of integrators
                    NumIntegrator = sum(indIntegrator);

                    IsPlantStable = (NumRHPpoles+NumIntegrator==0);
                    IsPlantMP = (NumRHPzeros==0);

                    if IsPlantStable
                        Order = order(Model)+1;
                    elseif IsPlantMP
                        Order = order(Model)+NumRHPpoles+NumIntegrator+1;
                    else
                        Order = order(Model)+NumRHPpoles+NumIntegrator+NumRHPzeros+1;
                    end
                else
                    % indices of open RHP zeros
                    indRHPzero = (abs(Zero)>1);
                    % indices of open RHP poles
                    indRHPpole = (abs(Pole)>1);
                    % indices of integrators
                    indIntegrator = (real(Pole)==1)&(imag(Pole)==0);
                    % number of open RHP zeros
                    NumRHPzeros = sum(indRHPzero);
                    % number of open RHP poles
                    NumRHPpoles = sum(indRHPpole);
                    % number of integrators
                    NumIntegrator = sum(indIntegrator);

                    IsPlantStable = (NumRHPpoles+NumIntegrator==0);
                    IsPlantMP = (NumRHPzeros==0);
                    if IsPlantStable
                        Order = order(Model)+length(Zero)+1;
                    elseif IsPlantMP
                        Order = order(Model)+1;
                    else
                        Order = order(Model)+length(Zero)+sum(real(Zero)<0)*2+(NumRHPpoles+NumIntegrator)*2+NumRHPzeros+1;
                    end
                end
            end
        end
    end

    methods (Hidden)
        function order = qelocalCalcOrder(this)
            order = calcOrder(this);
        end
    end
end

function Order = localCalcOrder(Model)
[Zero, Pole, Gain, Ts] = zpkdata(Model,'v');
Ts = abs(Ts);
if Ts==0
    % indices of open RHP zeros
    indRHPzero = (real(Zero) >0);
    % indices of open RHP poles
    indRHPpole = (real(Pole)>0);
    % indices of integrators
    indIntegrator = (real(Pole)==0)&(imag(Pole)==0);
    % number of open RHP zeros
    NumRHPzeros = sum(indRHPzero);
    % number of open RHP poles
    NumRHPpoles = sum(indRHPpole);
    % number of integrators
    NumIntegrator = sum(indIntegrator);

    IsPlantStable = (NumRHPpoles+NumIntegrator==0);
    IsPlantMP = (NumRHPzeros==0);

    if IsPlantStable
        Order = order(Model)+1;
    elseif IsPlantMP
        Order = order(Model)+NumRHPpoles+NumIntegrator+1;
    else
        Order = order(Model)+NumRHPpoles+NumIntegrator+NumRHPzeros+1;
    end
else
    % indices of open RHP zeros
    indRHPzero = (abs(Zero)>1);
    % indices of open RHP poles
    indRHPpole = (abs(Pole)>1);
    % indices of integrators
    indIntegrator = (real(Pole)==1)&(imag(Pole)==0);
    % number of open RHP zeros
    NumRHPzeros = sum(indRHPzero);
    % number of open RHP poles
    NumRHPpoles = sum(indRHPpole);
    % number of integrators
    NumIntegrator = sum(indIntegrator);

    IsPlantStable = (NumRHPpoles+NumIntegrator==0);
    IsPlantMP = (NumRHPzeros==0);
    if IsPlantStable
        Order = order(Model)+length(Zero)+1;
    elseif IsPlantMP
        Order = order(Model)+1;
    else
        Order = order(Model)+length(Zero)+sum(real(Zero)<0)*2+(NumRHPpoles+NumIntegrator)*2+NumRHPzeros+1;
    end
end
end