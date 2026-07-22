classdef NicholsPZView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    % Copyright 2020 The MathWorks, Inc.
    properties (Access = private)
        %% Data
        Axes
        PZGroup              % Compensator being modified
        
        %% HG handles
        Line                 % Line handles for poles and zeros
        Ruler                % Ruler handles (HG objects)
        Extra                % Other objects (e.g., notch width markers)
        
        %% Data needed for drag
        InitData             % Initial magnitude, phase before drag start
        MovedPZID            % ID of object being moved - "pole" or "zero"
        FreqInit             % Initial frequency before drag
        YInit                % Initial YData of line before drag
        LeftRight            % Left or Right notch width marker being moved
        RadSec2FreqUnits     % Conversion factor used during drag
        W0                   % Natural Frequency
        Z1                   % Damping 1
        Z2                   % Damping 2
        AbsLinMag            % Is magnitude - abs and YScale - linear
        InvalidMove          % Root moved past nyquist line
        Description = '';    % Description of root location for status message
        hLine
        
        %% Intermediate listeners used during drag
        Listeners
    end
    
    methods (Access = public)
        function this = NicholsPZView(Parent, Data, Axes,PZGroup, ~)
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            this.PZGroup = PZGroup;
            
            constructPZLines(this);
        end
        
        function HG = getHG(this)
            HG = [this.Line.Zero; this.Line.Pole; this.Line.Ruler; this.Line.Extra];
        end
        
        function HG = getHG_PZ(this)
            % Serialized getPZ method to return all compensator poles and
            % zeros - called by Parent
            HG = [];
            for ct = 1:numel(this)
                HG = [HG; this(ct).Line.Zero; this(ct).Line.Pole];
            end
        end
        
        function update(this)
            % update only if visible
            Ax = getAxes(this.Axes);
            if strcmp(Ax.Visible, 'on')
                % Delete existing line handles
                delete(this.Line.Pole);
                delete(this.Line.Zero);
                delete(this.Line.Extra);
                delete(this.Line.Ruler);
                % Reconstruct
                constructPZLines(this);
                % Refresh
                refresh(this);
            end
        end
        
        function refresh(this)
            % Update location of notch width markers
            if strcmp(this.PZGroup.Type, 'Notch')
                Wm = notchwidth(this.PZGroup, this.Data.Ts);
                
                % Markers
                Extras = this.Line.Extra;
                set(Extras(1), 'UserData', Wm(1))
                set(Extras(2), 'UserData', Wm(2))
            end
            interpxy(this,mag2db(getGain(this.Data)*this.Data.Magnitude),unitconv(this.Data.Phase,'deg',char(this.Axes.PhaseUnit)));
            
            if any(strcmp(this.PZGroup.Type,{'Complex','Notch'}))
                set(this.Line.Pole, 'LineWidth', 2);
                set(this.Line.Zero, 'LineWidth', 2);
            end
            
        end
        
        function setPZGroup(this, PZGroup)
            this.PZGroup = PZGroup;
            if ~isempty(this.Line.Pole)
                setappdata(this.Line.Pole,'PZGroup',PZGroup);
            end
            if ~isempty(this.Line.Zero)
                setappdata(this.Line.Zero,'PZGroup',PZGroup);
            end
        end
        
        function addlistener(this)
            this.Listeners = addlistener(this.Data.EditedBlock, 'GainChanged', @(es,ed)refresh(this));
        end
        
        function delete(this)
            delete(this.Line.Pole);
            delete(this.Line.Zero);
            delete(this.Line.Extra);
            delete(this.Line.Ruler);
        end
    end
    
    methods (Access = public)
        function start(this)
            switch this.Parent.EditMode
                case 'idle'
                    setRefreshMode(this, 'quick');
                    enableDataListeners(this.Data, false);
                    setEditedBlock(this.Data, this.PZGroup.Parent);
                    this.InitData = struct(...
                        'PZGroup',copy(this.PZGroup),...
                        'Frequency',this.Data.Frequency,...
                        'Magnitude',this.Data.Magnitude,...
                        'Phase',this.Data.Phase,...
                        'UncertainData', this.Data.UncertainData);
                    
                    PlotAxes = getAxes(this.Axes);
                    refresh(this.Parent,'start',this);
                    
                    this.MovedPZID = LocalGetSelection(gcbo, this.Line);
                    this.Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction( ...
                        getString(message('Control:compDesignTask:strMovePZ',this.MovedPZID)));
                    
                    % Set undo function
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.UndoFcn = {@loadSession this.Data.EditedBlock S};
                    
                    % Create pole/zero locus curve
                    this.hLine = line([1 1], [NaN NaN], ...
                        'parent',    PlotAxes, ...
                        'HitTest',   'off', ...
                        'Visible',   get(PlotAxes, 'Visible'), ...
                        'LineStyle', '--');
                    controllib.plot.internal.utils.setColorProperty(this.hLine,...
                        "Color",this.Parent.LineStyle.Color.Compensator);
                    
                    if any(strcmpi(this.MovedPZID, {'Pole','Zero'}))
                        if this.Data.Ts~=0 && this.PZGroup.beyondnf(this.MovedPZID,0.1)
                            % Discrete roots beyond Nyquist freq. cannot be moved
                            this.Parent.EventManager.postActionStatus('off',sprintf('%s. %s',...
                                getString(message('Control:compDesignTask:msgCannotMoveRootsBeyondNyquistFreq')),...
                                getString(message('Control:compDesignTask:msgUseRlocusToMovePZ'))));
                            this.InvalidMove = 1;
                            return
                        else
                            this.InvalidMove = 0;
                        end
                        
                        
                        AutoScaleX = strcmp(this.Axes.XLimitsMode{1},'auto');
                        AutoScaleY = strcmp(this.Axes.YLimitsMode{1},'auto');
                        
                        if AutoScaleX || AutoScaleY,
                            moveptr(PlotAxes,'init');
                        end
                        
                        this.Listeners = addlistener(this.PZGroup,'PZDataChanged',...
                            @(es,ed)redrawPlot(this));
                        
                    else
                        
                        % Notch width markers are being moved
                        % Disable all warnings
                        % Initialization for notch width marker drag
                        Ts = this.Data.Ts;
                        
                        % Get notch frequency and initial depth (Zeta1/Zeta2) (both invariants)
                        [this.W0,this.Z1] = damp(this.PZGroup.Zero(1),Ts);
                        [this.W0,this.Z2] = damp(this.PZGroup.Pole(1),Ts);
                        
                        % Determine whether left or right marker is selected
                        % RE: Don't rely on handles because markers can be on top of each other
                        Wm = get(gcbo, 'UserData');
                        this.LeftRight = Wm < this.W0;
                        this.InvalidMove = 0;
                        
                        this.Listeners = addlistener(this.PZGroup,'PZDataChanged',...
                            @(es,ed)redrawPlot(this));
                    end
                    
                    this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,this.Parent.Preferences.FrequencyUnits));
                    setptr(getHGParent(this.Parent),'closedhand');
            end
            this.Parent.Preferences.setPlotUpdateEnabled();
        end
        
        function move(this)
            switch this.Parent.EditMode
                case 'idle'
                    if ~this.InvalidMove
                        PlotAxes = getAxes(this.Axes); %#ok<*PROP>
                        
                        CP = get(PlotAxes,'CurrentPoint');
                        if any(strcmpi(this.MovedPZID, {'Pole','Zero'}))
                            % Convert mouse coordinates to default units
                            X = unitconv(CP(1,1), char(this.Axes.PhaseUnit), 'rad');
                            Y = 10^(CP(1,2)/20);
                            
                            % Inputs to MOVEPZ must be in (rad/s, abs, rad)
                            [X,Y] = movepz(this, X, Y);
                            
                            % Convert back to current units
                            X = unitconv(X, 'rad', char(this.Axes.PhaseUnit));
                            Y = mag2db(Y);
                            
                            
                            notify(this.PZGroup, 'PZDataChanged');
                            notifyValueChanged(this.Data.EditedBlock)
                            % Adjust axis limits if dragged pole/zero gets out of focus
                            %             if AutoScaleX || AutoScaleY,
                            % Adjust limits to track mouse motion
                            
                            MovePtr = reframe(this,PlotAxes,'xy',X,Y);
                            if MovePtr
                                % Reposition mouse pointer
                                moveptr(PlotAxes,'move',X,Y);
                            end
                            this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,this.Parent.Preferences.FrequencyUnits));
                            
                        else
                            
                            Gain = getGain(this.Data);
                            % Set the YData in current YUnits of Axes(1)
                            Magnitude = mag2db(Gain * this.Data.Magnitude);
                            Phase = unitconv(this.Data.Phase, 'deg', char(this.Axes.PhaseUnit));

                            % Notch width markers are being moved
                            % Acquire new marker position
                            % RE: * Convert to working units (rad/sec)
                            %     * Restrict X position to be in freq. range
                            X = max(min(Phase), min(CP(1,1), max(Phase)));
                            Y = max(min(Magnitude), min(CP(1,2), max(Magnitude)));
                            % Left/right marker constraints
                            if this.LeftRight==1,  % left
                                I = find(this.Data.Frequency < this.W0);
                            else
                                I = find(this.Data.Frequency > this.W0);
                            end
                            % Left/right marker frequency constraints
                            W = this.project(X, Y, Phase(I), Magnitude(I), this.Data.Frequency(I));
                            if this.LeftRight == 1 % Left
                                W = min(W, 0.99 * this.W0);
                            else
                                W = max(W, 1.01 * this.W0);
                            end
                            % Compute new values of notch zero/pole
                            LocalUpdate(this.PZGroup, W, this.W0, this.Z1, this.Z2, this.Data.Ts)
                            
                            % Broadcast PZDataChanged event (triggers plot updates)
                            notify(this.PZGroup, 'PZDataChanged');
                            
                            % Track root location in status bar
                            %                         EventMgr.poststatus(LocalTrackStatus(ShapedGroup,Ts,FreqUnits));
                        end
                    end
            end
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            % Cache parent for access after deletion
            Parent = this.Parent;
            switch this.Parent.EditMode
                case 'idle'
                    enableDataListeners(this.Data, true);
                    % Delete hLine
                    delete(this.hLine(ishandle(this.hLine)));
                    % Record transaction
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.RedoFcn = {@loadSession this.Data.EditedBlock S};
                    
                    this.Parent.EventManager.record(this.Transaction);
                    
                    if any(strcmpi(this.MovedPZID, {'Pole','Zero'}))
                        setptr(getHGParent(this.Parent),'hand');
                        delete(this.Listeners);
                        this.Listeners = [];
                        
                        Str = this.PZGroup.movelog(this.MovedPZID,this.Data.Ts);
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s %s',Str, ...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                        update(this.Parent);
                        
                    else
                        % Button up event. Clear ruler
                        
                        Str = this.PZGroup.movelog(this.MovedPZID,this.Data.Ts);
                        
                        this.Parent.EventManager.postActionStatus('off', sprintf('%s. %s',Str,...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                    end
                    % this.Axes.send('ViewChanged');
                case 'deletepz'
                    %DELETEPZ  Deletes pole or zero graphically.
                    
                    PlotAxes = getAxes(this.Axes);
                    
                    % Acquire pole/zero position
                    CP = get(PlotAxes,'CurrentPoint');
                    
                    Xm = CP(1,1);  Ym = CP(1,2);  % pointer location
                    
                    % Get positions of all compensator poles and zeros for
                    % the compensator
                    hPZ = getHG_PZ(this.Parent);
                    
                    X = get(hPZ,{'Xdata'});  X = cat(1,X{:});
                    Y = get(hPZ,{'Ydata'});  Y = cat(1,Y{:});
                    
                    % Adjust for X and Y scales (distance measured in pixels, not data units)
                    Lims = get(PlotAxes,{'Xlim','Ylim'});
                    if strcmp(PlotAxes.XScale,'log')
                        Lims{1} = log2(Lims{1});   Xm = log2(Xm);
                        ispos = (X>0);
                        X(ispos,:) = log2(X(ispos,:));
                        X(~ispos,:) = -Inf;
                    end
                    if strcmp(PlotAxes.YScale,'log')
                        Lims{2} = log2(Lims{2});   Ym = log2(Ym);
                        ispos = (Y>0);
                        Y(ispos,:) = log2(Y(ispos,:));
                        Y(~ispos,:) = -Inf;
                    end
                    
                    % Determine nearest match
                    [distmin,imin] = ...
                        min(abs(((Xm-X)/diff(Lims{1})).^2 + ((Ym-Y)/diff(Lims{2})).^2));
                    
                    if distmin < 0.03^2,
                        % Identify selected group and get its description
                        SelectedGroup = getappdata(hPZ(imin),'PZGroup');
                        C = SelectedGroup.Parent;
                        Description = SelectedGroup.describe(C.getTs);
                        %                         Ts = C.Ts;
                        %                         isel = C.PZGroup == SelectedGroup;
                        %                         Description = C.PZGroup(isel).describe(Ts);
                        
                        try
                            T = controllib.app.managers.eventmanager.internal.FunctionTransaction( ...
                                getString(message('Control:compDesignTask:strDeletePZ',Description{1})));
                            
                            % Set undo function
                            S = saveSession(C);
                            T.UndoFcn = {@loadSession C S};

                            % Delete selected group from list of compensator PZ groups
                            deletePZ(C,SelectedGroup);
                            
                            % Set redo function
                            S = saveSession(C);
                            T.RedoFcn = {@loadSession C S};


                            % Register transaction
                            Parent.EventManager.record(T);
                            
                            % Notify status and history listeners
                            Status = getString(message('Control:compDesignTask:strDeletedPZ',Description{2}));
                            Parent.EventManager.postActionStatus('off',Status);
                            Parent.EventManager.add2Hist(Status);
                            
                        catch ME
                            % deletion failed
                            % Parse error message and remove leading "Error..."
                            errmsg = ME.message;
                            idx = strfind('Error',errmsg);
                            if ~isempty(idx)
                                [~,errmsg] = strtok(errmsg(idx(end):end),sprintf('\n'));
                            end
                            % Pop up error dialog and abort apply
                            error(errmsg);
                            
                            %                             T.Transaction.commit; % commit transaction before deleting wrapper
                            %                             delete(T);
                        end
                    end
                    update(Parent);
            end
            
            Parent.setEditModeAndData('idle',[]);
            %             disp('Stop callback - MagPhaseView');
        end
        
        function [PointerType, HoverStatus] = hover(this, varargin)
            HitObject = varargin{1};
            switch this.Parent.EditMode
                case 'idle'
                    
                    % Pole or zero in focus
                    if strcmp(get(HitObject,'Marker'),'x')
                        PointerType = 'hand';
                        HoverStatus = getString(message('Control:compDesignTask:msgClickPoleToEdit', ...
                            this.PZGroup.Parent.describe(true)));
                    elseif strcmp(get(HitObject,'Marker'),'o')
                        PointerType = 'hand';
                        HoverStatus = getString(message('Control:compDesignTask:msgClickZeroToEdit', ...
                            this.PZGroup.Parent.describe(true)));
                    else
                        % Notch width markers being moved
                        PointerType = 'lrdrag';
                        HoverStatus =  getString(message('Control:compDesignTask:msgClickNotchToEdit'));
                    end
            end
            
        end
    end
    
    methods (Access = private)
        function constructPZLines(this)
            Ax = getAxes(this.Axes);
            Style = this.Parent.LineStyle;
            Zeros = this.PZGroup.Zero;   % zero values
            Ts = this.Data.Ts;
            if ~isempty(Zeros)
                if Ts
                    FreqZ = min(damp(Zeros(1), this.Data.Ts), pi/Ts);
                else
                    FreqZ = damp(Zeros(1)); % in rad/sec
                end
                ZProps = {...
                    'LineStyle','none',...
                    'LineWidth',0.75,...
                    'Marker','o','MarkerSize',6};
                hZ = line(NaN,NaN,NaN,...
                    'Parent',Ax,'Visible','on',...
                    'UserData', FreqZ, ...
                    ZProps{:});
                controllib.plot.internal.utils.setColorProperty(hZ,...
                    "Color",Style.Color.Compensator);
                setappdata(hZ,'PZGroup',this.PZGroup);
                setappdata(hZ,'Widget', this);
            else
                hZ = zeros(0,1);
            end
            this.Line.Zero = hZ;
            
            % Render poles
            Poles = this.PZGroup.Pole;   % pole values
            if ~isempty(Poles)
                if this.Data.Ts
                    FreqP = min(damp(Poles(1), Ts), pi/Ts);
                else
                    FreqP = damp(Poles(1)); % in rad/sec
                end
                PProps = {...
                    'LineStyle','none',...
                    'LineWidth',0.75,...
                    'Marker','x','MarkerSize',8};
                hP(1,1) = line(NaN,NaN,NaN,...
                    'Parent',Ax,'Visible','on',...
                    'UserData', FreqP, ...
                    PProps{:});
                controllib.plot.internal.utils.setColorProperty(hP,...
                    "Color",Style.Color.Compensator);
                setappdata(hP,'PZGroup',this.PZGroup);
                setappdata(hP,'Widget', this);
            else
                hP = zeros(0,1);
            end
            this.Line.Pole = hP;
            
            
            if strcmp(this.PZGroup.Type,'Notch')
                FreqM = notchwidth(this.PZGroup, this.Data.Ts);  % Marker frequencies
                NWProps = {...
                    'XlimInclude','off','YlimInclude','off',...
                    'Visible','on',...
                    'LineStyle','none','Marker','diamond',...
                    'MarkerSize',6,...
                    'Tag','NotchWidthMarker',...
                    'HelpTopicKey','sisonotchwidthmarker'}; %,...
                
                nwm(1,1) = line(NaN,NaN,NaN,'Parent',Ax, 'UserData', FreqM, NWProps{:});
                nwm(2,1) = line(NaN,NaN,NaN,'Parent',Ax, 'UserData', FreqM, NWProps{:});
                controllib.plot.internal.utils.setColorProperty(nwm,...
                    ["MarkerFaceColor","Color"],"--mw-graphics-colorNeutral-line-secondary");

                setappdata(nwm(1),'PZGroup',this.PZGroup);
                setappdata(nwm(1),'Widget',this);
                
                setappdata(nwm(2),'PZGroup',this.PZGroup);
                setappdata(nwm(2),'Widget',this);
                
                this.Line.Extra = nwm;
            else
                this.Line.Extra = zeros(0,1);
            end
            this.Line.Ruler = zeros(0,1);
            % Update axis limits
            % RE: Includes line handle restacking for proper layering
            %             updateview(this)
        end
        
        function interpy(this,Data)
            %INTERPY  Sets Y coordinate of objects overlayed on Bode plots.
            % Convert freq. data to current units
            
            FreqData = this.Data.Frequency*funitconv('rad/s',char(this.Axes.PhaseUnit));
            Handles = [this.Line.Pole;this.Line.Zero;this.Line.Extra];

            % Magnitude plot
            X = get(Handles,{'Xdata'});
            Y = utInterp1(FreqData,Data,cat(1,X{:}));
            for ct=1:length(Handles)
                set(Handles(ct),'Ydata',Y(ct))
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
            MovePtr = false;
            % 
            % Ax = this.Axes;
            % 
            % % Phase axis
            % if any(Mode=='x')
            %     if strcmp(Ax.PhaseUnit,'deg')
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
            %     Ax.send('PostLimitChanged')
            % end
        end
        
        function setPZData(this, Value)
            if strcmpi(this.PZGroup.Type, 'Notch')
                this.PZGroup.Zero = Value(1:2);
                this.PZGroup.Pole = Value(3:4);
            else
                this.PZGroup.(this.MovedPZID) = Value;
            end
            update(this.Parent);
        end
        
        function redrawPlot(this)
            % Update plot
            % RE:  * PZGroup: current PZGROUP data
            %      * Working units are (rad/sec,abs,deg)
            Ts = this.Data.Ts;
            
            % Natural and peaking frequencies for new pole/zero locations (in rad/sec)
            [W0,Zeta] = damp([this.PZGroup.Zero;this.PZGroup.Pole],Ts);
            
            if Ts,
                % Keep root freq. below Nyquist freq.
                W0 = min(W0,pi/Ts);
            end
            t = W0.^2 .* (1 - 2 * Zeta.^2);
            Wpeak = sqrt(t(t>0,:));
            
            % Update mag and phase data
            % RE: Update editor properties (used by INTERPY and REFRESHMARGIN)
            Wxtra = [Wpeak;W0];
            InitMag = [this.InitData.Magnitude ; ...
                interpmag(this,this.InitData.Frequency,this.InitData.Magnitude,Wxtra)];
            InitPhase = [this.InitData.Phase ; ...
                utInterp1(this.InitData.Frequency,this.InitData.Phase,Wxtra)];
            
            [W,iu] = LocalUniqueWithinTol([this.InitData.Frequency;Wxtra],1e3*eps);% sort + unique
            [this.Data.Magnitude, this.Data.Phase] = ...
                subspz(this, this.InitData.PZGroup, this.PZGroup, W, InitMag(iu), InitPhase(iu), Ts);
            this.Data.Frequency = W;
            
            %%%%%%% Update uncertainty bounds
            if this.Data.isUncertain && this.Parent.isMultiModelVisible
                for ct = 1:size(this.InitData.UncertainData.Magnitude,2)
                    
                    UInitMag = [this.InitData.UncertainData.Magnitude(:,ct) ; ...
                        this.interpmag(this.InitData.UncertainData.Frequency,...
                        this.InitData.UncertainData.Magnitude(:,ct),Wxtra)];
                    
                    UInitPhase = [this.InitData.UncertainData.Phase(:,ct) ; ...
                        utInterp1(this.InitData.UncertainData.Frequency,...
                        this.InitData.UncertainData.Phase(:,ct),Wxtra)];
                    
                    [UW,iu] = sort([this.InitData.UncertainData.Frequency;Wxtra]);  % sort + unique
                    
                    [UMagnitude(:,ct), UPhase(:,ct)] = ...
                        subspz(this, this.InitData.PZGroup, this.PZGroup, UW, UInitMag(iu), UInitPhase(iu), Ts);
                end
                this.Data.UncertainData.Magnitude = UMagnitude;
                this.Data.UncertainData.Phase = UPhase;
                this.Data.UncertainData.Frequency = UW(:);
            end
            if strcmpi(this.PZGroup.Type, 'LeadLag')
                set(this.Line.Zero, 'UserData', W0(1));
                set(this.Line.Pole, 'UserData', W0(2));
            else
                set(this.Line.Zero, 'UserData', min(W0));
                set(this.Line.Pole, 'UserData', min(W0));
            end
            refresh(this.Parent,'move',this);
            
            refresh(this);
        end
        
        function [mag,phase] = subspz(~,PZold,PZnew,w,mag,phase, Ts)
            % Updates frequency response by swapping pole/zero groups.
            %
            %   H = SUBSPZ(EDITOR,PZold,PZnew,W,H) returns the updated frequency
            %   response when swapping the pole/zero group PZOLD for PZNEW.
            %
            %   [MAG,PHASE] = SUBSPZ(EDITOR,PZold,PZnew,W,MAG,PHASE) returns the
            %   updated MAG,PHASE data when swapping the pole/zero group PZOLD
            %   for PZNEW.
            
            % RE: MAG, PHASE is associated to a (normalized) ZPK model and the
            %     update is therefore independent of the format.
            
            % Construct corrective factor
            zcorr = [PZold.Pole ; PZnew.Zero];
            pcorr = [PZold.Zero ; PZnew.Pole];
            
            % S or Z vectors
            s = 1i*w(:).';
            if Ts,
                s = exp(Ts * s);
            end
            ls = length(s);
            
            % Compute correction. Corrective term is prod(s-zj)/prod(s-pj)
            sz = s(ones(1,length(zcorr)),:) - zcorr(:,ones(1,ls));
            sp = s(ones(1,length(pcorr)),:) - pcorr(:,ones(1,ls));
            a = prod(sz,1);
            b = prod(sp,1);
            Correction = ones(size(a));
            nzb = find(b);
            Correction(:,nzb) = a(:,nzb)./b(:,nzb);
            
            % Update mag and phase
            Correction = reshape(Correction,length(Correction),1);
            if nargin==5
                % Complex frequency response
                mag = mag .* Correction;
            else
                mag = mag .* abs(Correction);
                phase = phase + (180/pi) * unwrap(angle(Correction)); % phase in degrees
            end
        end
        
        function [X,Y] = movepz(this, X, Y)
            %  MOVEPZ   Updates pole/zero group to track mouse location (X,Y) in editor
            %           axes.  X is in rad, and Y is in abs.
            
            %  Author(s): Bora Eryilmaz
            %  Revised:
            %  Copyright 1986-2008 The MathWorks, Inc.
            
            % REMARK: G0 contains initial pole/zero values for moved group
            
            % Initial data
            G0 = this.PZGroup;
            C = this.Data.EditedBlock;
            Ts = C.getTs;
            
            % Pole/zero format: time constant or zero/pole/gain
            Format = C.getFormat;
            Format = lower(Format(1));
            
            % Some Parameters
            Group.Zero = this.PZGroup.Zero.';  % Compensator roots in row (1xNz)
            Group.Pole = this.PZGroup.Pole.';  % (1xNp)
            iszpk  = strcmp(Format, 'z');          % pole/zero or time-constant format
            sgnpz  = 1 - 2 * strcmp(this.MovedPZID, 'Pole'); % 1 if zero, -1 otherwise
            
            % Get initial mag/phase data and remove contribution of moved roots
            % REMARK: Do not project to end points to avoid 0 frequency.
            Xr = this.Data.Phase(2:end-1) * pi / 180;   % rad
            Yr = this.Data.Magnitude(2:end-1) * getGain(this.Data);  % abs
            Wo = this.Data.Frequency(2:end-1);  % rad/sec
            [Xo,Yo] = LocalRespCurve(Wo, Xr, Yr, Group, Ts, Format, -1);
            
            
            % Update pole/zero group data
            switch this.PZGroup.Type
                case 'Real'
                    % Real root in current domain.  Can't be s = 0 or z = 1.
                    r0 = G0.(this.MovedPZID);  % Initial (moved) real root
                    
                    % Locus of pole/zero marker positions.
                    R0 = LocalSetRoot(Wo, Ts, r0);   % column vector of s = sgn(r0)*w, etc.
                    Group.(this.MovedPZID) = R0;
                    [LocPha, LocMag] = LocalRespCurve(Wo, Xo, Yo, Group, Ts, Format, 1);
                    
                    Xinit = utInterp1(Wo,Xr,abs(r0)); % initial root phase
                    Yinit = this.interpmag(Wo,Yr,abs(r0)); %initial root mag value
                    
                    if any( (abs(Xinit-LocPha)+abs(Yinit-LocMag) ) > 1e-6)
                        % g 177089 Check if the pole/zero can be moved
                        
                        % Plot marker locus
                        LocalLocusLine(this, this.hLine, LocPha, LocMag);
                        
                        % Project mouse position onto the marker locus and get frequency.
                        W = LocalProject(this, X, Y, LocPha, LocMag, Wo);
                        
                        % New root value
                        R = LocalSetRoot(W, Ts, r0);
                        this.PZGroup.(this.MovedPZID) = R;
                        
                        % Recalculate the pole/zero marker position
                        [X,Y] = LocalMarkerPosition(this, W, Wo, LocPha, LocMag);
                        
                    else
                        % Do not update marker position
                        X = Xinit;
                        Y = Yinit;
                        
                    end
                    
                    
                case 'LeadLag'
                    % Real root in current domain. Can't be s = 0 or z = 1.
                    ZPID = setxor(this.MovedPZID, {'Pole', 'Zero'}); ZPID = ZPID{:};
                    r0 = G0.(this.MovedPZID);  % Initial (moved) real root
                    r1 = G0.(ZPID);  % Initial (fixed) real root
                    
                    % Locus of pole/zero marker positions.
                    R0 = LocalSetRoot(Wo, Ts, r0);   % column vector
                    R1 = r1 * ones(length(Wo),1);
                    Group.(this.MovedPZID) = R0;
                    Group.(ZPID) = R1;
                    [LocPha, LocMag] = LocalRespCurve(Wo, Xo, Yo, Group, Ts, Format, 1);
                    
                    % Plot marker locus
                    LocalLocusLine(this, this.hLine, LocPha, LocMag);
                    
                    % Project mouse position on the marker locus and get frequency.
                    W = LocalProject(this, X, Y, LocPha, LocMag, Wo);
                    
                    % New root value
                    R = LocalSetRoot(W, Ts, r0);
                    this.PZGroup.(this.MovedPZID)= R;
                    
                    % Recalculate the pole/zero marker position
                    [X,Y] = LocalMarkerPosition(this, W, Wo, LocPha, LocMag);
                    
                    
                case 'Complex'
                    % Complex root (natural freq = W)
                    r0 = G0.(this.MovedPZID);
                    r0 = r0(1);     % initial moved complex root
                    [w0, Zeta] = damp(r0, Ts);  % initial damping
                    
                    % Locus of pole/zero marker positions.
                    R0 = LocalSetRoot(Wo, Ts, r0, Zeta);   % column vector
                    Group.(this.MovedPZID) = [R0, conj(R0)];
                    [LocPha, LocMag] = LocalRespCurve(Wo, Xo, Yo, Group, Ts, Format, 1);
                    
                    % Project mouse position on the marker locus and get frequency.
                    W = LocalProject(this, X, Y, LocPha, LocMag, Wo);
                    
                    % Update dmping. Zeta here is actually abs(Zeta).
                    Zeta = (Y/this.interpmag(Wo,Yo,W))^sgnpz / 2 / W^(2*iszpk);
                    Zeta = max(min(Zeta,1), sqrt(2*eps));  % 0 < Zeta <= 1
                    
                    % Locus of pole/zero marker positions for new Zeta.
                    r = LocalSetRoot(Wo, Ts, r0, Zeta);   % column vector
                    Group.(this.MovedPZID) = [r, conj(r)];
                    [LocPha, LocMag] = LocalRespCurve(Wo, Xo, Yo, Group, Ts, Format, 1);
                    
                    % Marker locus
                    LocalLocusLine(this, this.hLine, LocPha, LocMag);
                    
                    % New root value
                    R = LocalSetRoot(W, Ts, r0, Zeta);  % new value
                    this.PZGroup.(this.MovedPZID) = [R ; conj(R)];
                    
                    % Recalculate the pole/zero marker position
                    [X,Y] = LocalMarkerPosition(this, W, Wo, LocPha, LocMag);
                    
                    
                case 'Notch'
                    % Mouse motion controls w0 and ZetaZ (ZetaP is fixed)
                    % Notch filter (s^2+2*ZetaZ*w0*s+w0^2) / (s^2+2*ZetaP*w0*s+w0^2)
                    [w0, ZetaZ] = damp(G0.Zero(1), Ts);   % initial zero damping (moved)
                    [w0, ZetaP] = damp(G0.Pole(1), Ts);   % initial pole damping (fixed)
                    sgnZP = (sign(ZetaZ) - sign(ZetaP)) / 2;
                    
                    % Locus of pole/zero marker positions for ZetaZ.
                    LocPha = Xo + pi * sgnZP;
                    LocMag = Yo * abs(ZetaZ/ZetaP);
                    
                    % Project mouse position on the marker locus and get frequency.
                    W = LocalProject(this, X, Y, LocPha, LocMag, Wo);
                    
                    % Update zero damping. ZetaZ here is actually abs(ZetaZ).
                    ZetaZ = Y/this.interpmag(Wo,Yo,W) * abs(ZetaP);
                    ZetaZ = max(min(ZetaZ,abs(ZetaP)), sqrt(2*eps));  % 0 < ZetaZ <= ZetaP
                    
                    % Locus of pole/zero marker positions for new ZetaZ.
                    LocPha = Xo + pi * sgnZP;
                    LocMag = Yo * abs(ZetaZ/ZetaP);
                    
                    % Marker locus
                    LocalLocusLine(this, this.hLine, LocPha, LocMag);
                    
                    % Update notch data
                    z = LocalSetRoot(W, Ts, G0.Zero(1), ZetaZ);  % new values
                    p = LocalSetRoot(W, Ts, G0.Pole(1), ZetaP);
                    this.PZGroup.Zero=[z ; conj(z)];
                    this.PZGroup.Pole= [p ; conj(p)];
                    
                    % Recalculate the pole/zero marker position
                    [X,Y] = LocalMarkerPosition(this, W, Wo, LocPha, LocMag);
            end
            
        end
        
        function interpxy(this, Magnitude, Phase)
            %INTERPXY  Sets the X and Y coordinates of zero/pole markers of
            %          plant/compensator overlayed on Nichols plot.
            %          Magnitude and Phase should be in Current Units.
            %
            %   Author(s): Bora Eryilmaz
            %   Revised:
            %   Copyright 1986-2010 The MathWorks, Inc.
            
            % Get HG handle
            hPZ = [this.Line.Zero; this.Line.Pole;  this.Line.Extra];
            
            % Convert frequency data to current units
            Frequency = this.Data.Frequency*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
            
            
            % Get frequency data of corresponding objects in current units
            FreqPZ = get(hPZ, {'UserData'});
            FreqPZ = cat(1, FreqPZ{:})*funitconv('rad/s', this.Parent.Preferences.FrequencyUnits);
            
            % Compute interpolated Magnitude and Phase locations (in current units)
            MagPZ = utInterp1(Frequency, Magnitude, FreqPZ);
            PhaPZ = utInterp1(Frequency, Phase, FreqPZ);
            
            % Set X and Y coordinates of object handles
            for ct = 1:length(FreqPZ)
                set(hPZ(ct), 'XData', PhaPZ(ct), 'YData', MagPZ(ct), 'ZData', getZLevel(this.Parent, 'compensator'));
            end
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
    end
end


%----------------------- Local function ----------------------

function r = d2c(r,Ts)
% Get equivalent root value in continuous-time domain
if Ts
    r = log(r)/Ts;
end
end

function r = c2d(r,Ts)
% Get equivalent root value in discrete-time domain
if Ts
    r = exp(Ts*r);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%
% LocalUniqueWithinTol %
%%%%%%%%%%%%%%%%%%%%%%%%
function [w,iu] = LocalUniqueWithinTol(w,rtol)
% Eliminates duplicates within RTOL (relative tolerance)
% Helps prevent reintroducing duplicates during unit conversions

% Sort W
[w,iu] = sort(w);

% Eliminate duplicates
lw = length(w);
dupes = find(w(2:lw)-w(1:lw-1)<=rtol*w(2:lw));
w(dupes,:) = [];
iu(dupes,:) = [];
end

%%%%%%%%%%%%%%%%%%%
% LocalGetSelection %
%%%%%%%%%%%%%%%%%%%

function PZID = LocalGetSelection(CurrentObj, Line)
% Identifies selected PZGROUP object (pole/zero group)

% Moved PZVIEW object
if CurrentObj == Line.Pole
    PZID = 'Pole';
elseif CurrentObj == Line.Zero
    PZID = 'Zero';
elseif any(CurrentObj == Line.Extra)
    PZID = 'NotchWidthMarkers';
end
end

%%%%%%%%%%%%%%%
% LocalUpdate %
%%%%%%%%%%%%%%%
function LocalUpdate(Group, W, W0, Z1, Z2, Ts)
%  The natural frequency Wn and the depth factor Z1/Z2 are
%  invariant during the move operation.

% Markers are located at DepthFraction of the total notch depth in dB
% (for an isolated notch)
DepthFraction = 0.25;

% Moving the width marker amounts to transforming (Z1,Z2)->(t*Z1,t*Z2)
% The various quantities are related by
%     (x-1)^2 + 4 t^2 Zeta1^2 x
%     ------------------------- = (Zeta1/Zeta2)^(2*DepthFraction)
%     (x-1)^2 + 4 t^2 Zeta2^2 x
% with x = (W/W0)^2 .  Solve for t and enforce |t*Z2|<=1
Z1s = Z1^2;
Z2s = Z2^2;
x = (W/W0)^2;

if abs(Z1s-Z2s) < sqrt(eps)*Z2s
    % t->0.5*sqrt((x-1)^2/x/Z1s * DepthFraction/(1-DepthFraction)) as Z2s-Z1s->0
    t = sqrt((x-1)^2 / x / Z1s * DepthFraction / (1-DepthFraction)) / 2;
else
    theta = (Z1s / Z2s)^DepthFraction;
    t = sqrt((theta-1) * (x-1)^2 / x / (Z1s-theta*Z2s)) / 2;
end
t = min(t, 1/abs(Z2));  % |t*Z2|<=1

% Root values
Z1 = t * Z1;
Z2 = t * Z2;
Zero = W0 * (-Z1 + 1i * sqrt(1 - Z1^2));
Pole = W0 * (-Z2 + 1i * sqrt(1 - Z2^2));
if Ts,
    Zero = exp(Ts*Zero);
    Pole = exp(Ts*Pole);
end

% Update group data
Group.Zero = [Zero ; conj(Zero)];
Group.Pole = [Pole ; conj(Pole)];
end
% ----------------------------------------------------------------------------%
% Function: LocalTrackStatus
% Display info about moved pole/zero
% ----------------------------------------------------------------------------%
function Status = LocalTrackStatus(PZGroup, PZID, Ts, FreqUnits)
% Definitions
Spacing = blanks(4);

switch PZGroup.Type
    case 'Notch'
        % Custom display for notch filters
        Text = getString(message('Control:compDesignTask:msgShapeNotch2'));
        [Wn, Zeta] = damp([PZGroup.Zero(1) ; PZGroup.Pole(1)], Ts);
        Wn = Wn*funitconv('rad/s', FreqUnits);
        
        Status = ...
            sprintf('%s. %s%s%s%s%s',...
            Text, ...
            getString(message('Control:compDesignTask:lblNaturalFrequency',sprintf('%0.3g',Wn(1)), FreqUnits)), ...
            Spacing, ...
            getString(message('Control:compDesignTask:lblZeroDamping',sprintf('%0.3g',Zeta(1)))), ...
            Spacing, ...
            getString(message('Control:compDesignTask:lblPoleDamping',sprintf('%0.3g',Zeta(2)))));
        
        
    case 'Complex'
        % Complex pair
        if strcmpi(PZID,'pole')
            Text = getString(message('Control:compDesignTask:msgDragPole'));
        else
            Text = getString(message('Control:compDesignTask:msgDragZero'));
        end
        R = PZGroup.(PZID);
        R = R(1);
        [Wn, Zeta] = damp(R, Ts);
        Wn = Wn*funitconv('rad/s', FreqUnits);
        Status = ...
            sprintf('%s. %s%s%s%s%s',...
            Text, ...
            getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g %s %0.3gi',real(R),'+/-',abs(imag(R))))), ...
            Spacing, ...
            getString(message('Control:compDesignTask:lblDamping',sprintf('%0.3g',Zeta))), ...
            Spacing, ...
            getString(message('Control:compDesignTask:lblNaturalFrequency',sprintf('%0.3g',Wn),FreqUnits)));
        
    otherwise
        % Real pole/zero
        if strcmpi(PZID,'pole')
            Text = getString(message('Control:compDesignTask:msgDragPole'));
        else
            Text = getString(message('Control:compDesignTask:msgDragZero'));
        end
        R = PZGroup.(PZID);
        if Ts
            Wn = damp(R, Ts)*funitconv('rad/s', FreqUnits);
            Status = sprintf('%s. %s%s%s',...
                Text,...
                getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g',R))),...
                Spacing,...
                getString(message('Control:compDesignTask:lblNaturalFrequency',sprintf('%0.3g',Wn),FreqUnits)));
        else
            Status = sprintf('%s. %s', ...
                Text, ...
                getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g',R))));
        end
end
end

% ----------------------------------------------------------------------------%
% Purpose:  Add contribution of selected root or group of roots
%           to Nichols data and get the new marker position.
% ----------------------------------------------------------------------------%
function [X,Y] = LocalMarkerPosition(this, W, Wo, LocPha, LocMag)
X = utInterp1(Wo, LocPha, W);
Y = this.interpmag(Wo, LocMag, W);
end
% ----------------------------------------------------------------------------%
% Purpose:  Project mouse position onto the marker locus and get frequency.
% ----------------------------------------------------------------------------%
function W = LocalProject(this, Pha, Mag, LocPha, LocMag, Wo)
W = this.project(unitconv(Pha, 'rad', char(this.Axes.PhaseUnit)), ...
    mag2db(Mag), ...
    unitconv(LocPha, 'rad', char(this.Axes.PhaseUnit)), ...
    mag2db(LocMag), Wo);
end
% ----------------------------------------------------------------------------%
% Purpose:  Draw the locus of marker positions.
% ----------------------------------------------------------------------------%
function LocalLocusLine(this, hline, LocPha, LocMag)
Zlevel = this.Parent.getZLevel('curve');
set(hline, 'XData', unitconv(LocPha, 'rad', char(this.Axes.PhaseUnit)), ...
    'YData', mag2db(LocMag), ...
    'ZData', Zlevel(ones(1,length(LocPha)),:));
end
% ----------------------------------------------------------------------------%
% Purpose:  Sets up a root (continuous or discrete) with stability properties
%           as that of the initial root r, using continuous time frequency (w)
%           and damping (zeta) data.
% ----------------------------------------------------------------------------%
function p = LocalSetRoot(w, Ts, r, zeta)
% Stability of the root
if Ts
    isStable = (abs(r) > 1) - (abs(r) <= 1);   % discrete, abs(z) < 1
else
    isStable = (real(r) > 0) - (real(r) <= 0); % continuous, Re(s) < 0
end
% Root in appropriate domain
switch nargin
    case 3,  % real root
        p = c2d(isStable*w, Ts);
    case 4,  % complex root
        p = c2d(isStable*w*abs(zeta) + j*w*sqrt(1-zeta^2), Ts);
end
end
% ----------------------------------------------------------------------------%
% Purpose:  Add/remove contribution of selected root or group of roots
%           to/from Nichols data.  Generates locus in degrees and abs values.
% ----------------------------------------------------------------------------%
function [X,Y] = LocalRespCurve(Wo, Xo, Yo, Group, Ts, Format, op)
% REM: op = +1 for add and -1 for remove action.

% Get zero and pole values (in continuous domain)
rz = d2c(Group.Zero, Ts);  % zeros
rp = d2c(Group.Pole, Ts);  % poles

% Continuous domain variable, s
s = 1j * Wo;

% Evaluate root contribution
resp = 1;
switch Format
    case 'z'   % zero/pole/gain
        for ct = 1:size(rz,2)
            resp = -resp .* (1 - s./rz(:,ct));
        end
        for ct = 1:size(rp,2)
            resp = -resp ./ (1 - s./rp(:,ct));
        end
    case 't'   % time constant
        for ct = 1:size(rz,2)
            resp = resp .* (1 - s./rz(:,ct));
        end
        for ct = 1:size(rp,2)
            resp = resp ./ (1 - s./rp(:,ct));
        end
end

% Add/remove contribution of moved root(s) to/from X and Y data.
X = Xo  + op * unwrap(atan2(imag(resp), real(resp)));
Y = Yo .* (abs(resp)).^op;
end