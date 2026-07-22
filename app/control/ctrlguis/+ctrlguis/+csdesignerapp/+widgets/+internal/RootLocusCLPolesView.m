classdef RootLocusCLPolesView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    % Copyright 2020 The MathWorks, Inc.
    properties (Access = private)
        %% Data
        Axes
        CLPoleIdx            % Closed loop pole being modified
        
        %% HG handles
        Line                 % Line handles for poles and zeros
        
        %% Data needed for drag
        OLz
        OLp
        OLk
        SelectedBranch
        MinGM
        MaxGM
        AutoScaleON
        
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
        
        %% Intermediate listeners used during drag
        GainListener
    end
    
    methods (Access = public)
        function this = RootLocusCLPolesView(Parent, Data, Axes, CLPoleIdx)
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            this.CLPoleIdx = CLPoleIdx;
            
            constructPZLines(this);
        end
        
        function HG = getHG(this)
            HG = this.Line;
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
                delete(this.Line);
                % Reconstruct
                constructPZLines(this);
                % Refresh
                refresh(this);
            end
        end
        
        function refresh(this)
            % Update tuned pole/zero location
            ZData = this.Parent.getZLevel('compensator');
            
            if ~isempty(this.CLPoleIdx)
                set(this.Line,'XData', real(this.Data.ClosedPoles(this.CLPoleIdx)), 'YData', imag(this.Data.ClosedPoles(this.CLPoleIdx)), 'ZData', ZData);
            end
            
            if ~isempty(this.Parent.UncertainBounds) && isvalid(this.Parent.UncertainBounds)
                this.Parent.UncertainBounds.setData(this.Data.UncertainCLPoles);
            end
        end
        
        function setCLPoleIdx(this, CLPoleIdx)
            this.CLPoleIdx = CLPoleIdx;
            if ~isempty(this.Line)
                setappdata(this.Line,'CLPole',this.Data.ClosedPoles(this.CLPoleIdx));
            end
        end
        
        function addlistener(this)
            this.Listeners = addlistener(this.Data.EditedBlock, 'GainChanged', @(es,ed)refresh(this));
        end
        
        function delete(this)
            delete(this.Line);
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
                        % Initialization for closed-loop pole drag
                        % Initialize static variables
                        PlotAxes = getAxes(this.Axes); %#ok<*PROP>
                        Ts = this.Data.Ts;
                        RLInfo = this.Data.OpenLoopData;
                        if RLInfo.InverseFlag
                            this.OLz = RLInfo.Pole;  this.OLp = RLInfo.Zero;  this.OLk = 1/RLInfo.Gain;
                        else
                            this.OLz = RLInfo.Zero;  this.OLp = RLInfo.Pole;  this.OLk = RLInfo.Gain;
                        end
                        
                        % Find selected closed-loop pole and associated locus branch
                        CP = get(PlotAxes,'CurrentPoint');
                        [~,isel] = min(abs(this.Data.ClosedPoles-(CP(1,1)+1i*CP(1,2))));
                        P = this.Data.ClosedPoles(isel);
                        this.SelectedBranch = LocalFindBranch(this.Data.LocusRoots,P);
                        isFiniteBranch = isfinite(this.SelectedBranch([1 end]));
                        
                        % Bounds for gain magnitude (for numerical stability and to avoid
                        % k=0 or k=Inf (no Bode plot)
                        Gains = this.Data.LocusGains;
                        if isFiniteBranch(1)
                            % Watch for numerical instability for very small k
                            this.MinGM = 1e-3 * Gains(2);
                        else
                            this.MinGM = 1e-8 * Gains(2);
                        end
                        if isFiniteBranch(2)
                            % Watch for numerical instability for very large k
                            this.MaxGM = 1e3 * Gains(end-1);
                        else
                            this.MaxGM = 1e8 * Gains(end-1);
                        end
                        
                        % Initialize parameters used to adjust limits/pointer position
                        this.AutoScaleON = ...
                            strcmp(this.Axes.XLimitsMode{1},'auto') && strcmp(this.Axes.YLimitsMode{1},'auto');
                        if this.AutoScaleON
                            moveptr(PlotAxes,'init');
                        end
                        
                        this.GainListener = addlistener(this.Data.EditedBlock, 'GainChanged', @(es,ed)refresh(this));
                        % Update pointer
                        setptr(getHGParent(this.Parent),'closedhand');
                        
                        % Start transaction
                        this.Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction(getString(message('Control:compDesignTask:strEditGain')));
                        
                        refresh(this.Parent,'start',this);
                        
                        CurrentGain = getGain(this.Data);
                        this.Transaction.UndoFcn = {@setGain this.Data CurrentGain};
                        
                        % Display pole location in status bar
                        this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(P,Ts,this.Parent.Preferences.FrequencyUnits));
                    end
            end
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function move(this)
            switch this.Parent.EditMode
                case 'idle'
                    if this.Data.GainTunable
                        PlotAxes = getAxes(this.Axes); %#ok<*PROP>
                        C = this.Data.EditedBlock;
                        CP = get(PlotAxes,'CurrentPoint');
                        
                        % Project pointer on selected branch and get new location P of selected pole
                        % RE: 1) Guarantees the moved square won't jump to a different branch
                        %        if the pointer strays away from original branch
                        %     2) Move pointer when traversing infinity along a finite-escape asymptote
                        [P,MovePtr] = LocalProjectOnBranch(CP(1,1:2),this.SelectedBranch,PlotAxes);
                        
                        % Compute new gain value
                        NumP = this.OLk * prod(P-this.OLz);  % evaluate numerator at P
                        DenP = prod(P-this.OLp);        % evaluate denominator at P
                        if (NumP == 0)
                            NewGainMag = this.MaxGM;
                        else
                            NewGainMag = min(max(this.MinGM,abs(DenP/NumP)),this.MaxGM);
                        end
                        
                        % Compute closed-loop poles
                        updateGain(this.Data, this.Data.LocusGains, this.Data.LocusRoots, NewGainMag);
                        
                        % Update loop data (triggers plot update through gain listener installed by refreshgain)
                        C.setZPKGain(NewGainMag,'mag');
                        
                        % Adjust pointer and axis limits if necessary
                        if ~MovePtr && this.AutoScaleON
                            MovePtr = this.reframe(PlotAxes,'xy',CP(1,1),CP(1,2));
                        end
                        if MovePtr
                            % Reposition mouse pointer
                            moveptr(PlotAxes,'move',real(P),imag(P))
                        end
                        refresh(this.Parent,'move',this);
                        notifyValueChanged(this.Data.EditedBlock)
                        % Track pole location in status bar
                        this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(P,this.Data.Ts,this.Parent.Preferences.FrequencyUnits,this.Data.ClosedPoles));
                    end
            end
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            % Cache for use after deletion
            Parent = this.Parent;
            switch this.Parent.EditMode
                case 'idle'
                    if this.Data.GainTunable
                        enableDataListeners(this.Data, true);
                        % Record transaction
                        
                        CurrentGain = getGain(this.Data);
                        C = this.Data.EditedBlock;
                        this.Transaction.RedoFcn = {@setGain this.Data CurrentGain};
                        
                        this.Parent.EventManager.record(this.Transaction);
                        
                        
                        setptr(getHGParent(this.Parent),'hand');
                        delete(this.GainListener);
                        this.GainListener = [];
                        
                        % Update status and command history
                        Str = getString(message('Control:compDesignTask:msgLoopGainChangedToValue',...
                            sprintf('%0.3g',C.getFormattedGain)));
                        this.Parent.EventManager.postActionStatus('off',sprintf('%s %s',Str, ...
                            getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                        
                        update(this.Parent);
                        
                        % this.Axes.send('ViewChanged');
                    end
                case 'deletepz'
                    %DELETEPZ  Deletes pole or zero graphically.
                    
                    PlotAxes = getAxes(this.Axes);
                    
                    % Acquire pole/zero position
                    % mag or phase axes
                    CP = get(PlotAxes,'CurrentPoint');
                    
                    Xm = CP(1,1);  Ym = CP(1,2);  % pointer location
                    
                    % Get positions of all compensator poles and zeros for
                    % the compensator
                    hPZ = getHG_PZ(this.Parent);
                    
                    X = get(hPZ,{'Xdata'});  X = cat(1,X{:});
                    Y = get(hPZ,{'Ydata'});  Y = cat(1,Y{:});
                    
                    % Adjust for X and Y scales (distance measured in pixels, not data units)
                    Lims = get(PlotAxes,{'Xlim','Ylim'});
                    if strcmp(this.Axes.getAxes.XScale,'log')
                        Lims{1} = log2(Lims{1});   Xm = log2(Xm);
                        ispos = (X>0);
                        X(ispos,:) = log2(X(ispos,:));
                        X(~ispos,:) = -Inf;
                    end
                    if strcmp(this.Axes.getAxes.YScale,'log')
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
                            
                            T.UndoFcn = {@addPZ C SelectedGroup.Type SelectedGroup.Zero SelectedGroup.Pole};
                            
                            GroupBeingDeleted = struct('Type', SelectedGroup.Type, ...
                                'Zero', SelectedGroup.Zero, ...
                                'Pole', SelectedGroup.Pole);
                            %
                            T.RedoFcn = {@deletePZ C GroupBeingDeleted};
                            
                            % Delete selected group from list of compensator PZ groups
                            deletePZ(C,SelectedGroup);
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
            switch this.Parent.EditMode
                case 'idle'
                    % Pole or zero in focus
                    PointerType = 'hand';
                    HoverStatus = [];
                    %                     HoverStatus = getString(message('Control:compDesignTask:msgClickZeroToEdit', ...
                    %                         this.PZGroup.Parent.describe(true)));
            end
            
        end
    end
    
    methods (Access = private)
        function constructPZLines(this)
            Ax = getAxes(this.Axes);
            Style = this.Parent.LineStyle;
            % Render poles
            Zlevel = this.Parent.getZLevel('clpole');
            CLpoles = this.Data.ClosedPoles(this.CLPoleIdx);   % pole values
            if ~isempty(CLpoles)
                hP = line(real(CLpoles),imag(CLpoles),Zlevel,...
                    'Parent',Ax, ...
                    'LineStyle','none',...
                    'Marker',Style.Marker.ClosedLoop,...
                    'MarkerSize',5,...
                    'HelpTopicKey','closedlooppoles');
                controllib.plot.internal.utils.setColorProperty(hP,...
                    ["MarkerFaceColor","MarkerEdgeColor"],Style.Color.ClosedLoop);
                setappdata(hP,'CLPole',this.Data.ClosedPoles(this.CLPoleIdx));
                setappdata(hP,'Widget', this);
            else
                hP = zeros(0,1);
            end
            this.Line = hP;
            % Update axis limits
            % RE: Includes line handle restacking for proper layering
            %             updateview(this)
        end
        
        function interpy(this,Data)
            %INTERPY  Sets Y coordinate of objects overlayed on Bode plots.
            % Convert freq. data to current units

            FreqData = this.Data.Frequency*funitconv('rad/s',char(this.Axes.FrequencyUnit));
            Handles = [this.Line];

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
            if strcmp(this.Axes.XScale,'log')
                W = log2(W);
                nz = (Wi>0);
                Wi(nz) = log2(Wi(nz));
                Wi(~nz) = -Inf;
            end
            
            if strcmp(this.Axes.YUnits{1},'abs') && ...
                    strcmp(this.Axes.YScale{1},'linear')
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
            MovePtr = false;
            %   REFRAME adjusts the (auto) axes limits to include
            %   the specified data X,Y.  The MODE string is either
            %   'x', 'y', or 'xy'.
            % Ax = this.Axes;
            % % X axis
            % if any(Mode=='x')
            %     StretchX = Ax.stretchlims(PlotAxes,'x',false,X);
            % else
            %     StretchX = 0;
            % end
            % 
            % % Y axis
            % if any(Mode=='y')
            %     StretchY = Ax.stretchlims(PlotAxes,'y',true,Y);
            % else
            %     StretchY = 0;
            % end
            % 
            % MovePtr = StretchX || StretchY;
            % if MovePtr
            %     % Notify peers of limit change
            %     % Ax.send('PostLimitChanged')
            % end
        end
    end
end


%----------------------- Local function ----------------------
%----------------- Local functions -----------------


%%%%%%%%%%%%%%%%%%%
% LocalFindBranch %
%%%%%%%%%%%%%%%%%%%
function Branch = LocalFindBranch(Locus,Pole)
%  Find locus branch containing a given pole

nbranch = size(Locus,1);
dist = zeros(1,nbranch);
x = real(Pole);
y = imag(Pole);

% Project on each branch (in true coordinates) and save min distance
for i=1:nbranch
    branch = Locus(i,:);
    [xp,yp] = lproject(x,y,real(branch),imag(branch));
    dist(i) = (xp-x)^2+(yp-y)^2;
end

% Keep branch with min distance
[~,isel] = min(dist);
Branch = Locus(isel,:);
end

%%%%%%%%%%%%%%%%%%%%%%%%
% LocalProjectOnBranch %
%%%%%%%%%%%%%%%%%%%%%%%%
function [P,MovePtrFlag] = LocalProjectOnBranch(CP,Branch,Axes)
%  Project current cursor position

NearInfTresh = 0.25;
MovePtrFlag = 0;

% Project pointer loc. on branch
% ip = relative index of projection in vector Branch
[Xp,Yp,ip] = lproject(CP(1),CP(2),real(Branch),imag(Branch),Axes);
P = Xp + 1i * Yp;

% Look for infinite pole (one at most)
kinf = find(isinf(Branch));
if ~isempty(kinf)
    % NEARINF = 1 if previous branch point is at infinity
    %         = -1 if next branch point is at infinity
    %         = 0 otherwise
    nearinf = (abs(kinf-ip)<1+NearInfTresh) * ((ip>kinf) - (ip<kinf));
    if nearinf~=0
        % End of asymptote
        if (nearinf>0 && kinf==1) || (nearinf<0 && kinf==length(Branch))
            % Asymptote for gain->0 or Inf: project on asymptote
            % P = A + (AM.AB) AB/|AB|^2
            A = Branch(kinf+2*nearinf);
            AB = Branch(kinf+nearinf) - A;
            u = AB/abs(AB);
            P = A + real((CP(1)+1i*CP(2)-A)'*u) * u;
        else
            % Finite escape: traverse infinity
            % RE: get out of NearInfTresh jump zone to avoid going back and forth
            NearInfTresh = 1.5 * NearInfTresh;
            P = (1-NearInfTresh) * Branch(kinf-nearinf) + NearInfTresh * Branch(kinf-2*nearinf);
            MovePtrFlag = 1;
        end
    end
end
end


%%%%%%%%%%%%%%%%%%%%
% LocalTrackStatus %
%%%%%%%%%%%%%%%%%%%%
function StatusText = LocalTrackStatus(P,Ts,FreqUnits,CurrentPoles)
%  Display current pole data on status bar

if nargin==4
    % P = position of (projected) pointer
    % Get true location of closed-loop pole nearest to P
    [~,imin] = min(abs(CurrentPoles-P));
    P = CurrentPoles(imin);
end
Y = imag(P);

% Display string
Text = getString(message('Control:compDesignTask:msgDragCLPole'));
if Y, % Complex pole
    [Wn,Zeta] = damp(P,Ts);
    Wn = Wn*funitconv('rad/s',FreqUnits);
    % Don't trust
    if Y>0, Sign = '+'; else Sign = '-'; end
    StatusText = ...
        sprintf('%s. %s%s%s%s%s',...
        Text,...
        getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g %s %0.3gi',real(P),Sign,abs(Y)))), ...
        blanks(5), ...
        getString(message('Control:compDesignTask:lblDamping',sprintf('%0.3g',Zeta))), ...
        blanks(5),...
        getString(message('Control:compDesignTask:lblNaturalFrequency',sprintf('%0.3g',Wn),FreqUnits)));
else
    StatusText = sprintf('%s. %s',Text,...
        getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g',real(P)))));
end
end