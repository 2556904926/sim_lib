classdef SnapshotTimeModifier < handle
    %SNAPSHOTTIMEMODIFIER
    % Author(s): Baljeet Singh 27-Nov-2013

    % Copyright 2013 The MathWorks, Inc.
    
    
    properties (Dependent = true, SetObservable = true, AbortSet)
        Position
    end
    properties (Access = private)
        hPlot
        Figure
        AxesHandle
        Position_
        Line
        Dot
        Listeners
    end
    properties (Dependent = true, Access = private)
        Y0
    end
    methods
        function this = SnapshotTimeModifier(hplot, pos)
            %SNAPSHOTTIMEMODIFIER
            this.hPlot = hplot;
            axhandle = hplot.AxesGrid.getaxes; axhandle = axhandle(1);
            this.AxesHandle = axhandle;
            this.Figure = get(axhandle, 'Parent');
            hgg = hggroup('Parent',this.AxesHandle, 'DisplayName','Snapshot Time','Tag','linecontrol');
            hAnnotation = get(hgg,'Annotation');
            hLegendEntry = get(hAnnotation,'LegendInformation');
            set(hLegendEntry,'IconDisplayStyle','on');
            this.Dot = handle(line(NaN, NaN, 2, ...
                'Color', [255 25 0]/255, ...
                'Linewidth', 2,...
                'Linestyle', '-',...
                'Marker', 's',...
                'Parent', hgg,...
                'HitTest', 'off'));
            this.Line = handle(line(NaN, NaN, 1, ...
                'Color', [232 121 0]/255, ...
                'Linewidth', 2,...
                'Linestyle', '-',...
                'Parent', hgg,...
                'HitTest', 'off'));
            if nargin == 2
                this.Position = pos;
            else
                this.Position = mean(get(axhandle, 'XLim'));
            end
            this.attachFigureMouseCallbacks();
            this.Listeners = handle.listener(hplot.AxesGrid,'PostLimitChanged',@this.updateYLims);
        end
        %========================================================================================================(x-position)
        function set.Position(this, val)
            %SET_POSITION
            xlim = get(this.AxesHandle, 'XLim');
            if val < xlim(1) || val > xlim(2)
                return;
            end
            this.Position_ = val;
            this.updateView();
        end
        function val = get.Position(this)
            %GET_POSITION
            val = this.Position_;
        end
        %==================================================================================================(Dot's y-position)
        function val = get.Y0(this)
            %GET_Y0
            ty = this.hPlot.Waves.DataSrc.IOData.Data.Output;
            try
                val = interp1(ty.Time, ty.Data, this.Position_);
            catch
                val = NaN;
            end
        end
        %==============================================================================================================(View)
        function updateView(this)
            %UPDATEVIEW
            ylim = get(this.AxesHandle,'YLim');
            set(this.Line, 'XData' ,[this.Position this.Position], 'YData', [ylim(1) ylim(2)], 'ZData',[1 1]);
            set(this.Dot, 'XData' ,[this.Position this.Position], 'YData', [this.Y0 this.Y0], 'ZData',[2 2]);
        end
        function updateYLims(this,~,~)
            %UPDATEYLIMS
            ylim = get(this.AxesHandle,'YLim');
            set(this.Line,'YData', [ylim(1) ylim(2)]);
            set(this.Dot,'YData', [this.Y0 this.Y0]);
        end
        %===================================================================================================(Mouse Callbacks)
        function attachFigureMouseCallbacks(this)
            %ATTACHFIGUREMOUSECALLBACKS
            fig = this.Figure;
            set(fig,'WindowButtonDownFcn',...
                {@pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier.windowButtonDownFcn, this});
            set(fig,'WindowButtonMotionFcn',...
                {@pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier.defaultButtonMotionFcn, this});
        end
    end
    methods(Static)
        function windowButtonDownFcn(~, ~, this)
            %WINDOWBUTTONDOWNFCN
            fig = this.Figure;
            [NoHit, ~] = utSetMousePointer(fig);
            if NoHit
                set(fig,'WindowButtonUpFcn','');
            else                set(fig,'WindowButtonMotionFcn',...
                    {@pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier.mouseDragFcn,this});
                set(fig,'WindowButtonUpFcn',...
                    {@pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier.windowButtonUpFcn,this});
            end
        end
        function windowButtonUpFcn(~, ~,this)
            %WINDOWBUTTONUPFCN
            fig = this.Figure;
            utSetMousePointer(fig);
            set(fig,'WindowButtonMotionFcn',...
                {@pidtool.desktop.relinearizetool.gc.SnapshotTimeModifier.defaultButtonMotionFcn,this});
        end
        function defaultButtonMotionFcn(~, ~, this)
            %DEFAULTBUTTONMOTIONFCN
            utSetMousePointer(this.Figure);
        end
        function mouseDragFcn(~, ~,this)
            %MOUSEDRAGFCN
            ax = this.AxesHandle;
            pt = get(ax,'CurrentPoint'); val = pt(1,1:2);
            t0 = val(1);
            this.Position = t0;
        end
    end
end
function [NoHit, objtag] = utSetMousePointer(fig)
%UTSETMOUSEPOINTER
hoverobj = handle(hittest(fig));
objtype = get(hoverobj,'type');
objtag  = get(hoverobj,'tag');
NoHit = true;
if strcmpi(objtype,'hggroup')
    if any(strcmpi(objtag,{'linecontrol'}))
        setptr(fig,'closedhand');
        NoHit = false;
    else
        setptr(fig,'arrow');
    end
else
    setptr(fig,'arrow');
end
end
