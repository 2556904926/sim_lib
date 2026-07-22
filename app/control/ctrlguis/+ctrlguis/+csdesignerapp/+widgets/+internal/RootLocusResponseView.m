classdef RootLocusResponseView < ctrlguis.csdesignerapp.widgets.internal.AbstractWidget
    %MagPhase view Constructs HG object for magnitude/phase line rendering.
    
    % Copyright 2020 The MathWorks, Inc.
    properties (Access = private)
        Axes                 % ctrluis.AxesPair object
        FixedPZ              % System poles and zeros (HG objects)
        
        Origin               % Origin is always included in the root locus plot
        
        Locus                 % Response Line (HG object)
        LocusShadow           % Shadow line used for limit picking (HG object)
        
        GainListener         % Listener needed during drag
        AbsLinMag            % Needed during drag
    end
    
    methods (Access = public)
        function this = RootLocusResponseView(Parent, Data, Axes)
            % Super class constructor
            this = this@ctrlguis.csdesignerapp.widgets.internal.AbstractWidget(Parent, Data);
            
            this.Axes = Axes;
            
            % Construct response line
            constructLine(this);
        end
        
        function HG = getHG(this)
            HG = [this.Locus; this.FixedPZ];
        end
        
        function update(this)
            % Called during Parent RLEditor's update
            PlotAxes = getAxes(this.Axes);
            Style = this.Parent.LineStyle;
            
            if ~isempty(this.FixedPZ)
                for ct = 1:numel(this.FixedPZ)
                    delete(this.FixedPZ(ct));
                end
                this.FixedPZ = [];
            end
            % Clear existing plot
            clear(this);
            % Need to get context menus after the hg objects are cleared to
            % account for the case when update is called while in zoom mode
            UIC = get(PlotAxes,'uicontextmenu'); % axis ctx menu
            
            % Plot the fixed poles and zeros (Z level = 2)
            nz = length(this.Data.FixedZeros);
            np = length(this.Data.FixedPoles);
            this.FixedPZ = gobjects(nz+np,1);
            Zlevel = this.Parent.getZLevel('system');
            for ct=1:nz
                this.FixedPZ(ct) = line(real(this.Data.FixedZeros(ct)),imag(this.Data.FixedZeros(ct)),Zlevel,...
                    'XlimInclude','off','YlimInclude','off',...
                    'LineStyle','none','Marker','o','MarkerSize',5,...
                    'Parent',PlotAxes,'UIContextMenu',UIC,...
                    'HitTest','off',...
                    'HelpTopicKey','sisosystempolezero');
                controllib.plot.internal.utils.setColorProperty(this.FixedPZ(ct),...
                    "Color",Style.Color.System);
            end % for ct
            for ct=1:np,
                this.FixedPZ(nz+ct) = line(real(this.Data.FixedPoles(ct)),imag(this.Data.FixedPoles(ct)),Zlevel,...
                    'XlimInclude','off','YlimInclude','off',...
                    'LineStyle','none','Marker','x','MarkerSize',6,...
                    'Parent',PlotAxes,'UIContextMenu',UIC,...
                    'HitTest','off',...
                    'HelpTopicKey','sisosystempolezero');
                controllib.plot.internal.utils.setColorProperty(this.FixedPZ(nz+ct),...
                    "Color",Style.Color.System);
            end % for ct
            
            %---Plot the root locus
            this.Locus = gobjects(0,1);
            
            if ~isempty(this.Data.LocusGains)
                [Nline,Nroot] = size(this.Data.LocusRoots);
                for ct=Nline:-1:1
                    this.Locus(ct,1) = line(real(this.Data.LocusRoots(ct,:)),imag(this.Data.LocusRoots(ct,:)),...
                        this.Parent.getZLevel('curve',[1 Nroot]),...
                        'XlimInclude','off',...
                        'YlimInclude','off',...
                        'Parent',PlotAxes, ...
                        'UIContextMenu',UIC);
                    controllib.plot.internal.utils.setColorProperty(this.Locus(ct,1),...
                        "Color",Style.Color.Response);
                    setappdata(this.Locus(ct,1), 'Widget', this);
                end
                
            end
            
            [XFocus,YFocus] = rloclims(this.Data.LocusRoots);
            re = real(this.Data.LocusRoots(:));
            im = imag(this.Data.LocusRoots(:));
            InFocus = find(re>=XFocus(1) & re<=XFocus(2) & im>=YFocus(1) & im<=YFocus(2));
            set(this.LocusShadow,...
                'XData',re(InFocus),'YData',im(InFocus),'ZData',zeros(size(InFocus)))
            
        end
        
        function refresh(this)
            % Called during Parent BodeEditor's refresh - That is, when
            % something else other than the response view is being dragged.
            
            % Updates YData
            update(this);
        end
    end
    
    methods (Access = public)
        function start(this)
            
            switch this.Parent.EditMode
                case 'addpz'
                    Axes = getAxes(this.Axes); %#ok<*PROP>
                    setRefreshMode(this,'normal');
                    addPZ(this.Parent, Axes);
            end
            this.Parent.Preferences.setPlotUpdateEnabled(); 
        end
        
        function move(this)
        end
        
        function stop(this)
            this.Parent.Preferences.setPlotUpdateEnabled(true); 
            switch this.Parent.EditMode
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
                    HoverCursor = 'arrow';
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
        function clear(this)
            for ct = 1:length(this.Locus)
                delete(this.Locus(ct));
            end
            this.Locus = [];
            for ct = 1:length(this.Locus)
                delete(this.FixedPZ(ct));
            end
            this.FixedPZ = [];
        end
        function constructLine(this)
            % Construct all lines that are static
            
            PlotAxes = getAxes(this.Axes);
            
            % Always include origin
            this.Origin = line([-1 -1 1 1],[-1 1 -1 1], ...-Zlevel(ones(1,4)),...
                'LineStyle','none','Parent',PlotAxes,'HitTest','off');
            
            % Create shadow line specifying root locus portion to be
            % included in limit picking REVISIT: could be incorporated in
            % Locus as XlimIncludeData
            this.LocusShadow = line(NaN,NaN,...
                'Parent',PlotAxes, ...
                'LineStyle','none',...
                'HitTest','off',...
                'HandleVisibility','off');
        end
        
        function setGain(this, Gain)
            this.Data.setGain(Gain);
        end
        
        
        function updateFixedPZ(this)
            if ~isempty(this.FixedPZ)
                for ct = 1:numel(this.FixedPZ)
                    delete(this.FixedPZ(ct));
                end
                this.FixedPZ = [];
            end
            
            axes = getAxes(this.Axes);
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
                'HitTest','off'};
            for ct=length(FixedZeros):-1:1
                Z(ct,1) = line(FreqZ(ct),NaN,Zlevel,...
                    'Parent',axes(this.MagPhase),ZProps{:});
                controllib.plot.internal.utils.setColorProperty(Z(ct,1),...
                    "Color",controllib.plot.internal.utils.GraphicsColor(1).SemanticName);
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
                'HitTest','off',...
                'HelpTopicKey','sisosystempolezero'};
            for ct=length(FixedPoles):-1:1
                P(ct,1) = line(FreqP(ct),NaN,Zlevel,...
                    'Parent',axes(this.MagPhase),PProps{:});
                controllib.plot.internal.utils.setColorProperty(P(ct,1),...
                    "Color",controllib.plot.internal.utils.GraphicsColor(1).SemanticName);                
            end
            imfp = find(imag(FixedPoles)>0);
            set([P(imfp,:)],'LineWidth',2)
            this.FixedPZ = [this.FixedPZ; P];
        end
        
        function setnyqline(this,NyqFreq)
            % SETNYQLINE  Positions Nyquist line in Bode Diagrams. Expects
            % NyqFreq in Axes's XUnits
            
            if isfinite(NyqFreq)
                % Mag line RE: Update Y data to track abs vs. dB
                Zlevel = this.Parent.getZLevel('backgroundline');
                if this.MagPhase == 1
                    YData = unitconv(infline(0,Inf),'abs',this.Axes.YUnits);
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
            
            % RE: MAG and MAGI are expressed in abs units. The
            % interpolation occurs
            %     in abs or log scale depending on the mag. scale and units
            
            % Take XScale into account
            if strcmp(this.Axes.XScale,'log')
                W = log2(W);
                nz = (Wi>0);
                Wi(nz) = log2(Wi(nz));
                Wi(~nz) = -Inf;
            end
            
            % Take YScale into account
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
            %   REFRAME adjusts the (auto) axes limits to include the
            %   specified data X,Y.  The MODE string is either 'x', 'y', or
            %   'xy'.
            MovePtr = false;

            % Axes = this.Axes;
            % 
            % % Frequency axis
            % if any(Mode=='x')
            %     if strcmp(Axes.XScale,'log')
            %         ShiftX = Axes.slidelims(PlotAxes,'x','log',10,X);
            %     else
            %         ShiftX = Axes.slidelims(PlotAxes,'x','log',2,X);
            %     end
            % else
            %     ShiftX = 0;
            % end
            % 
            % % Mag or phase axes
            % if any(Mode=='y')
            %     hgaxes = getAxes(Axes);
            %     if PlotAxes==hgaxes(1)
            %         % Working in mag axes
            %         if strcmp(Axes.YUnits{1},'dB')
            %             ShiftY = Axes.slidelims(PlotAxes,'y','linear',20,Y);
            %         else
            %             ShiftY = Axes.slidelims(PlotAxes,'y','log',2,Y);
            %         end
            %     else
            %         % Working in phase axes
            %         if strcmp(Axes.YUnits{2},'deg')
            %             ShiftY = Axes.slidelims(PlotAxes,'y','linear',90,Y);
            %             if ShiftY
            %                 PlotAxes.YTickMode = 'auto';
            %                 PlotAxes.YTick = phaseticks(PlotAxes.YTick,PlotAxes.YLim);
            %             end
            %         else
            %             ShiftY = Axes.slidelims(PlotAxes,'y','linear',pi/2,Y); %#ok<*PROPLC>
            %         end
            %     end
            % else
            %     ShiftY = 0;
            % end
            % 
            % MovePtr = ShiftX || ShiftY;
            % if MovePtr
            %     % Notify peers of limit change
            %     Axes.send('PostLimitChanged')
            % end
            
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
            X = get(Handles,{'Xdata'});
            Y = utInterp1(FreqData,Data,cat(1,X{:}));
            for ct=1:length(Handles)
                set(Handles(ct),'Ydata',Y(ct))
            end

        end
    end
end
