classdef RootLocusPZView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    % Copyright 2020 The MathWorks, Inc.
    properties (Access = private)
        %% Data
        Axes
        PZGroup              % Compensator being modified
        
        %% HG handles
        Line                 % Line handles for poles and zeros
        
        %% Data needed for drag
        AutoScaleOn
        iLocusGains
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
        Listeners
    end
    
    methods (Access = public)
        function this = RootLocusPZView(Parent, Data, Axes,PZGroup)
            
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            this.PZGroup = PZGroup;
            
            constructPZLines(this);
        end
        
        function HG = getHG(this)
            HG = [this.Line.Zero(:); this.Line.Pole(:)];
        end
        
        function HG = getHG_PZ(this)
            % Serialized getPZ method to return all compensator poles and
            % zeros - called by Parent
            HG = [];
            for ct = 1:numel(this)
                HG = [HG; this(ct).Line.Zero(:); this(ct).Line.Pole(:)];
            end
        end
        
        function update(this)
            % update only if visible
            Ax = getAxes(this.Axes);
            if strcmp(Ax.Visible, 'on')
                % Delete existing line handles
                delete(this.Line.Pole);
                delete(this.Line.Zero);
                % Reconstruct
                constructPZLines(this);
                % Refresh
                refresh(this);
            end
        end
        
        function refresh(this)
            % Update tuned pole/zero location
            ZData = this.Parent.getZLevel('compensator');
            
            if ~isempty(this.PZGroup.Zero)
                for ct = 1:length(this.PZGroup.Zero)
                    set(this.Line.Zero(ct),'XData', real(this.PZGroup.Zero(ct)), 'YData', imag(this.PZGroup.Zero(ct)), 'ZData', ZData);
                end
            end
            if ~isempty(this.PZGroup.Pole)
                for ct = 1:length(this.PZGroup.Pole)
                set(this.Line.Pole(ct),'XData', real(this.PZGroup.Pole(ct)), 'YData', imag(this.PZGroup.Pole(ct)), 'ZData', ZData);
                end
            end
            
            % Update multimodel data
            if ~isempty(this.Parent.UncertainBounds) & this.Data.isUncertain && this.Parent.isMultiModelVisible
                CLPolesa = [];
                for ct = 1:length(this.Data.UncertainData)
                    CLPolesa = [CLPolesa;rlocus(this.Data.getOpenLoop(ct),getGain(this.Data))];
                end
                this.Data.UncertainCLPoles = CLPolesa;
                this.Parent.UncertainBounds.setData(CLPolesa);
            end
        end
        
        function setPZGroup(this, PZGroup)
            this.PZGroup = PZGroup;
            if ~isempty(this.Line.Pole)
                for ct = 1:numel(this.Line.Pole)
                    setappdata(this.Line.Pole(ct),'PZGroup',PZGroup);
                end
            end
            if ~isempty(this.Line.Zero)
                for ct = 1:numel(this.Line.Zero)
                    setappdata(this.Line.Zero(ct),'PZGroup',PZGroup);
                end
            end
        end
                  
        function addlistener(this)
            this.Listeners = addlistener(this.Data.EditedBlock, 'GainChanged', @(es,ed)refresh(this));
        end
        
        function delete(this)
            delete(this.Line.Pole);
            delete(this.Line.Zero);
        end
    end
    
    methods (Access = public)
        function start(this)           
            switch this.Parent.EditMode
                case 'idle'
                    setRefreshMode(this, 'quick');
                    enableDataListeners(this.Data, false);
                    setEditedBlock(this.Data, this.PZGroup.Parent);
                    FreqUnits = this.Parent.Preferences.FrequencyUnits;
                    refresh(this.Parent,'start',this);
                    
                    Axes = getAxes(this.Axes); %#ok<*PROP>
                    this.MovedPZID = LocalGetSelection(gcbo);
                    
                    this.Transaction = controllib.app.managers.eventmanager.internal.FunctionTransaction( ...
                        getString(message('Control:compDesignTask:strMovePZ',this.MovedPZID)));
                    
                    % Set undo function
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.UndoFcn = {@loadSession this.Data.EditedBlock S};
                    
                    AutoScaleX = strcmp(this.Axes.XLimitsMode{1},'auto');
                    AutoScaleY = strcmp(this.Axes.YLimitsMode{1},'auto');
                    
                    this.AutoScaleOn = AutoScaleX || AutoScaleY;
                    if  this.AutoScaleOn
                        moveptr(Axes,'init');
                    end
                    
                    nGains = 25;  % Number of gain values while dragging
                    MinGain = log10(this.Data.LocusGains(2));
                    MaxGain = log10(this.Data.LocusGains(end-2));
                    this.iLocusGains = [this.Data.LocusGains(1) , ...
                        logspace(MinGain,max(MinGain+1,MaxGain),nGains) , ...
                        this.Data.LocusGains(end-1:end)];
        
                    this.Listeners = addlistener(this.PZGroup,'PZDataChanged',...
                        @(es,ed)redrawPlot(this));
                    
%                     Str = LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,FreqUnits);
                    
%                     this.Parent.EventManager.postActionStatus('off',Str);
                    setptr(getHGParent(this.Parent),'closedhand');
                case 'addpz'
                    PlotAxes = getAxes(this.Axes);
                    addPZ(this.Parent, PlotAxes);
            end
            this.Parent.Preferences.setPlotUpdateEnabled();
        end
        
        function move(this)
            switch this.Parent.EditMode
                case 'idle'
                    try
                        Ax = getAxes(this.Axes); %#ok<*PROP>
                        CP = get(Ax,'CurrentPoint');
                        
                        % Get current value
                        curval = this.PZGroup.getValue(1);
                        
                        % Update data of moved PZGROUP
                        NewLoc = this.movepz(this.PZGroup,this.MovedPZID,CP(1,1),CP(1,2),this.Data.Ts);                        
                    catch ME %#ok<NASGU>
                        % Update Failed revert back to previous value
                        this.PZGroup.setValue(curval,1)
                    end
                    
                    notify(this.PZGroup, 'PZDataChanged');
                    notifyValueChanged(this.Data.EditedBlock)
                    % Track root location in status bar
                    this.Parent.EventManager.postActionStatus('off',LocalTrackStatus(this.PZGroup,this.MovedPZID,this.Data.Ts,CP(1,2),this.Parent.Preferences.FrequencyUnits));
                    
                    % Adjust axis limits if dragged pole/zero gets out of focus
                    MovePtr = this.reframe(Ax,'xy',CP(1,1),CP(1,2));
                    if MovePtr
                        % Reposition mouse pointer
                        moveptr(Ax,'move',real(NewLoc(1)),imag(NewLoc(1)));
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
                    % Record transaction
                    % Set redo function
                    S = saveSession(this.Data.EditedBlock);
                    this.Transaction.RedoFcn = {@loadSession this.Data.EditedBlock S};
                    
                    this.Parent.EventManager.record(this.Transaction);
                    
                    
                    setptr(getHGParent(this.Parent),'hand');
                    delete(this.Listeners);
                    this.Listeners = [];
                    
                    Str = this.PZGroup.movelog(this.MovedPZID,this.Data.Ts);
                    this.Parent.EventManager.postActionStatus('off',sprintf('%s %s',Str, ...
                        getString(message('Control:compDesignTask:msgRightClickForDesignOptions'))));
                    update(this.Parent);
                    % this.Axes.send('ViewChanged');
                case 'deletepz'
                    %DELETEPZ  Deletes pole or zero graphically.
                    
                    PlotAxes = getAxes(this.Axes);
                    
                    % Acquire pole/zero position
                    CP = get(PlotAxes,'CurrentPoint');
                    
                    Lims = get(PlotAxes,{'Xlim','Ylim'});  % axis extent
                    Xscale = Lims{1}(2)-Lims{1}(1);
                    Yscale = Lims{2}(2)-Lims{2}(1);
                    
                    % Get positions of all compensator poles and zeros for
                    % the compensator
                    hPZ = getHG_PZ(this.Parent);
                   

                    X = get(hPZ,{'Xdata'});  X = cat(2,X{:})';
                    Y = get(hPZ,{'Ydata'});  Y = cat(2,Y{:})';
                    
                    % Determine nearest match
                    [distmin,imin] = ...
                        min(abs(((CP(1,1)-X)/Xscale).^2 + ((CP(1,2)-Y)/Yscale).^2));
                    
                    if distmin < 0.03^2
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
                    end
            end
            
        end
    end
    
    methods (Access = private)
        function constructPZLines(this)
            Ax = getAxes(this.Axes);
            Style = this.Parent.LineStyle;
            Zeros = this.PZGroup.Zero;   % zero values
            if ~isempty(Zeros)
                ZProps = {...
                    'LineStyle','none',...
                    'LineWidth',0.75,...
                    'Marker','o','MarkerSize',6};
                for ct = 1:length(Zeros)
                    hZ(ct) = line(NaN,NaN,NaN,...
                        'Parent',Ax,'Visible','on',...
                        ZProps{:});
                    setappdata(hZ(ct),'PZGroup',this.PZGroup);
                    setappdata(hZ(ct),'Widget', this);

                    controllib.plot.internal.utils.setColorProperty(hZ(ct),...
                        "Color",Style.Color.Compensator);
                end
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
                for ct = 1:length(Poles)
                    hP(ct) = line(NaN,NaN,NaN,...
                        'Parent',Ax,'Visible','on',...
                        PProps{:});
                    setappdata(hP(ct),'PZGroup',this.PZGroup);
                    setappdata(hP(ct),'Widget', this);

                    controllib.plot.internal.utils.setColorProperty(hP(ct),...
                        "Color",Style.Color.Compensator);
                end
            else
                hP = zeros(0,1);
            end
            this.Line.Pole = hP;
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
            if strcmp(this.Axes.XScale,'log')
                W = log2(W);
                nz = (Wi>0);
                Wi(nz) = log2(Wi(nz));
                Wi(~nz) = -Inf;
            end
            
            if strcmp(this.Axes.YUnits,'abs') && ...
                    strcmp(this.Axes.YScale,'linear')
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
            MovePtr = false;
            %   Copyright 1986-2003 The MathWorks, Inc.
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
            % Revisit: Change to gasin target block
            Ctb = this.Data.EditedBlock;
            OL = getOpenLoop(this.Data);  % normalized open-loop
            if ~isfinite(OL)
                return
            end
            CurrentGain = getZPKGain(Ctb,'mag');
                     
            % Use pade to approximate delays compute delays
            OL = this.Data.utApproxDelay(OL);
            
            % Update locus data and closed-loop locations
            % RE: Use 'refine' flag to include branch crossing gains
            %     for increased smoothness
            [Roots,Gains] = rlocus(OL,[this.iLocusGains,CurrentGain],'refine');
            this.Data.LocusRoots  = Roots;
            this.Data.ClosedPoles = Roots(:,Gains==CurrentGain);
            this.Data.LocusGains  = Gains;
            
            refresh(this);
            refresh(this.Parent, 'move');
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
            if Ts
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
        

        
        function NewLoc = movepz(~,PZGroup,PZID,X,Y,Ts)
            %MOVEPZ  Updates pole/zero group to track mouse location (X,Y) in editor axes.
            
            %   Author(s): P. Gahinet
            %   Copyright 1986-2002 The MathWorks, Inc.
            
            switch PZGroup.Type
                case 'Real'
                    % Real pole/zero
                    PZGroup.(PZID) = X;
                    NewLoc = X;
                    
                case 'Complex'
                    % Complex pole/zero
                    PZGroup.(PZID) = [X + 1i * abs(Y) ; X - 1i * abs(Y)];
                    NewLoc = X + 1i * Y;
                    
                case 'LeadLag'
                    % Lead or lag network (s+tau1)/(s+tau2)
                    % Maintain stability
                    if Ts
                        X = X/max(1,abs(X));
                    else
                        X = min(0,X);
                    end
                    PZGroup.(PZID) = X;
                    NewLoc = X;
                    
                case 'Notch'
                    % Notch filter. If R1 is the dragged root, the other root R2 moves
                    % on a constant damping ray and |R2| tracks |R1|.
                    r1 = X + 1i * Y;
                    [Wn,z1] = damp(r1,Ts);  % new natural freq and damping of moved root
                    
                    % Determine new value of the other root
                    % RE: Enforce damping constraint |Zeta_zero/Zeta_pole|<=1
                    if strcmp(PZID,'Pole')
                        % Moving a pole: impose |z2/z1|<=1
                        [~,z2] = damp(PZGroup.Zero(1),Ts);  % current damping of other root
                        z2 = sign(z2) * min(abs(z2),abs(z1));
                        PZIDc = 'Zero';
                    else
                        % Moving a zero: impose |z1/z2|<=1
                        [~,z2] = damp(PZGroup.Pole(1),Ts);  % current damping of other root
                        z2 = sign(z2) * max(abs(z2),abs(z1));
                        PZIDc = 'Pole';
                    end
                    r2 = Wn * (-z2 + 1i * sqrt(1-z2^2));
                    if Ts
                        r2 = exp(r2*Ts);
                    end
                    
                    % Update group data
                    PZGroup.(PZID) = real(r1)+[1i;-1i]*abs(imag(r1));
                    PZGroup.(PZIDc) = real(r2)+[1i;-1i]*abs(imag(r2));
                    
                    NewLoc = [r1 ; r2];
                    
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

%----------------- Local functions -----------------

%%%%%%%%%%%%%%%%%%%%%
% LocalGetSelection %
%%%%%%%%%%%%%%%%%%%%%
function [PZID,Y] = LocalGetSelection(CurrentObj)
% Identifies selected PZGROUP object (pole/zero group)

% Moved PZVIEW object
MovedPZVIEW = getappdata(CurrentObj,'Widget');
if any(MovedPZVIEW.Line.Zero==CurrentObj)
   PZID = 'Zero';
else
   PZID = 'Pole';
end

% Moved PZGROUP
Y = get(CurrentObj,'Ydata');

end

%%%%%%%%%%%%%%%%%%%%
% LocalTrackStatus %
%%%%%%%%%%%%%%%%%%%%
function Status = LocalTrackStatus(Group,PZID,Ts,Y,FreqUnits)
% Display info about moved pole/zero

% Defs
Spacing = blanks(5);

switch Group.Type
case 'Notch'
   % Custom display for notch filters
   if strcmpi(PZID,'pole')
       Text = getString(message('Control:compDesignTask:msgShapeNotch4'));
   else
       Text = getString(message('Control:compDesignTask:msgShapeNotch5'));
   end
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
   if Y>=0
      R = R(1); Sign = '+';
   else
      R = R(2); Sign = '-';
   end
   [Wn,Zeta] = damp(R,Ts);
   Wn = Wn*funitconv('rad/s',FreqUnits);
   Status = ...
       sprintf('%s. %s%s%s%s%s',...
       Text, ...
       getString(message('Control:compDesignTask:lblCurrentLocation',sprintf('%0.3g %s %0.3gi',real(R),Sign,abs(imag(R))))), ...
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
   R = Group.(PZID);
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


