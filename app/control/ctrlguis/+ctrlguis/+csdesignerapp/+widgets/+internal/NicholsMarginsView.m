classdef NicholsMarginsView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    % MarginsView constructs and manages HG objects for gain and phase
    % margins
    properties (Access = private)
        Axes
        Line            % HG objects associated with margins
                        % Struct with fields:
                        % PhaDot, MagDot, PhaLine, MagLine, Text
        
        % Preference related properties
        MarginsVisible = true;
    end
    
    methods (Access = public)
        function this = NicholsMarginsView(Parent, Data, Axes)
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            this.Axes = Axes;
            
            constructLine(this);
            
            % Listener to change in axes limits
            % L = handle.listener(this.Axes,'PostLimitChanged',@adjustDisplay);
%             
%                L = [handle.listener(Editor.Axes,'PostLimitChanged',@LocalAdjustDisplay);...
%          handle.listener(Editor, Editor.findprop('FrequencyUnits'),...
%          'PropertyPostSet',@showmargin)];

            % L.CallbackTarget = this;
            % set(this.Line.MagDot,'UserData',L);
        end
        
        function update(this)
            Ax = getAxes(this.Axes);
            if strcmp(Ax.Visible, 'on') && this.MarginsVisible == true
                % Update margins when data changes
                Margins = getMargins(this.Data);
                redrawMargins(this,Margins);
                Style = this.Parent.LineStyle;
                % this.Line.PhaDot.MarkerFaceColor = Style.Color.Margin;
                % this.Line.PhaDot.MarkerEdgeColor = Style.Color.Margin;
                controllib.plot.internal.utils.setColorProperty(this.Line.PhaDot,...
                    ["MarkerFaceColor","MarkerEdgeColor"],Style.Color.Margin);
                % this.Line.MagDot.MarkerFaceColor = Style.Color.Margin;
                % this.Line.MagDot.MarkerEdgeColor = Style.Color.Margin;
                controllib.plot.internal.utils.setColorProperty(this.Line.MagDot,...
                    ["MarkerFaceColor","MarkerEdgeColor"],Style.Color.Margin);
                % this.Line.PhaLine.Color = Style.Color.Margin;
                % this.Line.MagLine.Color = Style.Color.Margin;
                controllib.plot.internal.utils.setColorProperty([this.Line.PhaLine,this.Line.MagLine],...
                    "Color",Style.Color.Margin);
            end
        end
        
        function refresh(this)
            if strcmp(this.Axes.Visible, 'on') && this.MarginsVisible == true
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
            fields = fieldnames(this.Line);
            for ct = 1:numel(fields)
                this.Line.(fields{ct}).Visible = bool;
            end
        end
        
        function bool = isMarginsVisible(this)
            b = strcmpi(this.Line.MagLine.Visible,'on') || ...
                strcmpi(this.Line.PhaLine.Visible,'on');
            if b
                bool = 'on';
            else
                bool = 'off';
            end
                
        end
        
        function HG = getHG(this)
            HG = [this.Line.PhaDot, this.Line.MagDot, this.Line.PhaLine, this.Line.MagLine, ...
                this.Line.Text];
        end
    end
    
    methods (Access = private)
        function constructLine(this)
            % Construct HG items associated with margins
            
            % Prefs
            %             Style = Editor.LineStyle;
            %             MarginColor = Style.Color.Margin;
            MarginColor = [0.8000 0.5000 0];
            % Create objects
            MarginObjects = struct('PhaDot',  [], ...
                'MagDot',  [], ...
                'PhaLine', [], ...
                'MagLine', [], ...
                'Text',    []);
            
            Ax = getAxes(this.Axes);
            
            % Graphics
            Zlevel = this.Parent.getZLevel('margin');
            MarginObjects.MagDot = line(0, 1, Zlevel, ...
                'Parent',  Ax, ...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'HitTest', 'off', ...
                'MarkerEdgeColor', MarginColor , ...
                'MarkerFaceColor', MarginColor , ...
                'Marker',       'o', ...
                'MarkerSize',   6, ...
                'HelpTopicKey', 'nicholsgainphasestems');
            
            MarginObjects.PhaDot = line(1, 0, Zlevel, ...
                'Parent',  Ax, ...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'HitTest', 'off', ...
                'MarkerEdgeColor', MarginColor , ...
                'MarkerFaceColor', MarginColor , ...
                'Marker',       'o', ...
                'MarkerSize',   6, ...
                'HelpTopicKey', 'nicholsgainphasestems');
            
            MarginObjects.MagLine = line([1 1], [NaN NaN], Zlevel(:,[1 1]), ...
                'Parent',  Ax, ...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'HitTest', 'off', ...
                'Color', MarginColor, ...
                'LineStyle', '-');
            
            % Horizontal line visible to X limit picker to always show
            % what 180 crossing the P.M. is relative to
            MarginObjects.PhaLine = line([NaN NaN], [1 1], Zlevel(:,[1 1]), ...
                'Parent',  Ax, ...
                'YLimInclude','off',...
                'XLimInclude','off',...
                'HitTest', 'off', ...
                'Color', MarginColor, ...
                'LineStyle', '-');
            
            AxesColor = get(Ax, 'Color');
            if strcmp(AxesColor, 'none'),
                AxesColor = get(get(Ax, 'Parent'), 'Color');
            end
            
            % Text
            Zlevel = this.Parent.getZLevel('margintext');
            % MarginObjects.Text = text(0, 0, Zlevel, '', ...
            %     'Parent',  Ax, ...
            %     'HitTest', 'off', ...
            %     'XLimInclude','off',...
            %     'YLimInclude','off',......
            %     'Interpreter', 'none', ...
            %     'Units',   'normalized', ...
            %     'Color',   (AxesColor == 0), ...
            %     'EdgeColor', AxesColor, ...
            %     'BackGroundColor', AxesColor, ...
            %     'HelpTopicKey', 'nicholsgainphasetext');
            MarginObjects.Text = text(1,0,Zlevel,'','parent',Ax, ...
                'HitTest','off',...
                'XLimInclude','off',...
                'YLimInclude','off',......
                'Interpreter','none',...
                'Units','normalized',...
                'HelpTopicKey','nicholsgainphasetext');
            
            this.Line = MarginObjects;
        end
        
        function redrawMargins(this, Margins)
            FreqUnits = this.Parent.Preferences.FrequencyUnits;
            FreqConvert = funitconv('rad/s',FreqUnits);
            Frequency = FreqConvert*this.Data.Frequency;
            PhaseUnits = char(this.Axes.PhaseUnit);
            Phase      = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));
            MagUnits   = 'dB';
            
            % Unit conversions
            % Gain and Phase Margins (convert to current units)
            Gm  = unitconv(Margins.Gm,  'abs', MagUnits);
            Pm  = unitconv(Margins.Pm,  'deg', PhaseUnits);
            Wcg = Margins.Wcg*funitconv('rad/s', FreqUnits);
            Wcp = Margins.Wcp*funitconv('rad/s', FreqUnits);
            
            % 180 degrees in current units;
            PhaseConvert = unitconv(1, 'deg', PhaseUnits);
            u180 = 180 * PhaseConvert;
            
            % Unit dependent entities
            Yo = unitconv(1, 'abs', MagUnits);
            if strcmpi(MagUnits, 'abs')
                MagUnitStr = '(abs)';
                Ydot = 1/Gm;
            else
                MagUnitStr = 'dB';
                Ydot = -Gm;
            end
            
            % Determine the gain line associated with the gain margin
            if isfinite(Gm) && isfinite(Wcg)
                Xg = u180 * round(utInterp1(Frequency(:), Phase(:), Wcg) / u180);
                % Gain margin data text
                Display = getString(message('Control:compDesignTask:lblGM',...
                    sprintf('%0.3g %s @ %0.3g %s',Gm, MagUnitStr, Wcg, FreqUnits)));
            else
                Xg = NaN; % trick to make it invisible
                Display = getString(message('Control:compDesignTask:lblGM',...
                    sprintf('Inf @ %0.3g', Wcg)));
            end
            
            % Determine the phase line associated with the phase margin (-180 modulo 360)
            if isfinite(Pm)
                Xp = u180 * round((utInterp1(Frequency(:), Phase(:), Wcp) - Pm) / u180);
                % Phase margin data text
                Display = sprintf('%s\n%s',Display, ...
                    getString(message('Control:compDesignTask:lblPM',...
                    sprintf('%0.3g %s @ %0.3g %s',Pm, PhaseUnits, Wcp, FreqUnits))));
            else
                Xp = NaN; % trick to make it invisible
                Display = sprintf('%s\n%s',Display,...
                    getString(message('Control:compDesignTask:lblPM',...
                    sprintf('Inf @ %0.3g',Wcp))));
            end
            
            if ~isnan(Margins.Stable)
                if Margins.Stable
                    Display = sprintf('%s\n%s', Display, ...
                        getString(message('Control:compDesignTask:strStableLoop')));
                else
                    Display = sprintf('%s\n%s', Display, ...
                        getString(message('Control:compDesignTask:strUnstableLoop')));
                end
            end
%             
%             if isUncertain(this.Data)
%                 Display = sprintf('%s\n%s', ...
%                     ctrlMsgUtils.message('Control:compDesignTask:strNominal'),Display);
%             end
            
            % Set margin-related attributes
            Px = [Xp+Pm Xp];  Gy = [Ydot Yo];
            set(this.Line.MagDot,  'Xdata',  Xg,      'Ydata',  Gy(1))   % mag dot marker
            set(this.Line.MagLine, 'Xdata', [Xg Xg],  'Ydata',  Gy)      % vertical line
            set(this.Line.PhaDot,  'Xdata',  Px(1),   'Ydata',  Yo)      % pha dot marker
            set(this.Line.PhaLine, 'Xdata',  Px,      'Ydata', [Yo Yo])  % horizontal line
            set(this.Line.Text,    'String', Display)                    % text
        end
        
        
    end

    methods (Hidden)
        function adjustDisplay(this,~)
            % Adjusts margin display when axis limits change
            
            % Adjust visibility and extents (in normal mode only)
            PlotAxes = getAxes(this.Axes);
            NormalRefresh = 1;
            Gain = getGain(this.Data);
            YData = mag2db(Gain * this.Data.Magnitude);
            XData = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));
%             FreqConvert = funitconv('rad/s',this.Axes.XUnits);
%             XData = FreqConvert*this.Data.Frequency;
            
            % if strcmp(Editor.MagVisible,'on')
            LocalRefresh(this.Line,PlotAxes,XData,YData,NormalRefresh);
            % end
            
        end
    end
end

%%%%%%%%%%%%%%%%%%%%
%%% LocalRefresh %%%
%%%%%%%%%%%%%%%%%%%%
function LocalRefresh(MarginObjects,Axes,Xdata,Ydata,NormalRefresh)
% Adjust position and visibility of margin objects when axis limits change

% % Quick exit
% if strcmp(Editor.EditMode,'off') || strcmp(Editor.MarginVisible,'off')
%    return
% end

% Get axis limits 
Xlims  = get(Axes, 'Xlim');
Ylims  = get(Axes, 'Ylim');

idx   = find(Xdata >= Xlims(1) & Xdata <= Xlims(2) & ...
   Ydata >= Ylims(1) & Ydata <= Ylims(2));
if ~isempty(idx) % protect against error when zooming in an empty area
   [~,minI] = min(Ydata(idx));
   minI = minI + idx(1) - 1;  % index of minimum visible Ydata point
end
Zlevel = get(MarginObjects.Text, 'Position');
Zlevel = Zlevel(3);
if isempty(idx) || Xdata(minI)<(Xlims(1)+Xlims(2))/2
   % Place it at the bottom right corner
   set(MarginObjects.Text, 'Position', [0.98 0.02 Zlevel], ...
      'VerticalAlignment', 'bottom', ...
      'HorizontalAlignment', 'right');
else
   % Place it at the bottom left corner
   set(MarginObjects.Text, 'Position', [0.02 0.02 Zlevel], ...
      'VerticalAlignment', 'bottom', ...
      'HorizontalAlignment', 'left');
end
end