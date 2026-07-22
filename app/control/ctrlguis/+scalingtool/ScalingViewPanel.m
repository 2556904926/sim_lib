classdef ScalingViewPanel < handle
    % @ScalingViewPanel class definition

    %   Author(s): P. Gahinet, C. Buhr
    %   Copyright 1986-2014 The MathWorks, Inc.
    properties (SetObservable = true)
        System
        PlotFocus = []; % empty is auto
        PlotFocusMode = 'auto';
        ScaleFocus = []; % empty is auto
        ScaleFocusMode = 'auto';
        Parent
        HG
        AxesXLimListener
        LinkXLim
    end

    methods

        function this = ScalingViewPanel(Parent)
            % Constructor
            this.Parent = Parent;
            % Build GUI components
            build(this)

            % Lay things out
            layout(this)

            %
            this.LinkXLim = linkprop(this.HG.Axes,'XLim');
            ax = handle(this.HG.Axes(1));
            weakThis = matlab.lang.WeakReference(this);
            this.AxesXLimListener = addlistener(ax,'XLim',...
                'PostSet',@(x,y) localUpdatePlotFocus(weakThis.Handle));

        end

        function setPlotFocus(this,NewPlotFocus,modeflag)
            if nargin == 2
                modeflag = true;
            end
            % Revisit Validate
            this.PlotFocus = NewPlotFocus;
            if modeflag
                this.PlotFocusMode = 'manual';
            end
            update(this);
        end

        function setPlotFocusMode(this,NewPlotFocusMode)
            % Revisit Validate
            this.PlotFocusMode = NewPlotFocusMode;
            update(this);
        end
        
        function Value = getPlotFocus(this)
            Value = this.PlotFocus;
        end
        
        function Value = getPlotFocusMode(this)
            Value = this.PlotFocusMode;
        end
        
        function setScaleFocus(this,NewScaleFocus)
            % Revisit Validate
            this.ScaleFocus = NewScaleFocus;
            if ~isempty(NewScaleFocus)
                this.ScaleFocusMode = 'manual';
            else
                this.ScaleFocusMode = 'auto';
            end
            update(this);
        end
        
        function setScaleFocusMode(this,NewScaleFocusMode)
            % Revisit Validate
            this.ScaleFocusMode = NewScaleFocusMode;
            if strcmp(NewScaleFocusMode,'auto')
                this.ScaleFocus = [];
            end 
            update(this);
        end
        
        function Value = getScaleFocus(this)
            Value = this.ScaleFocus;
        end
        
        function Value = getScaleFocusMode(this)
            Value = this.ScaleFocusMode;
        end

        function setSystem(this,Target,ScaleFocus)
            % Revisit check on setting this.System to a single model
            if nargin > 2 && ~isempty(ScaleFocus)
                this.ScaleFocus = ScaleFocus;
                this.ScaleFocusMode = 'manual';
            else
                this.ScaleFocus = [];
            end
            this.PlotFocus = [];
            this.System = Target;
            update(this)

        end


        function update(this)
           %Revisit case where system is not a SS model
           % Update plot content
           sys = this.System;
           if isempty(this.System)
              return;
           end
           
           % Original realization
           [a0,b0,c0,d0,~,Ts] = dssdata(sys);
           e0 = sys.e;
           
           % Scaled realization
           if strcmpi(this.ScaleFocusMode,'auto') || isempty(this.ScaleFocus)
              [a,b,c,e] = ltipack.xscale(a0,b0,c0,d0,e0,Ts,'Focus',[],'Warn',false);
           else
              [a,b,c,e] = ltipack.xscale(a0,b0,c0,d0,e0,Ts,'Focus',this.ScaleFocus,'Warn',false);
           end
           ScaledSys = ss(a,b,c,d0,Ts,'e',e,'Scaled',true);
           
           % Peak gain response
           if strcmpi(this.PlotFocusMode,'auto') || isempty(this.PlotFocus)
              [sv,w] = sigma(ScaledSys);
           else
              [sv,w] = sigma(ScaledSys,{this.PlotFocus(1) this.PlotFocus(2)});
           end
           % Drop negative frequencies (XSCALE can't handle systems with complex coefficients)
           ixp = find(w>0);
           w = w(ixp,:);  sv = sv(:,ixp);
           this.PlotFocus = [w(1),w(end)];
           
           
           % Compute accuracy before and after scaling
           RelAcc0 = eps * ltipack.util.frsens(a0,b0,c0,d0,e0,Ts,w,'safe');
           RelAcc = eps * ltipack.util.frsens(a,b,c,d0,e,Ts,w);
           
           % Compute optimal sensitivity to orthogonal transformation at each freq
           wopt = logspace(log10(w(1)),log10(w(end)),30);
           RelAccOpt = eps * ltipack.util.frsens(a0,b0,c0,d0,e0,Ts,wopt,'min');
           
           if isobject(this.AxesXLimListener)
              this.AxesXLimListener.Enabled = false;
           else
              this.AxesXLimListener.Enabled = 'off';
           end
           % Plot singular value data
           Axes = this.HG.Axes;
           cla(Axes(1));
           line('Parent',Axes(1),'Xdata',w,'Ydata',20*log10(sv(1,:)),'LineWidth',2,...
               'SeriesIndex',1);
           set(Axes(1),'XLim',[w(1),w(end)],'YLimMode','auto');
           
           % Plot relative accuracy
           cla(Axes(2));
           line('Parent',Axes(2),'Xdata',w,'Ydata',RelAcc0,...
              'SeriesIndex',2,'LineStyle','--','LineWidth',2,...
              'DisplayName',ctrlMsgUtils.message('Control:scalegui:strOriginal'));
           line('Parent',Axes(2),'Xdata',w,'Ydata',RelAcc,...
              'SeriesIndex',1,'LineWidth',2,'DisplayName',ctrlMsgUtils.message('Control:scalegui:strScaled'));
           hline = line('Parent',Axes(2),'Xdata',wopt,'Ydata',RelAccOpt,...
              'LineStyle','--','LineStyle','--','LineWidth',2,...
              'DisplayName',ctrlMsgUtils.message('Control:scalegui:strPointwiseOptimal'));
           controllib.plot.internal.utils.setColorProperty(hline,'Color',...
               controllib.plot.internal.utils.GraphicsColor(2,"quaternary").SemanticName);
           
           set(Axes(2),'XLim',[w(1),w(end)],'YLimMode','auto');
           
           if isobject(this.AxesXLimListener)
              this.AxesXLimListener.Enabled = true;
           else
              this.AxesXLimListener.Enabled = 'on';
           end
           lh = legend(Axes(2),'show');
           scalingtool.PreScaleTool.setLegendContextMenu(lh);
        end


        function layout(this)
            % Lays GUI components out
            HGvar = this.HG;
            p = get(HGvar.Panel,'Position');
            fw = p(3);  fh = p(4);
            vBorder = .5; 
            
            % Position axes
            y0 = vBorder;  yh = fh-y0;   axh = 0.5*yh;
            x0 = 1;
            set(HGvar.Axes(2),'OuterPosition',[1 y0 max(fw-x0,1) axh+1]);
            y0 = y0 + axh+1;
            set(HGvar.Axes(1),'OuterPosition',[1 y0 max(fw-x0,1) max(yh-axh-1,1)]);
            
            % Ensure axes boundaries line up for comparison
            p1 = get(HGvar.Axes(1),'Position');
            p2 = get(HGvar.Axes(2),'Position');          
            x0 = max(p1(1),p2(1));
            w0 = min(p1(3),p2(3));
            if w0 > 0
                % Prevent trying to set non-positive value for width or height
                set(HGvar.Axes(1),'Position',[x0, p1(2), w0, p1(4)]);
                set(HGvar.Axes(2),'Position',[x0, p2(2), w0, p2(4)]);
            end
        end


        function close(this)
            delete(this.Parent)
            delete(this)
        end

    end


    methods (Access = private)
        function build(this)
            % Builds GUI
            Panel = uipanel('Parent',this.Parent);
            HGvar.Panel = Panel;
            set(Panel,'units','character')

            % Set Font Size
            FontSize = 9;
            
            % Axes
            ax1 = axes('Parent',Panel,'FontSize',FontSize,...
                'XGrid','on','Ygrid','on','Xscale','log','Yscale','linear');
            set(ax1,'Units','characters');
            set(get(ax1,'Ylabel'),'String', ...
                ctrlMsgUtils.message('Control:scalegui:MagLabel'), ...
                'Fontsize',FontSize)
            set(get(ax1,'Title'),'String', ...
                ctrlMsgUtils.message('Control:scalegui:FreqRespGainLabel'),...
                'Fontsize',FontSize,'FontWeight','bold')
            ax2 = axes('Parent',Panel,'FontSize',FontSize,...
                'XGrid','on','Ygrid','on','Xscale','log','Yscale','log');
            set(ax2,'Units','characters');
            set(get(ax2,'Xlabel'),'String',...
                ctrlMsgUtils.message('Control:scalegui:FreqLabel'),'Fontsize',FontSize)
            set(get(ax2,'Ylabel'),'String', ...
                ctrlMsgUtils.message('Control:scalegui:RelAccuracyLabel'),'Fontsize',FontSize)
            set(get(ax2,'Title'),'String', ...
                ctrlMsgUtils.message('Control:scalegui:FreqRespAccuracyLabel'),...
                'Fontsize',FontSize,'FontWeight','bold')
            HGvar.Axes = [ax1 ax2];

            this.HG = HGvar;
        end
    end
end


function localUpdatePlotFocus(this)
this.PlotFocus = get(this.HG.Axes(1),'Xlim');
this.PlotFocusMode = 'manual';
end
