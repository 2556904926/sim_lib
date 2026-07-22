classdef LQGSpecPanel < ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel
%     Panel that is used to tune the compensators via PID Classical Methd
%     
%     To use the panel in a dialog
%     c = ctrlguis.csdesignerapp.panels.internal.LQGSpecPanel('Parent', uigridlayout)
    
    
    
    properties
    end
    
    methods
        function this = LQGSpecPanel(Dialog, Parent, SpecData, varargin)
            
            % Superclass constructor
            this = this@ctrlguis.csdesignerapp.panels.internal.CompensatorSpecPanel(Parent);
            
            % resassign property values
            this.Dlg = Dialog;
            this.Parent = Parent;
            this.Name = 'CSD_LQGSpecPanel';
            set(this, 'SpecData', SpecData);
            this.SpecData = SpecData;
            
            % build panel
            buildContainer(this)
        end
        
        function createWidgets(this)
            createSliders(this);
            createDefaultSpecData(this)
        end
        
        
    end
    
    %% Protected Methods %%
    methods (Access = protected)
        %% UI Methods
        %% Data 
        function createDefaultSpecData(this)
            this.SpecData.ControllerResponse = 35;
            this.SpecData.MeasurementNoise = 25;
            
            if isempty(this.Response) || isempty(this.Compensator)
                this.SpecData.DesiredOrder = 1;
            else
                this.SpecData.DesiredOrder = localCalcOrder(this);
            end
        end
        
        function createSliders(this)
            sliderLayout = uigridlayout(this.Layout,RowHeight=repmat({'fit'},1,5),...
                ColumnWidth={'fit','fit','1x','fit'});
            sliderLayout.Padding = 0;
            sliderLayout.Layout.Row = 1;
            sliderLayout.Layout.Column = [1 4];

            responseLabel = uilabel(sliderLayout, 'Text', ...
                                  getString(message('Control:designerapp:strControllerResponseLabel')));
            responseLabel.Layout.Row = 1;
            responseLabel.Layout.Column = 1;
            
            responseSlider = uislider(sliderLayout);
            responseSlider.Layout.Row = 1;
            responseSlider.Layout.Column = [2 4];
            responseSlider.Limits = [0 100];
            responseSlider.Value = 35;
            responseSlider.MinorTicks = [0 25 50 75 100];
            responseSlider.MajorTicks = [];
            responseSlider.MajorTickLabels = {};

            aggressiveLabel = uilabel(sliderLayout,Text="Aggressive");
            aggressiveLabel.Layout.Row = 2;
            aggressiveLabel.Layout.Column = 2;
            robustLabel = uilabel(sliderLayout,Text="Robust");
            robustLabel.Layout.Row = 2;
            robustLabel.Layout.Column = 4;
            
            
            % create slider for Measurement noise
            noiseLabel = uilabel(sliderLayout, 'Text', ...
                                  getString(message( ...
                                  'Control:designerapp:strMeasurementNoiseLabel')));
            noiseLabel.Layout.Row = 3;
            noiseLabel.Layout.Column = 1;
            noiseSlider = uislider(sliderLayout);
            noiseSlider.Layout.Row = 3;
            noiseSlider.Layout.Column = [2 4];
            noiseSlider.Limits = [0 100];
            noiseSlider.Value = 25;
            noiseSlider.MinorTicks = [0 25 50 75 100];
            noiseSlider.MajorTicks = [];
            noiseSlider.MajorTickLabels = {};
            
            smallLabel = uilabel(sliderLayout,Text="Small");
            smallLabel.Layout.Row = 4;
            smallLabel.Layout.Column = 2;
            largeLabel = uilabel(sliderLayout,Text="Large");
            largeLabel.Layout.Row = 4;
            largeLabel.Layout.Column = 4;

            orderLabel = uilabel(sliderLayout, 'Text', 'Desired Controller Order');
            orderLabel.Layout.Row = 5;
            orderLabel.Layout.Column = 1;
            
            orderSpinner = uispinner(sliderLayout);
            orderSpinner.Layout.Row = 5;
            orderSpinner.Layout.Column = 2;
            orderSpinner.Value = 3;
            orderSpinner.Limits = [1 10];
            
            this.Widgets.ResponseLabel = responseLabel;
            this.Widgets.NoiseLabel = noiseLabel;
            this.Widgets.ResponseSlider = responseSlider;
            this.Widgets.NoiseSlider = noiseSlider;
            this.Widgets.OrderLabel = orderLabel;
            this.Widgets.OrderSpinner = orderSpinner;
        end
        
        %% Adding Listeners
        function connectUI(this)
            weakThis = matlab.lang.WeakReference(this);
            responseListener = addlistener(this.Widgets.ResponseSlider, ...
                'ValueChanged', ...
                @(es, ed) updateControllerResponse(weakThis.Handle, es.Value));
            noiseListener = addlistener(this.Widgets.NoiseSlider, ...
                'ValueChanged', ...
                @(es, ed) updateMeasurementNoise(weakThis.Handle, es.Value));
            orderListener = addlistener(this.Widgets.OrderSpinner, ...
                'ValueChanged', ...
                @(es, ed) updateOrder(weakThis.Handle, es.Value));

            this.UIListeners{end+1} = responseListener;
            this.UIListeners{end+1} = noiseListener;
            this.UIListeners{end+1} = orderListener;
        end
        
        %% callabcks for ui components
        function updateControllerResponse(this, Value)
            this.SpecData.ControllerResponse = round(Value);
            this.notify('SpecDataChanged');
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

        function updateMeasurementNoise(this, Value)
            this.SpecData.MeasurementNoise = round(Value);
            this.notify('SpecDataChanged');
        end

        
        function refreshUI(this)
            if this.Panel.Visible
                Order = localCalcOrder(this);
                % update slider with limits, ticks, & labels
                this.Widgets.OrderSpinner.Limits = [1 Order];
                % TO-DO: double check with order value increments
                %             this.Widgets.OrderSpinner.Step = 1;
                if this.SpecData.DesiredOrder < Order
                    this.Widgets.OrderSpinner.Value = this.SpecData.DesiredOrder;
                elseif this.Widgets.OrderSpinner.Value < Order
                    this.SpecData.DesiredOrder = this.Widgets.OrderSpinner.Value;
                    this.notify('SpecDataChanged');
                else
                    this.Widgets.OrderSpinner.Value = Order;
                    this.SpecData.DesiredOrder = Order;
                    this.notify('SpecDataChanged');
                end

                %update response slider
                this.Widgets.ResponseSlider.Value = ...
                    this.SpecData.ControllerResponse;

                %update noise slider
                this.Widgets.NoiseSlider.Value = ...
                    this.SpecData.MeasurementNoise;
            end
        end
        
        function Order = localCalcOrder(this)
            % Calculate order of the system
            OL = get(this, 'OpenLoopPlant');
            Model = this.Dlg.utApproxDelay(OL);
            Order = order(Model)+1;
            
        end 
    end
    
    methods (Hidden)
        function order = qelocalCalcOrder(this)
            order = localCalcOrder(this);
        end
    end
end