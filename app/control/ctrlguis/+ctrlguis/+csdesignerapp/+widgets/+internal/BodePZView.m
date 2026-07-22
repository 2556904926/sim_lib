classdef BodePZView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
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
        MagPhase = 1;        % Magnitude or phase being plotted
        InitData             % Initial magnitude, phase before drag start
        MovedPZID            % ID of object being moved - "pole" or "zero"
        FreqInit             % Initial frequency before drag
        YInit                % Initial YData of line before drag
        LeftRight            % Left or Right notch width marker being movedthis.Axes
        RadSec2FreqUnits     % Conversion factor used during drag
        W0                   % Natural Frequency
        Z1                   % Damping 1
        Z2                   % Damping 2
        AbsLinMag            % Is magnitude - abs and YScale - linear
        InvalidMove          % Root moved past nyquist line
        Description = '';    % Description of root location for status message
        
        %% Intermediate listeners used during drag
        Listeners
    end
    
    methods (Access = public)
        function this = BodePZView(Parent, Data, Axes,PZGroup, ~)
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            this.PZGroup = PZGroup;
            
            if nargin == 5
                this.MagPhase = 2;
            end
            
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
            if strcmp(Ax(this.MagPhase).Visible, 'on')
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
            Ts = this.Data.Ts;
            FreqFactor = funitconv('rad/s',char(this.Axes.FrequencyUnit));
            Zeros = this.PZGroup.Zero;
            Poles = this.PZGroup.Pole;
            
            ZData = this.Parent.getZLevel('compensator');
            
            if ~isempty(this.PZGroup.Zero)
                if Ts
                    FreqZ = FreqFactor * min(damp(Zeros(1),Ts),pi/Ts);
                else
                    FreqZ = FreqFactor * damp(Zeros(1));
                end
                % Exclude roots far out focus region from limit picking
                if ~isempty(this.Data.FreqFocus) && (FreqZ<1e-2*this.Data.FreqFocus(1) || FreqZ>1e2*this.Data.FreqFocus(2))
                    set(this.Line.Zero,'XlimInclude','off','YlimInclude','off')
                end
                set(this.Line.Zero,'XData', FreqZ, 'ZData', ZData);
            end
            if ~isempty(this.PZGroup.Pole)
                if Ts
                    FreqZ = FreqFactor * min(damp(Poles(1),Ts),pi/Ts);
                else
                    FreqZ = FreqFactor * damp(Poles(1));
                end
                % Exclude roots far out focus region from limit picking
                if ~isempty(this.Data.FreqFocus) && (FreqZ<1e-2*this.Data.FreqFocus(1) || FreqZ>1e2*this.Data.FreqFocus(2))
                    set(this.Line.Pole,'XlimInclude','off','YlimInclude','off')
                end
                set(this.Line.Pole,'XData', FreqZ, 'ZData', ZData);
            end
            Axes = getAxes(this.Axes);
            
            if strcmp(this.PZGroup.Type, 'Notch') && this.MagPhase == 1
                Xm = FreqFactor * notchwidth(this.PZGroup,Ts);  % Marker frequencies
                set(this.Line.Extra(1,1), 'XData', Xm(1),'ZData',ZData);
                set(this.Line.Extra(2,1), 'XData', Xm(2),'ZData',ZData);
                if ~isempty(this.Line.Ruler)
                    YData = get(Axes(this.MagPhase), 'YLim');
                    ZData = this.Parent.getZLevel('compensator');
                    set(this.Line.Ruler(1),'Xdata',Xm([1 1],:),'YData',YData,'ZData',ZData(:,[1 1]));
                    set(this.Line.Ruler(2),'Xdata',Xm([2 2],:),'YData',YData,'ZData',ZData(:,[1 1]));
                end
            end
            
            if this.MagPhase == 1
                interpy(this,unitconv(getGain(this.Data)*this.Data.Magnitude,'abs',char(this.Axes.MagnitudeUnit)));
            else
                interpy(this,unitconv(this.Data.Phase,'deg',char(this.Axes.PhaseUnit)));
            end
            
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
                    
                    refresh(this.Parent,'start',this);
                    
                    Axes = getAxes(this.Axes); %#ok<*PROP>
                    MagAx = Axes(this.MagPhase);
                    this.MovedPZID = LocalGetSelection(gcbo);
                    FreqUnits = char(this.Axes.FrequencyUnit);
                    
                    this.Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction( ...
                        getString(message('Control:compDesignTask:strMovePZ',this.MovedPZID)));
                    
                    % Set undo function
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.UndoFcn = {@loadSession this.Data.EditedBlock S};

                    
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
                        
                        this.FreqInit = this.Data.Frequency;
                        
                        if this.MagPhase == 1
                            this.AbsLinMag = strcmp(this.Axes.MagnitudeUnit,'abs') & ...
                                strcmp(get(MagAx,'Yscale'),'linear');
                            Yinit = this.Data.Magnitude * getGain(this.Data);  % absolute
                        else
                            Yinit = (pi/180) * this.Data.Phase;   % radians
                        end
                        % YInit is in abs
                        this.YInit = LocalCancelRoot(this.MagPhase,this.FreqInit,Yinit,this.PZGroup,this.MovedPZID ,this.Data.Ts,getFormat(this.Data));
                        
                        FreqFactor = funitconv(FreqUnits,'rad/s');
                        % FreqFactor = funitconv('rad/s',FreqUnits);
                        
                        % Initial frequency in current axes XUnits
                        this.FreqInit = this.FreqInit / FreqFactor;
                        % this.FreqInit = FreqFactor*this.FreqInit;
                        
                        AutoScaleX = strcmp(this.Axes.XLimitsMode,'auto');
                        if this.MagPhase == 2 && ~this.Axes.MagnitudeVisible
                            AutoScaleY = strcmp(this.Axes.YLimitsMode{1},'auto');
                        else
                            AutoScaleY = strcmp(this.Axes.YLimitsMode{this.MagPhase},'auto');
                        end
                        
                        if AutoScaleX || AutoScaleY,
                            moveptr(MagAx,'init');
                        end
                        
                        this.Listeners = addlistener(this.PZGroup,'PZDataChanged',...
                            @(es,ed)redrawPlot(this));
                        
                    else
                        % Notch width markers are being moved
                        this.InvalidMove = 0;
                        % Initialization for notch width marker drag
                        Ts = this.Data.Ts;
                        
                        % Cache unit conversion for easy accss during drag
                        this.RadSec2FreqUnits = funitconv('rad/s',FreqUnits);
                        
                        % Get notch frequency and initial depth (Zeta1/Zeta2) (both invariants)
                        [this.W0,this.Z1] = damp(this.PZGroup.Zero(1),Ts);
                        [this.W0,this.Z2] = damp(this.PZGroup.Pole(1),Ts);
                        
                        % Determine whether left or right marker is selected
                        % RE: Don't rely on handles because markers can be on top of each other
                        CP = get(MagAx,'CurrentPoint');
                        this.LeftRight = 1 + (CP(1,1)>this.RadSec2FreqUnits * this.W0);
                        
                        % Add vertical rulers
                        Ylim = get(MagAx,'Ylim');
                        Wm = this.RadSec2FreqUnits * notchwidth(this.PZGroup,Ts);
                        %                         Zlevel = Editor.zlevel('compensator');
                        LeftRuler = line(Wm([1 1]),Ylim,'Parent',MagAx,...
                            'LineStyle','--');  % left
                        controllib.plot.internal.utils.setColorProperty(LeftRuler,...
                            "Color","--mw-graphics-colorNeutral-line-secondary");
                        setappdata(LeftRuler, 'PZGroup', this.PZGroup);
                        setappdata(LeftRuler, 'Widget', this);
                        
                        RightRuler = line(Wm([2 2]),Ylim,'Parent',MagAx,...
                            'LineStyle','--');  % right
                        controllib.plot.internal.utils.setColorProperty(RightRuler,...
                            "Color","--mw-graphics-colorNeutral-line-secondary");
                        setappdata(RightRuler, 'PZGroup', this.PZGroup);
                        setappdata(RightRuler, 'Widget', this);
                        
                        this.Line.Ruler = [LeftRuler;RightRuler];
                        
                        this.Listeners = addlistener(this.PZGroup,'PZDataChanged',...
                            @(es,ed)redrawPlot(this));
                    end
                    
                    this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,FreqUnits));
                    setptr(getHGParent(this.Parent),'closedhand');
            end
            % Set Plot Update (uses setting in Preferences)
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function move(this)
            switch this.Parent.EditMode
                case 'idle'
                    if ~this.InvalidMove
                        Axes = getAxes(this.Axes); %#ok<*PROP>
                        MagAx = Axes(this.MagPhase);
                        
                        CP = get(MagAx,'CurrentPoint');
                        if any(strcmpi(this.MovedPZID, {'Pole','Zero'}))
                            % X in visual units
                            X = max(this.FreqInit(1),min(CP(1,1),this.FreqInit(end)));
                            Y = CP(1,2);
                            if this.AbsLinMag
                                Ylim = get(MagAx,'Ylim');
                                Y = max(1e-3*Ylim(2),Y);
                            end
                            
                            FreqFactor = funitconv(char(this.Axes.FrequencyUnit),'rad/s');
                            
                            if this.MagPhase == 1
                                % Interpmag expects data in visual units.
                                % FreqInit and YInit are already in visual
                                % units
                                Y0 = this.interpmag(this.FreqInit,this.YInit,X);   % initial mag value at w=X (in abs)
                                Y = unitconv(Y,char(this.Axes.MagnitudeUnit),'abs');
                                Y = movePZMag(this,FreqFactor*X,Y,Y0);
                                Y = unitconv(Y,'abs',char(this.Axes.MagnitudeUnit));
                            else
                                Y0 = utInterp1(this.FreqInit,this.YInit,X);            % initial phase at w=X (in rad)
                                Y = unitconv(Y,char(this.Axes.PhaseUnit),'rad');
                                Y = movePZPhase(this,FreqFactor*X,Y,Y0);
                                Y = unitconv(Y,'rad',char(this.Axes.PhaseUnit));
                            end
                            
                            notify(this.PZGroup, 'PZDataChanged');
                            notifyValueChanged(this.Data.EditedBlock)
                                                        
                            % Adjust axis limits if dragged pole/zero gets out of focus
                            %             if AutoScaleX || AutoScaleY,
                            % Adjust limits to track mouse motion
                            
                            MovePtr = reframe(this,MagAx,'xy',X,Y);
                            if MovePtr
                                % Reposition mouse pointer
                                moveptr(MagAx,'move',X,Y);
                            end
                            this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,char(this.Axes.FrequencyUnit)));
                            
                        else
                            % Notch width markers are being moved
                            % Acquire new marker position
                            % RE: * Convert to working units (rad/sec)
                            %     * Restrict X position to be in freq. range
                            X = CP(1,1)/this.RadSec2FreqUnits;
                            X = max(this.Data.Frequency(1),min(X,this.Data.Frequency(end)));
                            % Left/right marker constraints
                            if this.LeftRight==1,  % left
                                X = min(X,0.99*this.W0);
                            else
                                X = max(X,1.01*this.W0);
                            end
                            % Compute new values of notch zero/pole
                            LocalShapeNotch(this.PZGroup,X,this.W0,this.Z1,this.Z2,this.Data.Ts);
                            
                            % Broadcast PZDataChanged event (triggers plot updates)
                            notify(this.PZGroup, 'PZDataChanged');
                            notifyValueChanged(this.Data.EditedBlock)
                            % Track root location in status bar
                            %                         EventMgr.poststatus(LocalTrackStatus(ShapedGroup,Ts,FreqUnits));
                        end
                    end
            end
        end
        
        function stop(this)
            % Enable Plot Update
            this.Parent.Preferences.setPlotUpdateEnabled(true);
            % Cache parent for access after deletion
            Parent = this.Parent;
            switch this.Parent.EditMode
                case 'idle'
                    enableDataListeners(this.Data, true);
                    % Record transaction
                    % Set redo function
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.RedoFcn = {@loadSession this.Data.EditedBlock S};
                    
                    
                    this.Parent.EventManager.record(this.Transaction);
                    
                    if any(strcmpi(this.MovedPZID, {'Pole','Zero'}))
                        setptr(getHGParent(this.Parent),'hand');
                        delete(this.Listeners);
                        this.Listeners = [];
                        
                        Str = this.PZGroup.movelog(this.MovedPZID,this.Data.Ts);
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s. %s',Str, ...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                        update(this.Parent);
                    else
                        % Button up event. Clear rulers
                        delete(this.Line.Ruler);
                        this.Line.Ruler = zeros(0,1);
                        
                        Str = this.PZGroup.movelog(this.MovedPZID,this.Data.Ts);
                        
                        this.Parent.EventManager.postActionStatus('off', sprintf('%s. %s',Str,...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                        update(this.Parent);
                        % Commit and stack transaction
                        %                         EventMgr.record(TransAction);
                        
                        % Broadcast MOVEPZ:finish event (exit RefreshMode=quick,...)
                        %                         LoopData.EventData.Phase = 'finish';
                        %                         LoopData.send('MovePZ')
                        
                        % Update status and command history
                        % %                         Str = ShapedGroup.movelog('',Ts);
                        %                         EventMgr.newstatus(sprintf('%s\n%s',Str,...
                        %                             getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                        %                         EventMgr.recordtxt('history',Str);
                        %
                        %                         % Clean up: release persistent UDD objects
                        %                         TransAction = [];   ShapedGroup = [];   ShapedView = [];
                        %
                        %                         % Trigger global update
                        %                         LoopData.dataevent('all');
                        %
                        %                         warning(sw); lastwarn(lw,lwid);
                    end
                    % this.Axes.send('ViewChanged');
                case 'deletepz'
                    %DELETEPZ  Deletes pole or zero graphically.
                    
                    PlotAxes = getAxes(this.Axes);
                    
                    % Acquire pole/zero position
                    PlotAxes = PlotAxes(this.MagPhase);  % mag or phase axes
                    CP = get(PlotAxes,'CurrentPoint');
                    
                    Xm = CP(1,1);  Ym = CP(1,2);  % pointer location
                    
                    % Get positions of all compensator poles and zeros for
                    % the compensator
                    hPZ = getHG_PZ(this.Parent);
                    
                    X = get(hPZ,{'Xdata'});  X = cat(1,X{:});
                    Y = get(hPZ,{'Ydata'});  Y = cat(1,Y{:});
                    
                    % Adjust for X and Y scales (distance measured in pixels, not data units)
                    Lims = get(PlotAxes,{'Xlim','Ylim'});
                    if strcmp(this.Axes.FrequencyScale,'log')
                        Lims{1} = log2(Lims{1});   Xm = log2(Xm);
                        ispos = (X>0);
                        X(ispos,:) = log2(X(ispos,:));
                        X(~ispos,:) = -Inf;
                    end
                    if strcmp(this.Axes.MagnitudeScale,'log')
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
                            
                            S = saveSession(C);
                            T.UndoFcn = {@loadSession C S};
                            
                            % Delete selected group from list of compensator PZ groups
                            deletePZ(C,SelectedGroup);
                            
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
            end
            % Reset warnings
%             warning(this.Parent.ModeManager.Warning.sw); lastwarn(this.Parent.ModeManager.Warning.lw, this.Parent.ModeManager.Warning.lwid)
            Parent.setEditModeAndData('idle',[]);
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
            axes = Ax(this.MagPhase);
            Style = this.Parent.LineStyle;
            %             if isLoopTransfer(this.Data.getResponse)
            CompColor = Style.Color.Compensator;
            %             else
            %                 CompColor = Style.Color.PreFilter;
            %             end
            Zeros = this.PZGroup.Zero;   % zero values
            if ~isempty(Zeros)
                ZProps = {...
                    'LineStyle','none',...
                    'LineWidth',0.75,...
                    'Marker','o','MarkerSize',6};
                hZ = line(NaN,NaN,NaN,...
                    'Parent',axes,'Visible','on',...
                    ZProps{:});
                controllib.plot.internal.utils.setColorProperty(hZ,"Color",CompColor);
                setappdata(hZ,'PZGroup',this.PZGroup);
                setappdata(hZ,'Widget', this);
            else
                hZ = zeros(0,1);
            end
            this.Line.Zero = hZ;
            
            % Render poles
            Poles = this.PZGroup.Pole;   % pole values
            if ~isempty(Poles)
                PProps = {...
                    'LineStyle','none',...
                    'LineWidth',0.75,...
                    'Marker','x','MarkerSize',8};
                hP(1,1) = line(NaN,NaN,NaN,...
                    'Parent',axes,'Visible','on',...
                    PProps{:});
                controllib.plot.internal.utils.setColorProperty(hP(1,1),"Color",CompColor);
                setappdata(hP,'PZGroup',this.PZGroup);
                setappdata(hP,'Widget', this);
            else
                hP = zeros(0,1);
            end
            this.Line.Pole = hP;
            
            
            if strcmp(this.PZGroup.Type,'Notch') && this.MagPhase == 1
                NWProps = {...
                    'XlimInclude','off','YlimInclude','off',...
                    'Visible','on',...
                    'LineStyle','none','Marker','diamond',...
                    'Tag','NotchWidthMarker',...
                    'HelpTopicKey','sisonotchwidthmarker'}; %,...
                %                     'ButtonDownFcn',{@LocalShapeNotch this 'init'}};
                nwm(1,1) = line(NaN,NaN,NaN,'Parent',axes,NWProps{:});
                controllib.plot.internal.utils.setColorProperty(nwm(1,1),...
                    ["MarkerFaceColor","Color"],"--mw-graphics-colorNeutral-line-secondary");
                nwm(2,1) = line(NaN,NaN,NaN,'Parent',axes,NWProps{:});
                controllib.plot.internal.utils.setColorProperty(nwm(2,1),...
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

            FreqData = this.Data.Frequency*funitconv('rad/s',char(this.Axes.FrequencyUnit));
            Handles = [this.Line.Pole;this.Line.Zero;this.Line.Extra];

            % Magnitude plot
            X = get(Handles,{'Xdata'});
            Y = utInterp1(FreqData,Data,cat(1,X{:}));
            for ct=1:length(Handles)
                set(Handles(ct),'Ydata',Y(ct))
            end
        end
        
        function Magi = interpmag(this,W,Mag,Wi)
            
            %INTERPMAG  Interpolates magnitude data in the visual units.
            
            % RE: MAG and MAGI are expressed in abs units. The interpolation occurs
            %     in abs or log scale depending on the mag. scale and units
            if strcmp(this.Axes.FrequencyScale,'log')
                W = log2(W);
                nz = (Wi>0);
                Wi(nz) = log2(Wi(nz));
                Wi(~nz) = -Inf;
            end
            
            if strcmp(this.Axes.MagnitudeUnit,'abs') && ...
                    strcmp(this.Axes.MagnitudeScale,'linear')
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
            % disp(['x: ',PlotAxes.XLimMode]);
            % disp(['y: ',PlotAxes.YLimMode]);
            % update(qeGetAxesGrid(Axes),true);
            
            % Frequency axis
            if any(Mode=='x')
                ShiftX = 0;
                if strcmp(this.Axes.FrequencyScale,'log')
                    % ShiftX = Axes.slidelims(PlotAxes,'x','log',10,X);
                else
                    % ShiftX = Axes.slidelims(PlotAxes,'x','log',2,X);
                end
            else
                ShiftX = 0;
            end
            
            % Mag or phase axes
            if any(Mode=='y')
                hgaxes = getAxes(this.Axes);
                if PlotAxes==hgaxes(1)
                    % Working in mag axes
                    ShiftY = 0;
                    if strcmp(this.Axes.MagnitudeScale,'dB')
                        % ShiftY = Axes.slidelims(PlotAxes,'y','linear',20,Y);
                    else
                        % ShiftY = Axes.slidelims(PlotAxes,'y','log',2,Y);
                    end
                else
                    % % Working in phase axes
                    if strcmp(this.Axes.PhaseUnit,'deg')
                        % ShiftY = Axes.slidelims(PlotAxes,'y','linear',90,Y);
                        ShiftY = 0;
                        if ShiftY
                            PlotAxes.YTickMode = 'auto';
                            PlotAxes.YTick = phaseticks(PlotAxes.YTick,PlotAxes.YLim);
                        end
                    else
                        % ShiftY = Axes.slidelims(PlotAxes,'y','linear',pi/2,Y); %#ok<*PROPLC>
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
        
        function Y = movePZMag(this,X,Y,Y0)
            Ts =  this.Data.Ts;
            isPole = strcmp(this.MovedPZID,'Pole');
            sgnpz = 1-2*isPole;  % 1 if zero, -1 otherwise
            Format = getFormat(this.Data);
            
            switch this.PZGroup.Type
                case 'Real'
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);   % initial value of moved root
                    if ~isreal(R0)
                        % Can only happen for z=-1
                        Y = Y0;
                    else
                        R = sign(R0) * X;   % new value
                        this.PZGroup.(this.MovedPZID) = c2d(R,Ts);
                        % Determine correct mag value Y by evaluating H0(s)/(s/X-1) or H0(s)/(1-s/X)
                        % at s=jX and using |H0(jX)|=Y0
                        switch Format
                            case 'z'
                                resp = (1i*X/R - 1);
                            case 't'
                                resp = 1 - 1i*X/R;
                        end
                        Y = Y0 * abs(resp)^sgnpz;
                    end
                case 'LeadLag'
                    % Lead/lag group
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);   % initial value of moved root
                    if ~isreal(R0)
                        % Can only happen for z=-1
                        Y = Y0;
                    else
                        this.PZGroup.(this.MovedPZID) = c2d(sign(R0)*X,Ts);
                        % Determine correct mag value Y
                        R = d2c([this.PZGroup.Zero;this.PZGroup.Pole],Ts);
                        switch Format
                            case 'z'
                                resp = (1i*X - R(1))/(1i*X - R(2));  % new lead/lag response at w=X
                            case 't'
                                resp = (1 - 1i*X/R(1))/(1 - 1i*X/R(2));
                        end
                        Y = Y0 * abs(resp);
                    end
                case 'Complex'
                    % Complex root (natural freq = X)
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);
                    R0 = R0(1);     % initial value of moved root
                    sgnR0 = (real(R0)>0)-(real(R0)<=0);
                    
                    % Evaluating H(s) = H0(s)/(s-R)/(s-conj(R)) at s = j*X  for R = (Zeta,X)
                    % gives
                    %     Y = Y0 * (2*zeta*X^2)^sgnpz
                    % with sgnpz=1 if moved root is a zero, -1 otherwise. The formula becomes
                    %     Y = Y0 * (2*zeta)^sgnpz
                    % for the bode format. Solve for ZETA:
                    switch Format
                        case 'z'
                            Xs = X^2;
                        case 't'
                            Xs = 1;
                    end
                    
                    % New damping factor
                    Zeta = (Y/Y0)^sgnpz / 2 / Xs;
                    if Zeta>1,
                        % RE: Zeta<=1 required to have complex roots
                        Zeta = 1;
                        Y = Y0 * (2 * Xs)^sgnpz;
                    end
                    
                    R = X * (sgnR0 * Zeta + 1i * sqrt(1-Zeta) * sqrt(1+Zeta));  % new value
                    
                    this.PZGroup.(this.MovedPZID) = c2d([R;conj(R)],Ts);
                    
                case 'Notch'
                    % Notch filter (s^2+2*ZetaZ*w0*s+w0^2)/(s^2+2*ZetaP*w0*s+w0^2)
                    % Mag motion controls W0 and ZetaZ (ZetaP is fixed)
                    
                    % Evaluating H(s) = H0(s) * Notch(s) at s = j*X  gives
                    %    Y = Y0 * abs(ZetaZ/ZetaP)
                    [w0,ZetaZ] = damp(this.InitData.PZGroup.Zero(1),Ts);   % initial zero damping
                    [w0,ZetaP] = damp(this.InitData.PZGroup.Pole(1),Ts);   % initial pole damping (fixed)
                    
                    % Update zero damping
                    sgnZetaZ = (ZetaZ>0)-(ZetaZ<=0);
                    ZetaZ = sgnZetaZ * abs(ZetaP) * min(Y/Y0,1);
                    Y = Y0 * abs(ZetaZ/ZetaP);
                    
                    % Update notch data
                    z = X * (-ZetaZ + 1i * sqrt(1-ZetaZ^2));
                    p = X * (-ZetaP + 1i * sqrt(1-ZetaP^2));
                    this.PZGroup.Zero = c2d([z;conj(z)],Ts);
                    this.PZGroup.Pole = c2d([p;conj(p)],Ts);
            end
            
            
        end
        
        function Y = movePZPhase(this,X,Y,Y0)
            %MOVEPZPHASE  Updates pole/zero group to track mouse location (X,Y) in editor axes.
            
            % RE: Expects freq. in rad/sec and phase in radians
            Ts =  this.Data.Ts;
            isPole = strcmp(this.MovedPZID,'Pole');
            sgnpz = 1-2*isPole;  % 1 if zero, -1 otherwise
            Format = getFormat(this.Data);
            
            % Derive continuous-time value
            switch this.PZGroup.Type
                
                case 'Real'
                    % Real root: control natural frequency + root sign
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);   % initial value of moved root
                    if ~isreal(R0)
                        % Can only happen for z=-1
                        Y = Y0;
                    else
                        % Compute phase variation DPH at w=X for both R=X and R=-X,
                        % and select root value for which DPH is closest to Y-Y0
                        R = [-X,X];
                        switch Format
                            case 'z'
                                resp = (1i*X./R - 1);
                            case 't'
                                resp = 1 - i*X./R;
                        end
                        Dph = sgnpz * atan2(imag(resp),real(resp));
                        % Pick root that best matches phase variation
                        [junk,imin] = min(abs(Dph - (Y-Y0)));
                        R = R(imin);
                        Y = Y0 + Dph(imin);
                        this.PZGroup.(this.MovedPZID) = c2d(R,Ts);
                    end
                    
                case 'LeadLag'
                    % LeadLag root: control natural frequency + force root in left half
                    % plane
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);   % initial value of moved root
                    if ~isreal(R0)
                        % Can only happen for z=-1
                        Y = Y0;
                    else
                        % Compute phase variation DPH at w=X for R=-X, Same as for real case
                        % except force leadlag roots to be in left half plane
                        switch Format
                            case 'z'
                                resp = (1+i)*X;
                            case 't'
                                resp = 1 + i;
                        end
                        Dph = sgnpz * atan2(imag(resp),real(resp));
                        Y = Y0 + Dph;
                        this.PZGroup.(this.MovedPZID) = c2d(-X,Ts);
                    end
                    
                case 'Complex'
                    % Complex root: control natural frequency and sign of real part
                    R0 = d2c(this.InitData.PZGroup.(this.MovedPZID),Ts);
                    R0 = R0(1);     % initial value of moved root
                    Zeta0 = real(R0)/abs(R0);
                    R = X * ([1 -1] * Zeta0 + 1i * sqrt(1-Zeta0^2));
                    % Estimate phase variation at w=X for both root values
                    switch Format
                        case 'z'
                            resp = (i*X - R) .* (i*X - conj(R));
                        case 't'
                            resp = (1 - i*X./R) .* (1 - i*X./conj(R));
                    end
                    Dph = sgnpz * atan2(imag(resp),real(resp));
                    % Keep root for which DPH is closest to Y-Y0
                    [junk,imin] = min(abs(Dph - (Y-Y0)));
                    R = R(imin);
                    Y = Y0 + Dph(imin);
                    this.PZGroup.(this.MovedPZID) = c2d([R;conj(R)],Ts);
                    
                case 'Notch'
                    % Notch filter: control only natural freq
                    z0 = d2c(this.InitData.PZGroup.Zero,Ts);
                    p0 = d2c(this.InitData.PZGroup.Pole,Ts);
                    % Keep damping and set Wn = X
                    WnR = X/abs(z0(1));  % ratio Wn/Wn0
                    this.PZGroup.Zero = c2d(z0*WnR,Ts);
                    this.PZGroup.Pole = c2d(p0*WnR,Ts);
                    Y = Y0;
                    
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
% LocalCancelRoot %
%%%%%%%%%%%%%%%%%%%
function Y = LocalCancelRoot(MagPhase,Freqs,Y,PZGroup,PZID,Ts,Format)
%  Remove contribution of selected root or groups of roots from magnitude or phase data

%  RE: Convert DT roots to continuous time (matched pole/zero conversion).
%      This is warranted by tractability for complex roots and the fact
%      that distortions will be corrected by REFRESHPZ
s = 1i*Freqs;

% Get zero and pole values (in CT domain)
rz = d2c(PZGroup.Zero,Ts);  % zeros
rp = d2c(PZGroup.Pole,Ts);  % poles

% Evaluate root contribution
resp = 1;
switch lower(Format(1))
    case 'z'   % zero/pole/gain
        for ct=1:length(rz)
            resp = resp .* (s - rz(ct));
        end
        for ct=1:length(rp)
            resp = resp ./ (s/rp(ct) - 1);
        end
    case 't'   % time constant
        for ct=1:length(rz)
            resp = resp .* (1 - s/rz(ct));
        end
        for ct=1:length(rp)
            resp = resp ./ (1 - s/rp(ct));
        end
end

% Remove contribution of moved root(s) from Y data
switch MagPhase
    case 1  % mag
        Y = Y ./ abs(resp);
    case 2  % phase
        Y = Y - atan2(imag(resp),real(resp));
end
end

%%%%%%%%%%%%%%%%%%%
% LocalGetSelection %
%%%%%%%%%%%%%%%%%%%

function PZID = LocalGetSelection(CurrentObj)
% Identifies selected PZGROUP object (pole/zero group)

% Moved PZVIEW object
if strcmpi(CurrentObj.Marker, 'o')
    PZID = 'Zero';
elseif strcmpi(CurrentObj.Marker, 'x')
    PZID = 'Pole';
elseif strcmpi(CurrentObj.Marker, 'diamond')
    PZID = 'NotchWidthMarkers';
end
end

%%%%%%%%%%%%%%%
% LocalUpdate %
%%%%%%%%%%%%%%%
function LocalShapeNotch(Group,W,W0,Z1,Z2,Ts)
%  Derive value of notch pole/zero from position of width marker
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
if abs(Z1s-Z2s)<sqrt(eps)*Z2s
    % t->0.5*sqrt((x-1)^2/x/Z1s * DepthFraction/(1-DepthFraction)) as Z2s-Z1s->0
    t = sqrt((x-1)^2/x/Z1s*DepthFraction/(1-DepthFraction))/2;
else
    theta = (Z1s/Z2s)^DepthFraction;
    t = sqrt((theta-1)*(x-1)^2/x/(Z1s-theta*Z2s))/2;
end
t = min(t,1/abs(Z2));  % |t*Z2|<=1

% Root values
Z1 = t * Z1;
Z2 = t * Z2;
Zero = W0 * (-Z1 + 1i * sqrt(1-Z1^2));
Pole = W0 * (-Z2 + 1i * sqrt(1-Z2^2));
if Ts,
    Zero = exp(Ts*Zero);   Pole = exp(Ts*Pole);
end

% Update group data
Group.Zero = [Zero ; conj(Zero)];
Group.Pole = [Pole ; conj(Pole)];
end

%%%%%%%%%%%%%%%%%%%%
% LocalTrackStatus %
%%%%%%%%%%%%%%%%%%%%
function Status = LocalTrackStatus(Group,PZID,Ts,FreqUnits)
% Display info about moved pole/zero

% Defs
Spacing = blanks(5);

switch Group.Type
    case 'Notch'
        % Custom display for notch filters
        Text = getString(message('Control:compDesignTask:msgShapeNotch2'));
        [Wn,Zeta] = damp([Group.Zero(1);Group.Pole(1)],Ts);
        Wn = Wn*funitconv('rad/s',FreqUnits);
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
        R = Group.(PZID);
        R = R(1);
        [Wn,Zeta] = damp(R,Ts);
        Wn = Wn*funitconv('rad/s',FreqUnits);
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
        R =  Group.(PZID);
        if Ts
            Wn = damp(R,Ts)*funitconv('rad/s',FreqUnits);
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