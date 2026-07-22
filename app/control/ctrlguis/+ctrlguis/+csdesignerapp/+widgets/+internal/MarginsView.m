classdef MarginsView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    % MarginsView constructs and manages HG objects for gain and phase
    % margins
    properties (Access = private)
        Axes
        Line            % HG objects associated with margins
                        % Struct with fields:
                        % GainMargin -> hLine, vLine, Dot, Text
                        % PhaseMargin -> hLine, vLine, Dot, Text
        MagPhase = 1;   % Margin on Mag Ax or Phase Ax
        
        % Preference related properties
        MarginsVisible = true;
    end
    
    methods (Access = public)
        function this = MarginsView(Parent, Data, Axes, PhaseFlag)
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            if nargin == 4
                this.MagPhase = 2;
            end
            
            this.Axes = Axes;
            
            constructLine(this, 'GainMargin');
            constructLine(this, 'PhaseMargin');
            
            % Listener to change in axes limits
            % L = handle.listener(this.Axes,'PostLimitChanged',@adjustDisplay);
            % L.CallbackTarget = this;
            % set(this.Line.GainMargin.Dot,'UserData',L);
        end
        
        function update(this)
            Ax = getAxes(this.Axes);
            if strcmp(Ax(this.MagPhase).Visible, 'on') && this.MarginsVisible == true
                % Update margins when data changes
                Margins = getMargins(this.Data);
                redrawMargins(this,Margins);
                
                Style = this.Parent.LineStyle;
                
                controllib.plot.internal.utils.setColorProperty(...
                    this.Line.GainMargin.Dot,["MarkerFaceColor","MarkerEdgeColor"],Style.Color.Margin);
                controllib.plot.internal.utils.setColorProperty(...
                    [this.Line.GainMargin.hLine,this.Line.GainMargin.vLine],"Color",Style.Color.Margin);
                
                controllib.plot.internal.utils.setColorProperty(...
                    this.Line.PhaseMargin.Dot,["MarkerFaceColor","MarkerEdgeColor"],Style.Color.Margin);
                controllib.plot.internal.utils.setColorProperty(...
                    [this.Line.PhaseMargin.hLine,this.Line.PhaseMargin.vLine],"Color",Style.Color.Margin);
            end
        end
        
        function refresh(this)
            if strcmp(this.Axes(this.MagPhase).Visible, 'on') && this.MarginsVisible == true
                % Refresh margins during drag
                % Quick exit if margins off
                %             if strcmp(this.MarginVisible,'on'),
                % Interpolate stability margins
                C = this.Data.EditedBlock;
                Magnitude = this.Data.Magnitude * getZPKGain(C,'mag');
                [Gm,Pm,Wcg,Wcp] = imargin(Magnitude(:),this.Data.Phase(:),this.Data.Frequency(:));
                
                % Update display
                redrawMargins(this,struct('Gm',Gm,'Pm',Pm,'Wcg',Wcg,'Wcp',Wcp,'Stable',NaN));
            end
        end
        
        function toggleVisibility(this,bool)
            fields = fieldnames(this.Line.GainMargin);
            for ct = 1:numel(fields)
                this.Line.GainMargin.(fields{ct}).Visible = bool;
                this.Line.PhaseMargin.(fields{ct}).Visible = bool;
            end
        end
        
        function bool = isMarginsVisible(this)
            bool = this.Line.GainMargin.vLine.Visible;
        end
        
        function HG = getHG(this)
            HG = [this.Line.GainMargin.vLine, this.Line.GainMargin.hLine, this.Line.GainMargin.Dot, this.Line.GainMargin.Text; ...
                this.Line.PhaseMargin.vLine, this.Line.PhaseMargin.hLine, this.Line.PhaseMargin.Dot, this.Line.PhaseMargin.Text];
        end
    end
    
    methods (Access = private)
        function constructLine(this, GP)
            % Construct HG items associated with margins
            
            % Prefs
            Style = this.Parent.LineStyle;
            MarginColor = Style.Color.Margin;
            % Create objects
            MarginObjects = ...
                struct('Dot',[],'hLine',[],'vLine',[],'Text',[]);
            Ax = getAxes(this.Axes);
            if strcmpi(GP, 'GainMargin')
                Ax = Ax(1);
            else
                Ax = Ax(2);
            end
            % Graphics
            Zlevel = this.Parent.getZLevel('margin');
            MarginObjects.Dot = line(1,1,Zlevel,'Parent',Ax,...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'HitTest','off',...
                'Marker','o','MarkerSize',6,...
                'HelpTopicKey','gainphasemargin');
            controllib.plot.internal.utils.setColorProperty(MarginObjects.Dot,...
                ["MarkerEdgeColor","MarkerFaceColor"],MarginColor);
            
            MarginObjects.hLine = line([.1 10],[NaN NaN],Zlevel(:,[1 1]),...
                'Parent',Ax,'HitTest','off','XLimInclude','off','YLimInclude','off',...
                'LineStyle','-.');
            controllib.plot.internal.utils.setColorProperty(MarginObjects.hLine,...
                "Color",MarginColor);
            
            MarginObjects.vLine = line([1 1],[NaN NaN],Zlevel(:,[1 1]),'parent',Ax, ...
                'HitTest','off','LineStyle','-');
            controllib.plot.internal.utils.setColorProperty(MarginObjects.vLine,...
                "Color",MarginColor);
            
            % Text
            Zlevel = this.Parent.getZLevel('margintext');
            % MarginObjects.Text = text(1,0,Zlevel,'','parent',Ax, ...
            %     'HitTest','off',...
            %     'XLimInclude','off',...
            %     'YLimInclude','off',......
            %     'Interpreter','none',...
            %     'Units','normalized',...
            %     'Color',(AxesColor==0),...
            %     'EdgeColor', AxesColor, ...
            %     'BackGroundColor', AxesColor, ...
            %     'HelpTopicKey','gainphasemargin');
            MarginObjects.Text = text(1,0,Zlevel,'','parent',Ax, ...
                'HitTest','off',...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'Interpreter','none',...
                'Units','normalized',...
                'HelpTopicKey','gainphasemargin');
            
            this.Line.(GP) = MarginObjects;
        end
        
        function redrawMargins(this, Margins)
            FreqUnits = char(this.Axes.FrequencyUnit);
            FreqConvert = funitconv('rad/s',FreqUnits);
            Frequency = FreqConvert*this.Data.Frequency;
            
            MagUnits = char(this.Axes.MagnitudeUnit);
            % Unit conversions
            Wcg = Margins.Wcg*funitconv('rad/s',FreqUnits);
            Gm = Margins.Gm;
            isStable = Margins.Stable;
            % Margin data text
            if isfinite(Gm),
                % Finite value
                MagUnitStr = MagUnits;
                if strcmpi(MagUnits,'abs')
                    MagUnitStr = sprintf('(%s)',MagUnits);
                end
                Display = sprintf('%s\n%s', ...
                    getString(message('Control:compDesignTask:lblGM', ...
                    sprintf('%0.3g %s',unitconv(Gm,'abs',MagUnits),MagUnitStr))), ...
                    getString(message('Control:compDesignTask:lblFreq', ...
                    sprintf('%0.3g %s', Wcg,FreqUnits))));
            else
                Display = sprintf('%s\n%s', ...
                    getString(message('Control:compDesignTask:lblGM', ...
                    sprintf('%s','inf'))), ...
                    getString(message('Control:compDesignTask:lblFreq', ...
                    sprintf('%0.3g', Wcg))));
            end
            if ~isnan(isStable)
                if isStable,
                    Display = sprintf('%s\n%s',Display, ...
                        getString(message('Control:compDesignTask:strStableLoop')));
                else
                    Display = sprintf('%s\n%s',Display, ...
                        getString(message('Control:compDesignTask:strUnstableLoop')));
                end
            end
            
            if this.Data.isUncertain
                Display = sprintf('%s\n%s',...
                    getString(message('Control:compDesignTask:strNominal')),Display);
            end
            
            
            % Horizontal 0dB gain line
            if isfinite(Gm) && (Wcg>=Frequency(1) && Wcg<=Frequency(end))
                Yg = unitconv(1,'abs',MagUnits);
                Ydot = unitconv(1/Gm,'abs',MagUnits);
            else
                Wcg = NaN;  % Wcg=0 gets mapped to -Inf in log scale
                Yg = NaN;   % trick to make it invisible
                Ydot = NaN;
            end
            
            % Set margin-related attributes
            set(this.Line.GainMargin.Dot,'Xdata',Wcg,'Ydata',Ydot)               % dot marker
            set(this.Line.GainMargin.vLine,'Xdata',[Wcg Wcg],'Ydata',[Ydot Yg])  % vertical line
            set(this.Line.GainMargin.hLine,'Ydata',[Yg Yg])                      % horizontal line
            set(this.Line.GainMargin.Text,'String',Display)                      % text
            
            PhaseUnits = char(this.Axes.PhaseUnit);
            
            % Unit conversions
            Wcp = Margins.Wcp*funitconv('rad/s',FreqUnits);
            
            PhaseConvert = unitconv(1,'deg',PhaseUnits);
            Pm = Margins.Pm * PhaseConvert;
            
            
            % Margin data text
            if isfinite(Pm),
                % Finite value
                Display = sprintf('%s\n%s',...
                    getString(message('Control:compDesignTask:lblPM', ...
                    sprintf('%0.3g %s',Pm,PhaseUnits))), ...
                    getString(message('Control:compDesignTask:lblFreq', ...
                    sprintf('%0.3g %s', Wcp,FreqUnits))));
            else
                Display = sprintf('%s\n%s', ...
                    getString(message('Control:compDesignTask:lblPM', ...
                    sprintf('%s','inf'))), ...
                    getString(message('Control:compDesignTask:lblFreq', ...
                    sprintf('%0.3g', Wcp))));
            end
            
            % Determine the phase line associated with the phase margin (-180 modulo 360)
            if isfinite(Pm) && (Wcp>=Frequency(1) && Wcp<=Frequency(end))
                Phase =  unitconv(this.Data.Phase,'deg',char(this.Axes.PhaseUnit));
                u180 = 180 * PhaseConvert;
                Yp = u180 * round((utInterp1(Frequency(:),Phase(:),Wcp)-Pm)/u180);
            else
                Wcp = NaN;  % Wcp=0 gets mapped to -Inf in log scale
                Yp = NaN;
            end
            
            if this.Data.isUncertain
                Display = sprintf('%s\n%s',...
                    ctrlMsgUtils.message('Control:compDesignTask:strNominal'),Display);
            end
            
            % Set margin-related attributes
            set(this.Line.PhaseMargin.Dot,'Xdata',Wcp,'Ydata',Yp+Pm)                % dot marker
            set(this.Line.PhaseMargin.vLine,'Xdata',[Wcp Wcp],'Ydata',[Yp Yp+Pm])   % vertical line
            set(this.Line.PhaseMargin.hLine,'Ydata',[Yp Yp])                        % horizontal line
            set(this.Line.PhaseMargin.Text,'String',Display)
            
            % Limit tweaking
            if isfinite(Wcp) && (Wcp>this.Data.FreqFocus(1)/10 && Wcp<10*this.Data.FreqFocus(2))
                % Make vertical phase line visible to limit picker
                set(this.Line.PhaseMargin.vLine,'XLimInclude','on','YLimInclude','on')
            else
                set(this.Line.PhaseMargin.vLine,'XLimInclude','off','YLimInclude','off')
            end
            
        end
    end

    methods (Hidden)
        function adjustDisplay(this,~)
            % Adjusts margin display when axis limits change
            
            % Adjust visibility and extents (in normal mode only)
            PlotAxes = getAxes(this.Axes);
            NormalRefresh = 1;
            Gain = getGain(this.Data);
            if this.MagPhase == 1
                YData = unitconv(Gain * this.Data.Magnitude','abs',char(this.Axes.MagnitudeUnit));
            else
                YData = unitconv(this.Data.Phase,'deg',char(this.Axes.PhaseUnit));
            end
            
            FreqConvert = funitconv('rad/s',char(this.Axes.FrequencyUnit));
            XData = FreqConvert*this.Data.Frequency;
            
            % if strcmp(Editor.MagVisible,'on')
            LocalRefresh(this.Line.GainMargin,PlotAxes(1),XData,YData,NormalRefresh);
            % end
            % if strcmp(Editor.PhaseVisible,'on')
            LocalRefresh(this.Line.PhaseMargin,PlotAxes(2),XData,YData,NormalRefresh)
            % end
        end
    end
end

%%%%%%%%%%%%%%%%%%%%
%%% LocalRefresh %%%
%%%%%%%%%%%%%%%%%%%%
function LocalRefresh(MarginObjects,BodeAxes,Xdata,Ydata,NormalRefresh)
% Adjust position and visibility of margin objects when axis limits change
% BODEAXES: mag or phase axes
% BODECURVE: mag or phase curve

% Get axis limits
Xlims = get(BodeAxes,'Xlim');
Ylims = get(BodeAxes,'Ylim');

% Visibility of horizontal line
set(MarginObjects.hLine,'Xdata',Xlims)
Wc = get(MarginObjects.Dot,'Xdata');
if ~isfinite(Wc) || Wc<Xlims(1) || Wc>Xlims(2)
    set(MarginObjects.hLine,'YData',[NaN NaN])  % hide horizontal line
end

% Position text (based on Y coordinate of left-most visible point)
if NormalRefresh
    Zlevel = get(MarginObjects.Text, 'Position');
    Zlevel = Zlevel(3);
    
    isLinearY = strcmp(get(BodeAxes,'YScale'),'linear');
    idx = find(Xdata >= Xlims(1));
    if ~isempty(idx) % protect against error when zooming in an empty area
        if ((isLinearY && Ydata(idx(1)) >= (Ylims(1)+Ylims(2))/2) || ...
                (~isLinearY && Ydata(idx(1)) >= sqrt(Ylims(1)*Ylims(2))))
            % Place it at the bottom left corner
            set(MarginObjects.Text,'Position',[.02 .04 Zlevel], ...
                'VerticalAlignment','bottom')
        else
            set(MarginObjects.Text,'Position',[.02 .97 Zlevel], ...
                'VerticalAlignment','top')
        end
    end
end
end