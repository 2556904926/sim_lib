classdef BodeUncertain < handle
    % @BodeUncertain class definition
    
    %   Copyright 1986-2014 The MathWorks, Inc.
    properties (SetObservable)
        Parent
        
        %% States
        Visible
        UncertainType = 'Systems'; % Bounds, Systems
        ZLevel = -5.5;
        
                
        %% Data
        Frequency  % size n rad/s
        Magnitude  % size n x m  abs
        Phase      % size n x m  deg
        
        %
        
        %% Patch Info
        MagPatch
        PhasePatch
        FaceColor = [0.9804 .9*0.9804 0.8235];
        MagUpperLine
        MagLowerLine
        
        %% Lines Info
        MagLines
        PhaseLines
        LineColor = [0.9804 .9*0.9804 0.8235];
    end
    
    methods
        %%
        function this = BodeUncertain(Parent)
            % Constructor
            this.Parent = Parent;
            
        end
        
        function set.UncertainType(this,value)
            this.UncertainType = value;
            draw(this);
        end
        
        function set.Visible(this,value)
            this.Visible = value;
            draw(this);
        end
        
        %%
        function setData(this,mag,phase,w)
            this.Frequency = w(:);
            this.Magnitude = mag;
            this.Phase = phase;
            this.draw;
        end
        
        %%
        function setZLevel(this,ZLevel)
            this.ZLevel = ZLevel;
        end
        
        %%
        function draw(this)
            if isempty(this.MagPatch)
                BodeAxes = this.Parent.Axes.getAxes;
                % Magnitude Patch
                this.MagPatch = patch(nan,nan,this.ZLevel,Parent=BodeAxes(1),PickableParts='none',...
                    FaceAlpha=0.3,EdgeAlpha=0.3);
                controllib.plot.internal.utils.setColorProperty(this.MagPatch,["FaceColor","EdgeColor"],this.FaceColor);
                % Phase Patch
                this.PhasePatch = patch(nan,nan,this.ZLevel,Parent=BodeAxes(2),PickableParts='none',...
                    FaceAlpha=0.3,EdgeAlpha=0.3);
                controllib.plot.internal.utils.setColorProperty(this.PhasePatch,["FaceColor","EdgeColor"],this.FaceColor);
                % Magnitude Lines
                this.MagLines = line(nan,nan,this.ZLevel,Parent=BodeAxes(1),XLimInclude='off',PickableParts='none');
                controllib.plot.internal.utils.setColorProperty(this.MagLines,"Color",this.LineColor);
                % Phase Lines
                this.PhaseLines = line(nan,nan,this.ZLevel,Parent=BodeAxes(2),XLimInclude='off',PickableParts='none');
                controllib.plot.internal.utils.setColorProperty(this.PhaseLines,"Color",this.LineColor);
            end
            
            
            if isVisible(this)
                if strcmpi(this.UncertainType,'Bounds')
                    set(this.MagLines,'visible','off')
                    set(this.PhaseLines,'visible','off')
                    set(this.MagPatch,'visible','on')
                    set(this.PhasePatch,'visible','on')
                    % what about nans or infs in response?
                    frequency = this.Frequency;
                    MagUpper = max(this.Magnitude,[],2);
                    MagLower = min(this.Magnitude,[],2);
                    PhaseUpper = max(this.Phase,[],2);
                    PhaseLower = min(this.Phase,[],2);
                    
                    % Use the editors focus for drawing
                    XFocus = getfocus(this.Parent);
                    if isempty(XFocus)
                        InFocus = 1:length(this.Frequency);
                    else
                        InFocus = find(this.Frequency >= XFocus(1) & this.Frequency <= XFocus(2));
                    end
                    
                    frequency = frequency(InFocus)*funitconv('rad/s',char(this.Parent.Axes.FrequencyUnit));
                    MagUpper = MagUpper(InFocus);
                    MagLower = MagLower(InFocus);
                    PhaseUpper = PhaseUpper(InFocus);
                    PhaseLower = PhaseLower(InFocus);
                    
                    
                    FreqVect = [frequency;frequency(end:-1:1)];
                    zdata = this.ZLevel * ones(size(FreqVect));
                    % Dont forget to convert units
                    set(this.MagPatch,'YData', unitconv([MagUpper;MagLower(end:-1:1)],'abs',char(this.Parent.Axes.MagnitudeUnit)),...
                        'XData', FreqVect,'ZData',zdata);
                    set(this.PhasePatch,'YData', unitconv([PhaseUpper;PhaseLower(end:-1:1)],'deg',char(this.Parent.Axes.PhaseUnit)),...
                        'XData', FreqVect,'ZData',zdata)
                else
                    set(this.MagLines,'visible','on')
                    set(this.PhaseLines,'visible','on')
                    set(this.MagPatch,'visible','off')
                    set(this.PhasePatch,'visible','off')
                    
                    % Use the editors focus for drawing
                    XFocus = getfocus(this.Parent);
                    if isempty(XFocus)
                        InFocus = 1:length(this.Frequency);
                    else
                        InFocus = find(this.Frequency >= XFocus(1) & this.Frequency <= XFocus(2));
                    end
                    frequency = this.Frequency(InFocus)*funitconv('rad/s',char(this.Parent.Axes.FrequencyUnit));
                    Magdata = [];
                    Phasedata = [];
                    Freqdata = [];
                    for ct = 1:size(this.Magnitude,2)
                        Magdata = [Magdata; this.Magnitude(InFocus,ct);NaN]; %#ok<AGROW>
                        Phasedata = [Phasedata; this.Phase(InFocus,ct);NaN]; %#ok<AGROW>
                        Freqdata = [Freqdata; frequency;NaN]; %#ok<AGROW>
                    end
                    zdata = this.ZLevel * ones(size(Freqdata));
                    set(this.MagLines,'YData', unitconv(Magdata,'abs',char(this.Parent.Axes.MagnitudeUnit)),...
                        'XData', Freqdata,'ZData', zdata);
                    set(this.PhaseLines,'YData', unitconv(Phasedata,'deg',char(this.Parent.Axes.PhaseUnit)),...
                        'XData', Freqdata,'ZData', zdata);
                end
            else
                set(this.MagLines,'visible','off')
                set(this.PhaseLines,'visible','off')
                set(this.MagPatch,'visible','off')
                set(this.PhasePatch,'visible','off')
            end
        end
            
        function b = isVisible(this,Type)
            if strcmpi(this.Visible,'on')
                if nargin == 1
                    b = true;
                else
                    if strcmpi(Type,this.UncertainType)
                        b = true;
                    else
                        b = false;
                    end
                end
            else
                b = false;
            end
        end
        
        function setColor(this,Color)
            if isnumeric(Color)
                % Convert numeric color
                hsvcolor = rgb2hsv(Color);
                Color = hsv2rgb(hsvcolor.*[1,.2,1]);
                this.FaceColor = Color;
                this.LineColor = Color;
            else
                % Convert semantic color
                this.FaceColor = Color;
                this.LineColor = controllib.plot.internal.utils.convertSemanticColor(Color,"tertiary");
            end

            if ~isempty(this.MagPatch)
                % Magnitude patch
                controllib.plot.internal.utils.setColorProperty(this.MagPatch,...
                    ["EdgeColor","FaceColor"],this.FaceColor);
                this.MagPatch.EdgeAlpha = 0.3;
                this.MagPatch.FaceAlpha = 0.3;
                
                % Phase patch
                controllib.plot.internal.utils.setColorProperty(this.PhasePatch,...
                    ["EdgeColor","FaceColor"],this.FaceColor);
                this.PhasePatch.EdgeAlpha = 0.3;
                this.PhasePatch.FaceAlpha = 0.3;
            end
            if ~isempty(this.MagLines)
                controllib.plot.internal.utils.setColorProperty(this.MagLines,...
                    "Color",this.LineColor);
                controllib.plot.internal.utils.setColorProperty(this.PhaseLines,...
                    "Color",this.LineColor);
            end
            
            
        end
        
        
    end
    
    
    methods (Access = private)
        
        %%
        
        
    end
end
