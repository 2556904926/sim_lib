classdef BodeResponseView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    % Copyright 2020-2022 The MathWorks, Inc.
    
    properties (Access = private)
        Axes                 % ctrluis.AxesPair object
        FixedPZ              % System poles and zeros (HG objects)
        
        MagPhase = 1;        % Magnitude or Phase line - Set this to 1 for Magnitude axes, 2 for Phase axes
        
        NyqLine              % Nyquist line (HG object)
        
        Line                 % Response Line (HG object)
        LineShadow           % Shadow line used for limit picking (HG object)
        
        GainListener         % Listener needed during drag
        AbsLinMag            % Needed during drag
        FreqData             % Needed during drag
    end
    
    methods (Access = public)
        function this = BodeResponseView(Parent, Data, Axes, ~)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            % Magnitude or Phase Line?
            if nargin == 4
                this.MagPhase = 2;
            end
            
            % Construct response line
            constructLine(this);
        end
        
        function HG = getHG(this)
            HG = [this.Line; this.FixedPZ];
        end
        
        function update(this)
            % Called during Parent BodeEditor's update
            Style = this.Parent.LineStyle;
            Ax = getAxes(this.Axes);
            if strcmp(Ax(this.MagPhase).Visible, 'on')
                % Update only if axes is visible
                if this.ShowSystemPZ
                    updateFixedPZ(this);
                end
                
                refresh(this);
                
                Ts = this.Data.Ts;
                FreqConvert = funitconv('rad/s',char(this.Axes.FrequencyUnit));
                if Ts
                    NyqFreq = FreqConvert * pi/Ts;
                else
                    NyqFreq = NaN;
                end
                % update style options
                %                 if isLoopTransfer(this.Data.getResponse)
                controllib.plot.internal.utils.setColorProperty(this.Line,"Color",Style.Color.Response);
                %                 else
                %                     this.Line.Color = Style.Color.ClosedLoop;
                %                 end
                % set(this.FixedPZ,'Color',Style.Color.System);
                controllib.plot.internal.utils.setColorProperty(this.FixedPZ,"Color",Style.Color.System);
                % setnyqline expets NyqFreq to be in axes's XUnits
                setnyqline(this,NyqFreq);
            end
        end
        
        function refresh(this)
            % Called during Parent BodeEditor's refresh - That is, when
            % something else other than the response view is being dragged.
            
            % Updates YData
            Gain = getGain(this.Data);
            if this.MagPhase == 1
                % Set the YData in current YUnits of Axes(1)
                YData = unitconv(Gain * this.Data.Magnitude','abs',char(this.Axes.MagnitudeUnit));
            else
                % Set the YData in current YUnits of Axes(2)
                YData = unitconv(this.Data.Phase,'deg',char(this.Axes.PhaseUnit));
            end
            
            % Set the XData in current XUnits of Axes
            FreqConvert = funitconv('rad/s',char(this.Axes.FrequencyUnit));
            ZData = this.Parent.getZLevel('curve',[length(this.Data.Frequency) 1]);
            FreqData = FreqConvert*this.Data.Frequency;
            
            set(this.Line, 'XData', FreqData, 'YData', YData, 'ZData', ZData);
            
            interpy(this,YData);
            
            if this.Parent.isMultiModelVisible
                this.Parent.UncertainBounds.setData(Gain*this.Data.UncertainData.Magnitude,...
                    this.Data.UncertainData.Phase,this.Data.UncertainData.Frequency);
            end
            
            % Update shadow
            XFocus = getfocus(this.Parent);
            InFocus = find(this.Data.Frequency >= XFocus(1) & this.Data.Frequency <= XFocus(2));
            
            set(this.LineShadow,'XData',FreqData(InFocus),'YData',YData(InFocus));
        end
    end
    
    methods (Access = public)
        function start(this)
            
            switch this.Parent.EditMode
                case 'idle'
                    setRefreshMode(this, 'quick');
                    if this.MagPhase == 1 && this.Data.GainTunable
                        enableDataListeners(this.Data, false);
                        setEditedBlock(this.Data,this.Data.GainTargetBlock);
                        refresh(this.Parent,'start',this);
                        % Initialize persistent
                        this.FreqData = this.Data.Frequency*funitconv('rad/s',char(this.Axes.FrequencyUnit));
                        MagAx = getAxes(this.Axes);  MagAx = MagAx(1);
                        this.AbsLinMag = strcmp(this.Axes.MagnitudeUnit,'abs') && strcmp(get(MagAx,'Yscale'),'linear');
                        
                        % Store current pointer to restore at end
                        Axes = getAxes(this.Axes); %#ok<*PROP>
                        MagAx = Axes(1);
                        moveptr(MagAx,'i');
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
                            getString(message('Control:compDesignTask:msgDragCurveToEditGain',this.Data.EditedBlock.Name)));
                    end
                case 'addpz'
                    Axes = getAxes(this.Axes); %#ok<*PROP>
%                     setRefreshMode(this,'normal');
                    addPZ(this.Parent, Axes(this.MagPhase));
            end
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function move(this)
            if this.MagPhase == 1 && this.Data.GainTunable
                switch this.Parent.EditMode
                    case 'idle'
                        % RE: Restrict X position to be in freq. data range
                        Axes = getAxes(this.Axes); %#ok<*PROP>
                        MagAx = Axes(1);
                        FreqData = this.FreqData;
                        Magnitude = this.Data.Magnitude;
                        CP = get(MagAx,'CurrentPoint');
                        X = max(FreqData(1),min(CP(1,1),FreqData(end)));
                        Y = CP(1,2);
                        if this.AbsLinMag
                            Ylim = get(MagAx,'Ylim');
                            Y = max(1e-3*Ylim(2),Y);
                        end
                        MagUnits = char(this.Axes.MagnitudeUnit);
                        % Get new gain value (interpolate in plot units to limit distorsions)
                        
                        % Interpmag expects and returns magnitude in abs units.
                        % Thus, convert current point to abs.
                        NewGain = unitconv(Y,MagUnits,'abs') / ...
                            this.interpmag(FreqData,Magnitude,X);
                        
                        
                        setGain(this.Data,NewGain,'mag');
                        
                        % Adjust Y limits to keep mouse cursor in focus
                        AutoY = strcmp(this.Axes.YLimitsMode{1},'auto');
                        
                        if AutoY
                            MovePtr = this.reframe(MagAx,'y',[],Y);
                            if MovePtr
                                % Reposition mouse pointer
                                moveptr(MagAx,'move',X,Y);
                            end
                        end
                        refresh(this.Parent,'move',this);
                        notifyValueChanged(this.Data.EditedBlock)
                end
            end
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            switch this.Parent.EditMode
                case 'idle'
                    if this.MagPhase == 1 && this.Data.GainTunable
                        enableDataListeners(this.Data, true);
                        setptr(getHGParent(this.Parent),'hand');
                        delete(this.GainListener);
                        this.GainListener = [];
                        update(this.Parent);
                        CurrentGain = getGain(this.Data);
                        this.Transaction.RedoFcn = {@setGain this CurrentGain};
                        this.Parent.EventManager.record(this.Transaction);
                        Str = getString(message('Control:compDesignTask:msgGainChangedTo',this.Data.EditedBlock.Name,sprintf('%0.3g',getGain(this.Data))));
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s. %s',Str,getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
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
            if this.MagPhase == 1 && strcmpi(this.Parent.EditMode, 'idle')
                if this.Data.GainTunable
                    HoverCursor = 'hand';
                    Status = sprintf('%s %s', get(this.Line,'Tag'), ...
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
            if this.MagPhase == 1
                Tag = getString(message('Control:compDesignTask:strOpenLoopMagPlot'));
            else
                Tag = getString(message('Control:compDesignTask:strOpenLoopPhasePlot'));
            end
            
            axes = getAxes(this.Axes);
            
            this.Line = line(...
                'Parent',axes(this.MagPhase), ...
                'XlimInclude','off',...
                'YlimInclude','off',...
                'Visible','on', ...
                'Color','b',...
                'Tag',Tag);
            
            setappdata(this.Line, 'Widget', this);
            
            this.LineShadow = line(NaN,NaN,...
                'Parent',axes(this.MagPhase), ...
                'LineStyle', 'none', ...
                'HandleVisibility', 'off', ...
                'HitTest', 'off');
            
            % Nyquist lines
            Zlevel = getZLevel(this.Parent,('backgroundline'));
            
            if this.MagPhase == 1
                this.NyqLine = line(NaN,NaN,NaN, ...
                    'Parent', axes(this.MagPhase), 'XlimInclude','off', 'YlimInclude','off',...
                    'Linestyle', '-', 'HitTest', 'off', ...
                    'HelpTopicKey', 'sisonyquistline');
            else
                YData = infline(-Inf,Inf);
                npts = length(YData);
                this.NyqLine = line(NaN([1 npts]), YData, repmat(Zlevel,[1 npts]), ...
                    'Parent', axes(this.MagPhase), 'XlimInclude','off', 'YlimInclude','off',...
                    'Linestyle','-', 'HitTest', 'off', ...
                    'HelpTopicKey', 'sisonyquistline');
            end
            controllib.plot.internal.utils.setColorProperty(this.NyqLine,...
                "Color","--mw-graphics-colorNeutral-line-primary");
        end
        
        function setGain(this, Gain)
            this.Data.setGain(Gain);
        end
        
        function refreshGain(this)
            Gain = getGain(this.Data);
            % Set YData in Axes(1)'s YUnits (interpy expects YData in
            % Axes(1)'s YUnits)
            YData = unitconv(Gain * this.Data.Magnitude','abs',char(this.Axes.MagnitudeUnit));
            set(this.Line, 'YData', YData);
            interpy(this,YData);
            
            if this.Parent.isMultiModelVisible
                this.Parent.UncertainBounds.setData(Gain*this.Data.UncertainData.Magnitude,...
                    this.Data.UncertainData.Phase,this.Data.UncertainData.Frequency);
            end
        end
        
        function updateFixedPZ(this)
            if ~isempty(this.FixedPZ)
                for ct = 1:numel(this.FixedPZ)
                    delete(this.FixedPZ(ct));
                end
                this.FixedPZ = [];
            end
            
            Ax = getAxes(this.Axes);
            [FixedZeros,FixedPoles] = getFixedPZ(this.Data);
            
            % Fixed pole/zero's XData to be set in current axes units
            FreqConvert = funitconv('rad/s',char(this.Axes.FrequencyUnit));
            
            Ts = this.Data.Ts;
            if Ts
                NyqFreq = FreqConvert * pi/Ts;
            else
                NyqFreq = NaN;
            end
            
            Zlevel = this.Parent.getZLevel('system');
            
            % System zeros
            FixedZeros = [FixedZeros(~imag(FixedZeros),:) ; FixedZeros(imag(FixedZeros)>0,:)];
            FreqZ = FreqConvert * damp(FixedZeros,Ts);
            Z = [];
            
            if Ts,
                % Discard roots whose CT frequency exceeds pi/Ts
                idx = find(FreqZ<=NyqFreq);
                FixedZeros = FixedZeros(idx);
                FreqZ = FreqZ(idx);
            end
            ZProps = {...
                'XlimInclude','off','YlimInclude','off',...
                'LineStyle','none','Marker','o','MarkerSize',5,...
                'Color','b',...
                'HitTest','off'};
            for ct=length(FixedZeros):-1:1
                Z(ct,1) = line(FreqZ(ct),NaN,Zlevel,...
                    'Parent',Ax(this.MagPhase),ZProps{:});
            end
            imfz = find(imag(FixedZeros)>0);
            set([Z(imfz,:);],'LineWidth',2)
            this.FixedPZ = [this.FixedPZ; Z];
            
            % System poles
            FixedPoles = [FixedPoles(~imag(FixedPoles),:) ; FixedPoles(imag(FixedPoles)>0,:)];
            FreqP = FreqConvert * damp(FixedPoles,Ts);
            P = [];
            if Ts,
                % Discard roots whose CT frequency exceeds pi/Ts
                idx = find(FreqP<=NyqFreq);
                FixedPoles = FixedPoles(idx);
                FreqP = FreqP(idx);
            end
            PProps = {...
                'XlimInclude','off','YlimInclude','off',...
                'LineStyle','none','Marker','x','MarkerSize',6,...
                'Color','b',...
                'HitTest','off',...
                'HelpTopicKey','sisosystempolezero'};
            for ct=length(FixedPoles):-1:1
                P(ct,1) = line(FreqP(ct),NaN,Zlevel,...
                    'Parent',Ax(this.MagPhase),PProps{:});
                
            end
            imfp = find(imag(FixedPoles)>0);
            set([P(imfp,:)],'LineWidth',2)
            this.FixedPZ = [this.FixedPZ; P];
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
        
        function Magi = interpmag(this,W,Mag,Wi)
            %INTERPMAG  Interpolates magnitude data in the visual units.
            
            % RE: MAG and MAGI are expressed in abs units. The interpolation occurs
            %     in abs or log scale depending on the mag. scale and units
            
            % Take XScale into account
            if strcmp(this.Axes.FrequencyScale,'log')
                W = log2(W);
                nz = (Wi>0);
                Wi(nz) = log2(Wi(nz));
                Wi(~nz) = -Inf;
            end
            
            % Take YScale into account
            if strcmp(this.Axes.MagnitudeUnit,'abs') && ...
                    strcmp(qeGetAxesGrid(this.Axes).YScale,'linear')
                % Interpolate natural magnitude
                Magi = utInterp1(W,Mag,Wi);
            else
                % Interpolate log of magnitude
                Magi = pow2(utInterp1(W,log2(Mag),Wi));
            end
        end
        
        function MovePtr = reframe(this,PlotAxes,Mode,X,Y)
            % Reframes plot to include specified data.
            %
            %   REFRAME adjusts the (auto) axes limits to include
            %   the specified data X,Y.  The MODE string is either
            %   'x', 'y', or 'xy'.
            
            Axes = this.Axes;
            
            % Frequency axis
            if any(Mode=='x')
                ShiftX = 0;
                if strcmp(Axes.FrequencyScale,'log')
                    % ShiftX = Axes.slidelims(PlotAxes,'x','log',10,X);
                else
                    % ShiftX = Axes.slidelims(PlotAxes,'x','log',2,X);
                end
            else
                ShiftX = 0;
            end
            
            % Mag or phase axes
            if any(Mode=='y')
                hgaxes = getAxes(Axes);
                if PlotAxes==hgaxes(1)
                    % Working in mag axes
                    ShiftY = 0;
                    if strcmp(Axes.MagnitudeUnit,'dB')
                        % ShiftY = Axes.slidelims(PlotAxes,'y','linear',20,Y);
                    else
                        % ShiftY = Axes.slidelims(PlotAxes,'y','log',2,Y);
                    end
                else
                    % Working in phase axes
                    if strcmp(Axes.PhaseUnit,'deg')
                        ShiftY = 0;
                        % ShiftY = Axes.slidelims(PlotAxes,'y','linear',90,Y);
                        % if ShiftY
                        %     PlotAxes.YTickMode = 'auto';
                        %     PlotAxes.YTick = phaseticks(PlotAxes.YTick,PlotAxes.YLim);
                        % end
                    else
                        ShiftY = Axes.slidelims(PlotAxes,'y','linear',pi/2,Y); %#ok<*PROPLC>
                    end
                end
            else
                ShiftY = 0;
            end
            
            MovePtr = ShiftX || ShiftY;
            if MovePtr
                % Notify peers of limit change
                % Axes.send('PostLimitChanged')
            end
            
        end
        
        function interpy(this,Data)
            %INTERPY  Sets Y coordinate of objects overlayed on Bode plots.
            % Convert freq. data to current units
            
            % Interpy computes YData from Data. Expects Data to be in
            % Yunits of Axes(1).
            
            % Convert frequency to Axes's Xunits
            FreqData = this.Data.Frequency*funitconv('rad/s',char(this.Axes.FrequencyUnit));
            Handles = this.FixedPZ;

            % Magnitude plot
            if strcmp(this.ShowSystemPZ,'on')
                X = get(Handles,{'Xdata'});
                Y = utInterp1(FreqData,Data,cat(1,X{:}));
                for ct=1:length(Handles)
                    set(Handles(ct),'Ydata',Y(ct))
                end
            end

        end
    end
    
    methods (Hidden = true)
        function NyqLine = qeGetNyqLine(this)
            NyqLine = this.NyqLine;
        end
    end
end
