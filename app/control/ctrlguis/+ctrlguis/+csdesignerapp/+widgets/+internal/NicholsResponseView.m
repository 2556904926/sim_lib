classdef NicholsResponseView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    properties (Access = private)
        Axes                 % ctrluis.AxesPair object
        FixedPZ              % System poles and zeros (HG objects)
                
        NyqLine              % Nyquist line (HG object)
        
        Line                 % Response Line (HG object)
        LineShadow           % Shadow line used for limit picking (HG object)
        
        GainListener         % Listener needed during drag
        AbsLinMag            % Needed during drag
        
        InitMag
        InitFreq
        Phase
        Frequency
    end
    
    methods (Access = public)
        function this = NicholsResponseView(Parent, Data, Axes)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            % Construct response line
            constructLine(this);
        end
        
        function HG = getHG(this)
            HG = [this.Line; this.FixedPZ];
        end
        
        function update(this)
            % Called during Parent Bodethis's update
            %             Ax = getAxes(this.Axes);
            %             if strcmp(Ax(this.MagPhase).Visible, 'on')
            % Update only if axes is visible
            if this.ShowSystemPZ
                updateFixedPZ(this);
            end
            
            refresh(this);
            
            %                 Ts = this.Data.Ts;
            %                 FreqConvert = funitconv('rad/s',this.Axes.XUnits);
            %                 if Ts
            %                     NyqFreq = FreqConvert * pi/Ts;
            %                 else
            %                     NyqFreq = NaN;
            %                 end
            %
            %                 % setnyqline expets NyqFreq to be in axes's XUnits
            %                 setnyqline(this,NyqFreq);
            %             end
            Style = this.Parent.LineStyle;
            controllib.plot.internal.utils.setColorProperty(this.Line,"Color",Style.Color.Response);
        end
        
        function refresh(this)
            % Called during Parent Bodethis's refresh - That is, when
            % something else other than the response view is being dragged.
            
            % Updates YData
            Gain = getGain(this.Data);
            % Set the YData in current YUnits of Axes(1)
            MagData = mag2db(Gain * this.Data.Magnitude);
            PhaseData = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));

            ZData = this.Parent.getZLevel('curve',[length(this.Data.Frequency) 1]);
            
            set(this.Line, 'XData', PhaseData, 'YData', MagData, 'ZData', ZData);
            
            % update fixed pz
            this.interpxy;
            
            if this.Parent.isMultiModelVisible
                this.Parent.UncertainBounds.setData(Gain*this.Data.UncertainData.Magnitude,...
                    this.Data.UncertainData.Phase,this.Data.UncertainData.Frequency);
            end
            
            % Update shadow
            XFocus = getfocus(this.Parent);
            InFocus = find(this.Data.Frequency >= XFocus(1) & this.Data.Frequency <= XFocus(2));
            
            set(this.LineShadow,'XData',PhaseData(InFocus),'YData',MagData(InFocus));
        end
    end
    
    methods (Access = public)
        function start(this)
            
            switch this.Parent.EditMode
                case 'idle'
                    setRefreshMode(this, 'quick');
                    if this.Data.GainTunable
                        enableDataListeners(this.Data, false);
                        setEditedBlock(this.Data,this.Data.GainTargetBlock);
                        refresh(this.Parent,'start',this);
                        Gain = getGain(this.Data);
                        Magnitude  = mag2db(this.Data.Magnitude * Gain);
                        this.Phase  = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));
                        this.Frequency = this.Data.Frequency*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
                        
                        % Store current pointer to restore at end
                        PlotAxes = getAxes(this.Axes); %#ok<*PROP>
                        moveptr(PlotAxes,'i');
                        
                        % Initial mouse position
                        CP = get(PlotAxes, 'CurrentPoint');
                        X = max(min(this.Phase), min(CP(1,1), max(this.Phase)));
                        Y = CP(1,2);
                        
                        % Initial freq. at the point closest to the mouse position, in current units.
                        this.InitFreq = this.project(X, Y, this.Phase, Magnitude, this.Frequency);
                        this.InitMag  = 20*log10(this.interpmag(this.Frequency, this.Data.Magnitude, this.InitFreq));
                        
                        % add listener to gain changed
                        this.GainListener = addlistener(this.Data.EditedBlock, 'GainChanged', @(es,ed)refreshGain(this));
                        % Update pointer
                        setptr(getHGParent(this.Parent),'closedhand');
                        
                        % Start transaction
                        this.Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction(getString(message('Control:compDesignTask:strEditGain')));
                        
                        % Add new pole/zero group to database
                        CurrentGain = getGain(this.Data);
                        this.Transaction.UndoFcn = {@setGain this CurrentGain};
                        
                        this.Parent.EventManager.postActionStatus('off',...
                            sprintf('%s. %s.', ...
                            getString(message('Control:compDesignTask:msgNicholsEditGain')),...
                            this.pointerlocation))
                    end
                case 'addpz'
                    PlotAxes = getAxes(this.Axes); %#ok<*PROP>
                    setRefreshMode(this,'normal');
                    addPZ(this.Parent, PlotAxes);
            end
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function move(this)
            switch this.Parent.EditMode
                case 'idle'
                    if this.Data.GainTunable
                        PlotAxes = getAxes(this.Axes);
                        CP = get(PlotAxes, 'CurrentPoint');
                        X = max(min(this.Phase), min(CP(1,1), max(this.Phase))); % Range of X motion
                        Y = CP(1,2);
                        
                        % Interpolate mouse X-position using phase data
                        [index, alpha] = interppha(this, this.Phase, X);
                        
                        % Get the frequency data
                        Freq = alpha .* this.Frequency(index+1) + (1-alpha) .* this.Frequency(index);
                        [~,I] = min(abs(Freq - this.InitFreq));
                        
                        % Get new gain value (interpolate in plot units to limit distortions)
                        NewMag = 20*log10(this.interpmag(this.Frequency, this.Data.Magnitude, Freq(I)));
                        Jump = 10; % Limit maximum jump/change in dB in a single step
                        if abs(NewMag-this.InitMag) > Jump;
                            this.InitMag = this.InitMag + Jump * sign(NewMag-this.InitMag);
                            NewGain = 10.^((Y-this.InitMag)/20);
                        else
                            NewGain = 10.^((Y-NewMag)/20);
                        end
                        
                        % Update loop data (triggers plot update via listeners by refreshgain)
                        setGain(this.Data,NewGain,'mag');
                        
                        % Adjust Y limits to keep mouse cursor in focus
                        AutoY = strcmp(this.Axes.YLimitsMode{1},'auto');
                        if AutoY
                            MovePtr = this.reframe(PlotAxes,'y',[],Y);
                            if MovePtr
                                % Reposition mouse pointer
                                moveptr(PlotAxes,'move',X,Y);
                            end
                        end
                        
                        % Update status
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s. %s.', ...
                            getString(message('Control:compDesignTask:msgNicholsEditGain')),...
                            this.pointerlocation))
                        refresh(this.Parent,'move',this);
                        notifyValueChanged(this.Data.EditedBlock)
                    end
            end
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            switch this.Parent.EditMode
                case 'idle'
                    if this.Data.GainTunable
                        enableDataListeners(this.Data, true);
                        setptr(getHGParent(this.Parent),'hand');
                        delete(this.GainListener);
                        this.GainListener = [];
                        update(this.Parent);
                        CurrentGain = getGain(this.Data);
                        this.Transaction.RedoFcn = {@setGain this CurrentGain};
                        this.Parent.EventManager.record(this.Transaction);
                        % Update status and command history
                        Str = getString(message('Control:compDesignTask:msgLoopGainChangedToValue', ...
                            sprintf('%0.3g',this.Data.EditedBlock.getFormattedGain)));
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s. %s',Str, ...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                    end
                case 'addpz'
                    setptr(getHGParent(this.Parent),'hand');
                    %                     update(this.Parent);
            end
            
            % this.Axes.send('ViewChanged');
        end
        
        function [HoverCursor, Status] = hover(this, varargin)
            Status = '';
            HoverCursor = 'Arrow';
            if strcmpi(this.Parent.EditMode, 'idle')
                if this.Data.GainTunable
                    HoverCursor = 'hand';
                    Status = sprintf('%s. %s', get(this.Line,'Tag'), ...
                        getString(message('Control:compDesignTask:msgClickCurveToEditGain',this.Data.EditedBlock.Name)));
                else
                    HoverCursor = 'arrow';
                    Status = sprintf('%s %s', get(this.Line, 'Tag'), ...
                        getString(message('Control:compDesignTask:msgGainNotEditable')));
                end
            elseif strcmpi(this.Parent.EditMode, 'addpz')
                switch this.Parent.EditModeData.Group
                    case {'Real','Complex'}
                        HoverCursor = sprintf('add%s',lower(this.Parent.EditModeData.Root));
                        if strcmpi(this.Parent.EditModeData.Root,'pole')
                            Status = getString(message('Control:compDesignTask:msgLeftClickToAddPole'));
                        else
                            Status = getString(message('Control:compDesignTask:msgLeftClickToAddZero'));
                        end
                    case 'Lead'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddLead'));
                    case 'Lag'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddLag'));
                    case 'Notch'
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddNotch'));
                    otherwise
                        HoverCursor = 'addpole';  % default
                        Status = getString(message('Control:compDesignTask:msgLeftClickToAddPZ'));
                end
            end
        end
    end
    
    methods (Access = private)
        function constructLine(this)
            PlotAxes = getAxes(this.Axes);
            Style = this.Parent.LineStyle;
            
            Zdata = this.Parent.getZLevel('curve', [length(this.Data.Phase) 1]);
            this.Line = line(NaN, NaN, NaN, ...
                'Parent', PlotAxes, ...
                'XlimInclude','off',...
                'YlimInclude','off',...
                'Tag', getString(message('Control:compDesignTask:strOpenLoopNicholsPlot')), ...
                'HelpTopicKey', 'sisonicholsplot');
            controllib.plot.internal.utils.setColorProperty(this.Line,"Color",Style.Color.Response);
            setappdata(this.Line, 'Widget', this);
            
            this.LineShadow = line(NaN,NaN,...
                'Parent',PlotAxes, ...
                'LineStyle', 'none', ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off');
        end
        
        function setGain(this, Gain)
            this.Data.setGain(Gain);
        end
        
        function refreshGain(this)
            Gain = getGain(this.Data);
            % Set YData in Axes(1)'s YUnits (interpy expects YData in
            % Axes(1)'s YUnits)
            YData = mag2db(this.Data.Magnitude * Gain);
            set(this.Line, 'YData', YData);
            interpxy(this);
            if this.Parent.isMultiModelVisible
                this.Parent.UncertainBounds.setData(Gain*this.Data.UncertainData.Magnitude,...
                    this.Data.UncertainData.Phase,this.Data.UncertainData.Frequency);
            end
        end
        
        function updateFixedPZ(this)
            Style = this.Parent.LineStyle;
            if ~isempty(this.FixedPZ)
                for ct = 1:numel(this.FixedPZ)
                    delete(this.FixedPZ(ct));
                end
                this.FixedPZ = [];
            end
            
            PlotAxes = getAxes(this.Axes);
            
            [FixedZeros,FixedPoles] = getFixedPZ(this.Data);
            
            % Fixed pole/zero's XData to be set in current axes units
            FreqConvert = funitconv('rad/s',this.Parent.Preferences.FrequencyUnits);
            
            Ts = this.Data.Ts;
            if Ts
                NyqFreq = FreqConvert * pi/Ts;
            else
                NyqFreq = NaN;
            end
            
            Zlevel = this.Parent.getZLevel('system');
                        
            % System zeros (discard conjugates of imaginary zeros)
            FixedZeros = [FixedZeros(~imag(FixedZeros), :) ; ...
                FixedZeros(imag(FixedZeros) > 0, :)];
            FreqZ = damp(FixedZeros, Ts); % in rad/sec
            MagPhaZ = [];
            
            % Discard roots whose CT frequency exceeds pi/Ts
            if Ts,
                idx = find(FreqZ <= NyqFreq);
                FixedZeros = FixedZeros(idx);
                FreqZ = FreqZ(idx);
            end
            
            % Line structure for zeros
            Zlevel = this.Parent.getZLevel('system');
            for ct = length(FixedZeros):-1:1
                MagPhaZ(ct,1) = line(NaN, NaN, Zlevel, ...
                    'Parent', PlotAxes, ...
                    'XlimInclude','off',...
                    'YlimInclude','off',...
                    'UserData', FreqZ(ct), ...
                    'Visible', 'on',...
                    'LineStyle', 'none', ...
                    'Marker', 'o', ...
                    'MarkerSize', 5, ...
                    'HelpTopicKey', 'nicholssystemzero', ...
                    'HitTest','off');
                controllib.plot.internal.utils.setColorProperty(MagPhaZ(ct,1),...
                    "Color",Style.Color.System);
                %                     'UIContextMenu', UIC, ...
            end
            
            % Highlight imaginary zeros
            imfz = find(imag(FixedZeros) > 0);
            set(MagPhaZ(imfz, :), 'LineWidth', 2)
            this.FixedPZ = [this.FixedPZ; MagPhaZ];
            
            % System poles (discard conjugates of imaginary poles)
            FixedPoles = [FixedPoles(~imag(FixedPoles), :) ; ...
                FixedPoles(imag(FixedPoles) > 0, :)];
            FreqP = damp(FixedPoles, Ts);  % in rad/sec
            MagPhaP = [];
            
            % Discard roots whose CT frequency exceeds pi/Ts
            if Ts,
                idx = find(FreqP <= NyqFreq);
                FixedPoles = FixedPoles(idx);
                FreqP = FreqP(idx);
            end
            
            % Line structure for poles
            for ct = length(FixedPoles):-1:1
                MagPhaP(ct,1) = line(NaN, NaN, Zlevel, ...
                    'Parent', PlotAxes, ...
                    'XlimInclude','off',...
                    'YlimInclude','off',...
                    'UserData', FreqP(ct), ...
                    'LineStyle', 'none', ...
                    'Marker', 'x', ...
                    'MarkerSize', 6, ...
                    'HelpTopicKey', 'nicholssystempole', ...
                    'HitTest','off');
                controllib.plot.internal.utils.setColorProperty(MagPhaP(ct,1),...
                    "Color",Style.Color.System);
            end
            
            % Highlight imaginary poles
            imfp = find(imag(FixedPoles) > 0);
            set(MagPhaP(imfp, :), 'LineWidth', 2);
            
            this.FixedPZ = [this.FixedPZ; MagPhaP];
            
            this.interpxy;
        end
        
        function setnyqline(this,NyqFreq)
            % SETNYQLINE  Positions Nyquist line in Bode Diagrams.
            % Expects NyqFreq in Axes's XUnits
            
            if isfinite(NyqFreq)
                % Mag line
                % RE: Update Y data to track abs vs. dB
                Zlevel = this.Parent.getZLevel('backgroundline');
                if this.MagPhase == 1
                    YData = unitconv(infline(0,Inf),'abs',char(this.Axes.MagnitudeUnit));
                    npts = length(YData);
                    set(this.NyqLine,'Xdata',NyqFreq(:,ones(1,npts)),...
                        'YData', YData, 'ZData', Zlevel(:,ones(1,npts)))
                else
                    % Phase line
                    npts = length(get(this.NyqLine,'YData'));
                    set(this.NyqLine,'Xdata',NyqFreq(:,ones(1,npts)),'Visible','on')
                end
            else
                if this.MagPhase == 1
                    set(this.NyqLine,'XData',[],'YData',[],'ZData',[])
                else
                    set(this.NyqLine,'Visible','off')
                end
            end
        end
        
        function Magi = interpmag(this, W, Mag, Wi)
            %INTERPMAG  Interpolates magnitude data in the visual units.
            %           MAG and MAGI are expressed in Absolute units.
            %           The interpolation occurs in abs or log scale depending
            %           on the magnitude scale and units.
            
            %   Author(s): Bora Eryilmaz
            %   Copyright 1986-2007 The MathWorks, Inc.
            
            % Interpolate log of magnitude
            Magi = pow2(utInterp1(W, log2(Mag), Wi));
        end
        
        function MovePtr = reframe(this,PlotAxes,Mode,X,Y)
            % Reframes plot to include specified data.
            %
            %   REFRAME adjusts the (auto) axes limits to include
            %   the specified data X,Y.  The MODE string is either
            %   'x', 'y', or 'xy'.
            
            %   Copyright 1986-2014 The MathWorks, Inc.
            Ax = this.Axes;
            MovePtr = false;

            % % Phase axis
            % if any(Mode=='x')
            %     if strcmp(Ax.XUnits,'deg')
            %         ShiftX = Ax.slidelims(PlotAxes,'x','linear',90,X);
            %         if ShiftX
            %             PlotAxes.XTickMode = 'auto';
            %             PlotAxes.XTick = phaseticks(PlotAxes.XTick,PlotAxes.XLim);
            %         end
            %     else
            %         ShiftX = Ax.slidelims(PlotAxes,'x','linear',pi/2,X);
            %     end
            % else
            %     ShiftX = 0;
            % end
            % 
            % % Mag axis
            % if any(Mode=='y')
            %     ShiftY = Ax.slidelims(PlotAxes,'y','linear',20,Y);
            % else
            %     ShiftY = 0;
            % end
            % 
            % MovePtr = ShiftX || ShiftY;
            % if MovePtr
            %     % Notify peers of limit change
            %     % Ax.send('PostLimitChanged')
            % end
        end
        
        function interpxy(this)
            %INTERPXY  Sets the X and Y coordinates of zero/pole markers of
            %          plant/compensator overlayed on Nichols plot.
            %          Magnitude and Phase should be in Current Units.
            %
            Magnitude = mag2db(getGain(this.Data) * this.Data.Magnitude);
            Phase = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));

            % Convert frequency data to current units
            Frequency = this.Data.Frequency*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
            
            % Get handles of Nichols plot objects (zero/pole markers for plant/compensator)
            hPZ = this.FixedPZ;
            
            % Get frequency data of corresponding objects in current units
            FreqPZ = get(hPZ, {'UserData'});
            FreqPZ = cat(1, FreqPZ{:})*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
            
            % Compute interpolated Magnitude and Phase locations (in current units)
            MagPZ = utInterp1(Frequency, Magnitude, FreqPZ);
            PhaPZ = utInterp1(Frequency, Phase, FreqPZ);
            
            % Set X and Y coordinates of object handles
            for ct = 1:length(FreqPZ)
                set(hPZ(ct), 'XData', PhaPZ(ct), 'YData', MagPZ(ct));
            end
        end
        
        function [Status] = pointerlocation(this)
            % POINTERLOCATION  Returns a string for pointer location info.
            
            % Handles
            PlotAxes = getAxes(this.Axes);
            
            % Get Nichols plot data in current units
            Gain = getGain(this.Data);
            Magnitude  = mag2db(this.Data.Magnitude * Gain);
            Phase  = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));
            Frequency = this.Data.Frequency*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
            
            % Acquire new marker position
            % REMARK: * Convert to working units
            %         * Restrict X position to be in Phase range
            %         * Restrict Y position to be in Mag range
            CP = get(PlotAxes, 'CurrentPoint');
            X = max(min(Phase), min(CP(1,1), max(Phase)));
            Y = max(min(Magnitude), min(CP(1,2), max(Magnitude)));
            
            % Frequency at the point closest to the mouse, in current units.
            W = this.project(X, Y, Phase, Magnitude, Frequency);
            
            str1 = getString(message('Control:compDesignTask:lblMagnitude',...
                sprintf('%0.3g %s', Y, getString(message('Control:compDesignTask:unitdB')))));
            str2 = getString(message('Control:compDesignTask:lblPhase',...
                sprintf('%0.3g %s', X, char(this.Axes.PhaseUnit))));
            str3 = getString(message('Control:compDesignTask:lblFrequency',...
                sprintf('%0.3g %s', W, this.Parent.Preferences.FrequencyUnits)));
            
            Spacing = blanks(4);
            Status = sprintf('%s%s%s%s%s', str1, Spacing, str2, Spacing, str3);
        end
        
        function zp = project(this, x, y, xline, yline, zline)
            % Project point (x,y) on polyline (xline,yline) at (xp,yp) and
            % find the corresponding zp on zline.
            
            %   Author(s): Bora Eryilmaz
            %   Revised:
            %   Copyright 1986-2002 The MathWorks, Inc.
            
            % Handles
            PlotAxes = getAxes(this.Axes);
            
            %---If line is single point, just return the point
            if length(xline) == 1
                xp = xline;
                yp = yline;
                zp = zline;
                ip = 1;
                return;
            end
            
            %---Transform log-scale data for linear scanning
            IsLogX = strcmpi(get(PlotAxes, 'XScale'), 'log');
            IsLogY = strcmpi(get(PlotAxes, 'YScale'), 'log');
            if IsLogX
                x = log2(x);
                xline = log2(xline);
            end
            if IsLogY
                y = log2(y);
                yline = log2(yline);
            end
            
            % Perform 'XY' tracking (good for data which crosses back on itself in x)
            [xp, yp, ip] = lproject(x, y, xline, yline, PlotAxes);
            
            % Reconvert for log scale data
            if IsLogX
                xp = pow2(xp);
            end
            if IsLogY
                yp = pow2(yp);
            end
            
            % Assumes ip lies within valid range of data (zline)
            i1 = floor(ip);
            i2 = ip-i1;
            
            % Prevents indexing error for case i1 = size(zline,1);
            if i2
                zp = zline(i1) * (1-i2) + zline(i1+1) * i2;
            else
                zp = zline(i1);
            end
        end
        
        function [index, alpha] = interppha(this, X, Xi)
            %INTERPPHA  Interpolates phase data:
            %           Given X = X(n), find (index) and (alpha) such that
            %           Xi =  (1-alpha) * X(index) + alpha * X(index+1).
            %           X and XI are expressed in linear units (deg or rad).
            
            %   Author(s): Bora Eryilmaz
            %   Revised:
            %   Copyright 1986-2009 The MathWorks, Inc.
            
            % Remove infs and nans from vector
            X = X(isfinite(X));
            
            % length of data
            np = length(X);
            
            % Length of data intervals
            dX  = X(2:np) - X(1:np-1);
            dXi = Xi      - X(1:np-1);
            
            % Find indices (k's) such that Xi is in [X(k), X(k+1)]
            % REMARK: Prevent 0's in dX.
            ratio = dXi ./ (dX + eps*(dX==0));
            index = find((ratio >=0) & (ratio <= 1)); % Use >= and <= to include end points
            
            % Interpolation coefficients
            % Xi =  (1-alpha) * X(index) + alpha * X(index+1).
            alpha = ratio(index);
        end
        
    end
end
