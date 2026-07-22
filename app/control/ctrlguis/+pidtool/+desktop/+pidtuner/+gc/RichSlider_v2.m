classdef RichSlider_v2 < handle
    %RICHSLIDER

    % Copyright 2013-2019 The MathWorks, Inc.
    properties (Dependent = true, SetObservable = true, AbortSet = true)
        Value
        MinimumValue
        MaximumValue
        Free
    end
    properties (Dependent = true, AbortSet = true)
        TickSequence
        LabelTable
        Resolution
        RightIncreasing
        MinMaxBounds
    end
    properties (SetAccess = private)
        NameTPComponent
        SliderTPComponent
        SpinnerTPComponent
        MinEditTPComponent
        MaxEditTPComponent
        RangeUpTPComponent
        RangeDownTPComponent
        FixTPComponent
    end
    properties
        Scale = 'linear'
    end
    properties(Access = private)
        RangeMultiplier_
        Value_ = 15
        MinimumValue_ = 10
        MaximumValue_ = 20
        MinMaxBounds_ = [-inf inf]
        SliderValue_
        SliderPosition_
        SpinnerValue_
        SpinnerPosition_
        SpinnerText_
        SliderMappingCoefficients
        invSliderMappingCoefficients
        SpinnerMappingCoefficients
        invSpinnerMappingCoefficients
        MinText_
        MaxText_
        LabelTable_
        TickSequence_ = {'value', 'tick', 'Slider', 'tick', 'value'}
        Ticks_ = 5
        Free_ = true
        RightIncreasing_ = true
        Listeners
        SpinnerToSliderResolutionRatio = 5
    end
    properties(Access = private, Dependent = true, AbortSet = true)
        SliderValue
        SliderPosition
        SpinnerValue
        SpinnerPosition
        preSpinnerText
        postSpinnerText
        preMinText
        postMinText
        preMaxText
        postMaxText
        RangeMultiplier
    end
    events
        DataChanged
    end
    methods
        function this = RichSlider_v2(min, max, value, TPComponentSettings)
            %RICHSLIDER
            %=======================================================================================================(Widgets)
            if nargin >= 3
                this.MinimumValue_ = min;
                this.MaximumValue_ = max;
                this.Value_ = value;
            end
            if nargin == 4
                SliderMin = TPComponentSettings.Min;
                SliderMax = TPComponentSettings.Max;
                SliderDefault = (SliderMin+SliderMax)/2;
            else
                SliderMin = 0;
                SliderMax = 100;
                SliderDefault = 50;
            end
            
            import matlab.ui.internal.toolstrip.*
            this.NameTPComponent = Label('Slider');
            this.NameTPComponent.Tag = 'RichSlider:SliderParName';
            this.SliderTPComponent = Slider([SliderMin,SliderMax],SliderDefault);
            this.SliderTPComponent.Tag = 'RichSlider:Slider';
            this.SpinnerTPComponent = Spinner([SliderMin SliderMax]*this.SpinnerToSliderResolutionRatio,...
                50*this.SpinnerToSliderResolutionRatio);
            this.SpinnerTPComponent.Tag = 'RichSlider:Spinner';
            this.SpinnerTPComponent.NumberFormat = 'double';
            this.MinEditTPComponent = EditField('5');
            this.MinEditTPComponent.Tag = 'RichSlider:MinEditTextField';
            this.MaxEditTPComponent = EditField('5');
            this.MaxEditTPComponent.Tag = 'RichSlider:MaxEditTextField';
            this.RangeUpTPComponent = Button('',Icon('chevronDoubleEastUI'));
            this.RangeUpTPComponent.Tag = 'RichSlider:RangeUpButton';
            this.RangeDownTPComponent = Button('',Icon('chevronDoubleWestUI'));
            this.RangeDownTPComponent.Tag = 'RichSlider:RangeDownButton';
            this.FixTPComponent = CheckBox(pidtool.utPIDgetStrings('cst','strFix'));
            this.FixTPComponent.Tag = 'RichSlider:FixCheckbox';
            %===============================================================================================(Initialize view)
            this.updateMapping();
            this.updateView();
            %=================================================================================================(Add listeners)
            
            % Add default labels to slider
            midVal = (SliderMin+SliderMax/2);
            labelTable = {num2str(this.MinimumValue_) SliderMin; 'Slider' midVal; num2str(this.MaximumValue_) SliderMax};
            this.SliderTPComponent.Labels = labelTable;
            
            addlistener(this.SliderTPComponent,'ValueChanged',@this.sliderCallback);
            addlistener(this.SpinnerTPComponent,'ValueChanged',@this.spinnerCallback);
            addlistener(this.MinEditTPComponent,'ValueChanged',@this.minEditCallback);
            addlistener(this.MaxEditTPComponent,'ValueChanged',@this.maxEditCallback);
            addlistener(this.RangeUpTPComponent, 'ButtonPushed', @this.rangeUpButtonCallback);
            addlistener(this.RangeDownTPComponent, 'ButtonPushed', @this.rangeDownButtonCallback);
            addlistener(this.FixTPComponent, 'ValueChanged', @this.fixCheckboxCallback);
        end
        %============================================================================================================(Valule)
        function val = get.Value(this)
            %GET_VALUE
            val = this.Value_;
        end
        function set.Value(this, val)
            %SET_VALUE
            if val < this.MinMaxBounds(1) || val > this.MinMaxBounds(2)
                if val < this.MinMaxBounds(1)
                    val = this.MinMaxBounds(1);
                else
                    val = this.MinMaxBounds(2);
                end
            end
            this.Value_ = val;
            this.updateSliderView();
            this.updateSpinnerView();
            this.updateSpinnerTextView();
        end
        %===============================================================================================================(Min)
        function val = get.MinimumValue(this)
            %GET_MINIMUMVALUE
            val = this.MinimumValue_;
        end
        function set.MinimumValue(this, val)
            %SET_MINIMUMVALUE
            if val > this.MaximumValue_
                this.MinimumValue_ = this.MaximumValue_;
            elseif val < this.MinMaxBounds(1)
                this.MinimumValue_ = this.MinMaxBounds(1);
            else
                this.MinimumValue_ = val;
            end
            this.updateMapping();
            if (val > this.Value_)
                this.SliderPosition = this.SliderTPComponent.Value;
            else
                this.updateSliderView();
                this.updateSpinnerView();
            end
            this.updateMinTextView();
            this.updateLabelTableView();
            this.RangeMultiplier_ = [];
            this.updateChevronsView();
        end
        %===============================================================================================================(Max)
        function val = get.MaximumValue(this)
            %GET_MAXIMUMVALUE
            val = this.MaximumValue_;
        end
        function set.MaximumValue(this, val)
            %SET_MAXIMUMVALUE
            if val < this.MinimumValue_
                this.MaximumValue_ = this.MinimumValue_;
            elseif val > this.MinMaxBounds(2)
                this.MaximumValue_ = this.MinMaxBounds(2);
            else
                this.MaximumValue_ = val;
            end
            this.updateMapping();
            if (val < this.Value_)
                this.SliderPosition = this.SliderTPComponent.Value;
            else
                this.updateSliderView();
                this.updateSpinnerView();
            end
            this.updateMaxTextView();
            this.updateLabelTableView();
            this.RangeMultiplier_ = [];
            this.updateChevronsView();
        end
        %============================================================================================================(Slider)
        function val = get.SliderPosition(this)
            %GET_SLIDERPOSITION
            val = this.SliderPosition_;
        end
        function set.SliderPosition(this, val)
            %SET_SLIDERPOSITION
            this.SliderPosition_ = val;
            sliderval = localGetValueFromSliderPosition(this, val);
            this.SliderValue_ = sliderval;
            this.Value = sliderval;
        end
        function val = get.SliderValue(this)
            %GET_SLIDERVALUE
            val = this.SliderValue_;
        end
        function set.SliderValue(this, val)
            %SET_SLIDERVALUE
            sliderpos = localGetSliderPositionFromValue(this, val);
            if ((sliderpos > this.Resolution) || (sliderpos < 0))
                this.resetMinMaxBasedOnValue(val);
                return
            end
            this.SliderPosition_ = sliderpos;
            this.SliderTPComponent.Value = sliderpos;
        end
        function updateSliderView(this)
            %UPDATESLIDERVIEW
            this.SliderValue = this.Value_;
        end
        %===========================================================================================================(Spinner)
        function val = get.SpinnerPosition(this)
            %GET_SPINNERPOSITION
            val = this.SpinnerPosition_;
        end
        function set.SpinnerPosition(this, val)
            %SET_SPINNERPOSITION
            this.SpinnerPosition_ = val;
            sliderval = val;
            this.SpinnerValue_ = sliderval;
            this.Value = sliderval;
        end
        function val = get.SpinnerValue(this)
            %GET_SPINNERVALUE
            val = this.SpinnerValue_;
        end
        function set.SpinnerValue(this,~)
            %SET_SPINNERVALUE
            this.SpinnerPosition_ = this.Value_;
            this.SpinnerTPComponent.Value = this.Value_;
        end
        function updateSpinnerView(this)
            %UPDATESPINNERVIEW
            this.SpinnerValue = this.Value_;
            ValueExponent = floor(log10(this.Value_));
            ValueNumber = ceil(this.Value_/(10^ValueExponent));
            newValue = ValueNumber*10^ValueExponent;
            if strcmp(this.Scale,'logarithmic')
                StepSize = abs(newValue/this.Resolution);
            else
                % Check for if MinValue = MaxValue
                diffVal = abs(this.MaximumValue - this.MinimumValue);
                if (diffVal < eps)
                    StepSize = this.SpinnerTPComponent.StepSize;
                else
                    StepSize = abs(this.MaximumValue - this.MinimumValue)/50;
                end
            end
            
            % Change Decimal Format
            if StepSize < 1
                DecFormat = [num2str(ceil(abs(log10(StepSize)))+1) 'f'];
            else
                DecFormat = '0f';
            end
            this.SpinnerTPComponent.StepSize = StepSize;
            this.SpinnerTPComponent.DecimalFormat = DecFormat;
                
        end
        function updateChevronsView(this)
            %UPDATECHEVRONSVIEW
            if this.MaximumValue == this.MinMaxBounds(2)
                if this.RightIncreasing
                    this.RangeUpTPComponent.Enabled = false;
                else
                    this.RangeDownTPComponent.Enabled = false;
                end
            else
                if this.RightIncreasing
                    this.RangeUpTPComponent.Enabled = true;
                else
                    this.RangeDownTPComponent.Enabled = true;
                end
            end
            if this.MinimumValue == this.MinMaxBounds(1)
                if this.RightIncreasing
                    this.RangeDownTPComponent.Enabled = false;
                else
                    this.RangeUpTPComponent.Enabled = false;
                end
            else
                if this.RightIncreasing
                    this.RangeDownTPComponent.Enabled = true;
                else
                    this.RangeUpTPComponent.Enabled = true;
                end
            end
        end

        %% Spinner Methods
        %======================================================================================================(Spinner Text)
        function val = get.preSpinnerText(this)
            %GET_PRESPINNERTEXT
            val = this.SpinnerText_;
        end
        function set.preSpinnerText(this, val)
            %SET_PRESPINNERTEXT
            this.SpinnerText_ = val;
            if strcmp(this.Scale, 'logarithmic')
                numval = localGetValueFromText(val, true);
            else
                numval = localGetValueFromText(val, false);
            end
            this.SpinnerTPComponent.Value = numval;
        end
        function val = get.postSpinnerText(this)
            %GET_POSTSPINNERTEXT
            val = this.SpinnerText_;
        end
        function set.postSpinnerText(this, val)
            %SET_POSTSPINNERTEXT
            this.SpinnerText_ = val;
            if strcmp(this.Scale, 'logarithmic')
                numval = localGetValueFromText(val, true);
            else
                numval = localGetValueFromText(val, false);
            end
            if isempty(numval)
                this.updateSpinnerTextView();
            else
                this.Value = numval;
            end
        end
        function updateSpinnerTextView(this)
            %UPDATESPINNERTEXTVIEW
            this.preSpinnerText = localGetTextFromValue(this.Value_);
        end

        %% Min/Max Methods
        %==========================================================================================================(Min Text)
        function val = get.preMinText(this)
            %GET_PREMINTEXT
            val = this.MinText_;
        end
        function set.preMinText(this, val)
            %SET_PREMINTEXT
            this.MinText_ = val;
            this.MinEditTPComponent.Value = val;
        end
        function val = get.postMinText(this)
            %GET_POSTMINTEXT
            val = this.MinText_;
        end
        function set.postMinText(this, val)
            %SET_POSTMINTEXT
            this.MinText_ = val;
            if strcmp(this.Scale, 'logarithmic')
                numval = localGetValueFromText(val, true);
            else
                numval = localGetValueFromText(val, false);
            end
            if isempty(numval)
                this.updateMinTextView();
            else
                this.MinimumValue = numval;
            end
        end
        function updateMinTextView(this)
            %UPDATEMINTEXTVIEW
            this.preMinText = localGetTextFromValue(this.MinimumValue_);
        end
        %==========================================================================================================(Max Text)
        function val = get.preMaxText(this)
            %GET_PREMAXTEXT
            val = this.MaxText_;
        end
        function set.preMaxText(this, val)
            %SET_PREMAXTEXT
            this.MaxText_ = val;
            this.MaxEditTPComponent.Value = val;
        end
        function val = get.postMaxText(this)
            %GET_POSTMAXTEXT
            val = this.MaxText_;
        end
        function set.postMaxText(this, val)
            %SET_POSTMAXTEXT
            this.MaxText_ = val;
            if strcmp(this.Scale, 'logarithmic')
                numval = localGetValueFromText(val, true);
            else
                numval = localGetValueFromText(val, false);
            end
            if isempty(numval)
                this.updateMaxTextView();
            else
                this.MaximumValue = numval;
            end
        end
        function updateMaxTextView(this)
            %UPDATEMAXTEXTVIEW
            this.preMaxText = localGetTextFromValue(this.MaximumValue_);
        end
        
        %% Slider Labels/Ticks
        %=======================================================================================================(Label Tabel)
        function val = get.LabelTable(this)
            %GET_LABELTABLE
            val = this.LabelTable_;
        end
        function set.LabelTable(this, val)
            %SET_LABELTABLE
            this.LabelTable_ = val;
            this.TickSequence_ = [];
            this.updateLabelTableView();
        end
        function val = get.TickSequence(this)
            %GET_TICKSEQUENCE
            val = this.TickSequence_;
        end
        function set.TickSequence(this, tickseq)
            %SET_TICKSEQUENCE
            this.TickSequence_ = tickseq;
            this.Ticks_ = length(tickseq);
            this.updateLabelTableMapping();
            this.updateLabelTableView();
        end
        function updateLabelTableMapping(this)
            %UPDATELABELTABLEMAPPING
            tickseq = this.TickSequence;
            if isempty(tickseq)
                return;
            end
            idx = strcmp(tickseq,'tick');
            tickseq = tickseq(~idx);
            n = length(tickseq);
            val = cell(n,2);
            tickvals = round(linspace(0, this.Resolution,n));
            for i = 1:n
                tickstr = tickseq{i};
                switch tickstr
                    case 'value'
                        val{i,1} = sprintf('%0.3g',localGetValueFromSliderPosition(this,tickvals(i)));
                        val{i,2} = tickvals(i);
                    case 'tick'
                        % Do nothing here
                    otherwise
                        val{i,1} = tickstr;
                        val{i,2} = tickvals(i);
                end
            end
            this.LabelTable_ = val;
        end
        function updateLabelTableView(this)
            %UPDATELABELTABLEVIEW
            % Need to "reset" the labels and ticks before setting the
            % properties
            this.SliderTPComponent.Labels = {};
            this.SliderTPComponent.Ticks = 0;
            this.SliderTPComponent.Labels = this.LabelTable_;
            this.SliderTPComponent.Ticks = this.Ticks_;
        end

        %% Slider Scaling
        %==============================================================================================================(Free)
        function val = get.Free(this)
            %GET_FREE
            val = this.Free_;
        end
        function set.Free(this, val)
            %SET_FREE
            this.Free_ = val;
            this.SliderTPComponent.Enabled = val;
            this.SpinnerTPComponent.Enabled = val;
            this.MinEditTPComponent.Enabled = val;
            this.MaxEditTPComponent.Enabled = val;
            this.RangeUpTPComponent.Enabled = val;
            this.RangeDownTPComponent.Enabled = val;
        end
        %========================================================================================================(Resolution)
        function val = get.Resolution(this)
            %GET_RESOLUTION
            val = this.SliderTPComponent.Limits(2);
        end
        function set.Resolution(this, val)
            %SET_RESOLUTION
            this.SliderTPComponent.Limits(2) = val;
            this.SpinnerTPComponent.Limits(2) = val*this.SpinnerToSliderResolutionRatio;
            this.updateMapping();
            this.updateView();
        end
        %=============================================================================================================(Scale)
        function set.Scale(this,val)
            %SET_SCALE
            if ~ismember(val,{'logarithmic','linear'})
                error('Invalid setting for Scale');
            end
            this.Scale = val;
            this.updateMapping();
            this.updateView();
        end
        %===========================================================================================================(Mapping)
        function updateMapping(this)
            %UPDATEMAPPING
            min = this.MinimumValue_;
            max = this.MaximumValue_;
            switch this.Scale
                case 'logarithmic'
                    if this.RightIncreasing
                        this.SliderMappingCoefficients = [min max/min];
                        this.invSliderMappingCoefficients = [1 -log10(min)]/log10(max/min);
                    else
                        this.SliderMappingCoefficients = [max min/max];
                        this.invSliderMappingCoefficients = [1 -log10(max)]/log10(min/max);
                    end
                    this.SpinnerMappingCoefficients = [min max/min];
                    this.invSpinnerMappingCoefficients = [1 -log10(min)]/log10(max/min);
                case 'linear'
                    if this.RightIncreasing
                        this.SliderMappingCoefficients = [(max - min) min];
                        this.invSliderMappingCoefficients = [1 -min]/(max - min);
                    else
                        this.SliderMappingCoefficients = [(min - max) max];
                        this.invSliderMappingCoefficients = [1 -max]/(min - max);
                    end
                    this.SpinnerMappingCoefficients = [(max - min) min];
                    this.invSpinnerMappingCoefficients = [1 -min]/(max - min);
            end
            this.SliderValue_ = [];
            this.SliderPosition_ = [];
            this.SpinnerValue_ = [];
            this.SpinnerPosition_ = [];
            this.updateLabelTableMapping();
        end
        %==============================================================================================================(View)
        function updateView(this)
            %UPDATEVIEW
            this.updateSliderView();
            this.updateSpinnerView();
            this.updateSpinnerTextView();
            this.updateMinTextView();
            this.updateMaxTextView();
            this.updateLabelTableView();
            this.updateChevronsView();
        end
        %==================================================================================================(Right increasing)
        function val = get.RightIncreasing(this)
            %GET_RIGHTINCREASING
            val = this.RightIncreasing_;
        end
        function set.RightIncreasing(this, val)
            %SET_RIGHTINCREASING
            this.RightIncreasing_ = val;
            this.updateMapping();
            this.updateView();
        end
        %====================================================================================================(Min/Max bounds)
        function set.MinMaxBounds(this, val)
            %SET_MINMAXBOUNDS
            assert((numel(val) == 2) & (val(2) > val(1)));
            min_ = this.MinimumValue_;
            max_ = this.MaximumValue_;
            MIN_ = val(1);
            MAX_ = val(2);
            min_ = min(max(min_, MIN_), MAX_);
            max_ = max(min(max_,MAX_),MIN_);
            this.atomicSet(min_,max_,[],val,[],[],[],[]);
        end
        function val = get.MinMaxBounds(this)
            %GET_MINMAXBOUNDS
            val = this.MinMaxBounds_;
        end
        %========================================================================================================(Atomic set)
        function atomicSet(this, min_, max_, val_, minmaxbounds, rightincreasing, ticks, labeltable, numTicks)
            %ATOMICSET
            assert(max_>=min_);
            if ~isempty(minmaxbounds)
                assert((min_ >= minmaxbounds(1))&&(max_ <= minmaxbounds(2)));
                this.MinMaxBounds_ = minmaxbounds;
            end
            this.MinimumValue_ = min_;
            this.MaximumValue_ = max_;
            if ~isempty(rightincreasing)
                this.RightIncreasing_ = rightincreasing;
                this.RangeMultiplier_ = [];
            end
            if ~isempty(ticks)
                this.TickSequence_ = ticks;
                this.Ticks_ = length(ticks);
            end
            if ~isempty(numTicks)
                if ~isempty(ticks)
                    assert(length(ticks)==numTicks)
                end
                this.Ticks_ = numTicks;
            end
            if ~isempty(labeltable)
                this.LabelTable_ = labeltable;
                this.TickSequence_ = [];
            end
            this.updateMapping();
            if isempty(val_)
                this.SliderPosition = this.SliderTPComponent.Value;
            else
                % Adjust val if numerical error is introduced
                if val_<min_
                    val_ = min_;
                elseif val_>max_
                    val_ = max_;
                end
                assert((val_ >= min_)&&(val_ <= max_));
                this.Value_ = val_;
            end
            this.updateView();
            this.notify('DataChanged');
        end
        %=============================================================================(Reset min max when Value out of range)
        function resetMinMaxBasedOnValue(this, val)
            %RESETMINMAXBASEDONVALUE
            min_ = this.MinimumValue_;
            max_ = this.MaximumValue_;
            MIN_ = this.MinMaxBounds(1);
            MAX_ = this.MinMaxBounds(2);
            switch this.Scale
                case 'logarithmic'
                    newmin = max(val/sqrt(max_/min_), MIN_);
                    newmax = min(val*sqrt(max_/min_), MAX_);
                case 'linear'
                    newmin = max(val - (max_ - min_)/2, MIN_);
                    newmax = min(val + (max_ - min_)/2, MAX_);
            end
            this.atomicSet(newmin, newmax, val, [],[],[],[],[]);
        end
        %=======================================================================================================(Range Shift)
        function val = get.RangeMultiplier(this)
            %GET_RANGEMULTIPLIER
            val = this.RangeMultiplier_;
            if isempty(val)
                if strcmp(this.Scale, 'linear')
                    val = (this.MaximumValue_ - this.MinimumValue_)/1;
                else
                    val = 10; %sqrt(this.MaximumValue_/this.MinimumValue_); for a more general case
                end
                this.RangeMultiplier_ = val;
            end
        end
        %=========================================================================================================(Callbacks)
        function sliderCallback(this, src, ~)
            %SLIDERCALLBACK
            this.SliderPosition = src.Value;
        end
        function spinnerCallback(this, src, ~)
            %SPINNERCALLBACK
            this.SpinnerPosition = src.Value;
            this.postSpinnerText = localGetTextFromValue(src.Value);
        end
        function minEditCallback(this, src, ~)
            %MINEDITCALLBACK
            this.postMinText = src.Value;
        end
        function maxEditCallback(this, src, ~)
            %MAXEDITCALLBACK
            this.postMaxText = src.Value;
        end
        function rangeUpButtonCallback(this, ~, ~)
            %RANGEUPBUTTONCALLBACK
            if strcmp(this.Scale, 'linear')
                if this.RightIncreasing
                    factor = this.RangeMultiplier;
                else
                    factor = -this.RangeMultiplier;
                end
                outfactor = this.shiftLinearRange(factor);
                if outfactor == factor
                    this.RangeMultiplier_ = [];
                else
                    if outfactor ~= 0
                        if this.RightIncreasing
                            this.RangeMultiplier_ =  outfactor;
                        else
                            this.RangeMultiplier_ =  -outfactor;
                        end
                    end
                end
            else
                if this.RightIncreasing
                    factor = this.RangeMultiplier;
                else
                    factor = 1/this.RangeMultiplier;
                end
                outfactor = this.shiftLogRange(factor);
                if outfactor == factor
                    this.RangeMultiplier_ = [];
                else
                    if outfactor ~= 1
                        if this.RightIncreasing
                            this.RangeMultiplier_ =  outfactor;
                        else
                            this.RangeMultiplier_ =  1/outfactor;
                        end
                    end
                end
            end
        end
        function rangeDownButtonCallback(this, ~, ~)
            %RANGEDOWNBUTTONCALLBACK
            if strcmp(this.Scale, 'linear')
                if this.RightIncreasing
                    factor = -this.RangeMultiplier;
                else
                    factor = this.RangeMultiplier;
                end
                outfactor = this.shiftLinearRange(factor);
                if outfactor == factor
                    this.RangeMultiplier_ = [];
                else
                    if outfactor ~= 0
                        if this.RightIncreasing
                            this.RangeMultiplier_ =  -outfactor;
                        else
                            this.RangeMultiplier_ =  outfactor;
                        end
                    end
                end
            else
                if this.RightIncreasing
                    factor = 1/this.RangeMultiplier;
                else
                    factor = this.RangeMultiplier;
                end
                outfactor = this.shiftLogRange(factor);
                if outfactor == factor
                    this.RangeMultiplier_ = [];
                else
                    if outfactor ~= 1
                        if this.RightIncreasing
                            this.RangeMultiplier_ =  1/outfactor;
                        else
                            this.RangeMultiplier_ =  outfactor;
                        end
                    end
                end
            end
        end
        function outfactor = shiftLogRange(this, factor)
            %MULTIPLYRANGEBYFACTOR
            max_ = min(this.MaximumValue_*factor, this.MinMaxBounds(2));
            factor1 = max_/this.MaximumValue_;
            min_ = max(this.MinimumValue_*factor, this.MinMaxBounds(1));
            factor2 = min_/this.MinimumValue_;
            if factor > 1
                outfactor = min(factor1, factor2);
            else
                outfactor = max(factor1, factor2);
            end
            min_ = this.MinimumValue_*outfactor;
            max_ = this.MaximumValue_*outfactor;
            val_ = this.Value_*outfactor;
            this.atomicSet(min_,max_,val_,[],[],[],[],[]);
        end
        function outdisp = shiftLinearRange(this, disp)
            %MULTIPLYRANGEBYFACTOR
            max_ = min(this.MaximumValue_+disp, this.MinMaxBounds(2));
            disp1 = max_ - this.MaximumValue_;
            min_ = max(this.MinimumValue_+disp, this.MinMaxBounds(1));
            disp2 = min_ - this.MinimumValue_;
            if disp > 0
                outdisp = min(disp1, disp2);
            else
                outdisp = max(disp1, disp2);
            end
            min_ = this.MinimumValue_+outdisp;
            max_ = this.MaximumValue_+outdisp;
            val_ = this.Value_+outdisp;
            this.atomicSet(min_,max_,val_,[],[],[],[],[]);
        end
        function fixCheckboxCallback(this, src, ~)
            %FIXCHECKBOXCALLBACK
            this.Free = ~src.Value;
        end
        
        function spinnerTextCallback(this,src, ~)
            %SPINNERTEXTCALLBACK
            % this.postSpinnerText = char(src.getText());
            this.postSpinnerText = localGetTextFromValue(src.Value);
        end
    end
end
%====================================================================================================================(Slider)
function val = localGetSliderPositionFromValue(this, value)
%LOCALGETSLIDERPOSITIONFROMVALUE
res = this.Resolution;
switch this.Scale
    case 'logarithmic'
        val = round(res*this.invSliderMappingCoefficients*[log10(value);1]);
    case 'linear'
        val = round(res*this.invSliderMappingCoefficients*[value;1]);
end
end
function val = localGetValueFromSliderPosition(this, sliderpos)
%LOCALGETVALUEFROMSLIDERPOSITION
res = this.Resolution;
switch this.Scale
    case 'logarithmic'
        C = this.SliderMappingCoefficients;
        val = C(1)*C(2)^(sliderpos/res);
    case 'linear'
        val = this.SliderMappingCoefficients*[sliderpos/res;1];
end
end

%======================================================================================================================(Text)
function val = localGetTextFromValue(val)
%LOCALGETTEXTFROMVALUE
val = num2str(val, '%0.4g');
end
function val = localGetValueFromText(str, Pos)
%LOCALGETVALUEFROMTEXT
if isempty(str)
    val = [];
else
    try
        val = evalin('base', str);
        if ~isscalar(val) || ~isreal(val) || ~isnumeric(val) || ...
                hasInfNaN(val) || (Pos && val<=0)
            val = [];
        end
    catch
        val = [];
    end
end
end
