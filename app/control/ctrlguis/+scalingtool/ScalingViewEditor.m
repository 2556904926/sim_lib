classdef ScalingViewEditor < handle
    % @ScalingViewEditor class definition

    %   Copyright 1986-2011 The MathWorks, Inc.
    properties
        ScalingView
        HG
    end
    
    properties (Access = protected)
        Parent
    end

    methods
        %%
        function this = ScalingViewEditor(ScalingView,Parent)
            if nargin == 0
                return;
            end
            
            % Constructor
            this.Parent = Parent;
            this.ScalingView = ScalingView;
            % Build GUI components
            build(this)
            % Lay things out
            layout(this)
            addScalingViewListeners(this)
            this.refreshPlotFocus;
            this.refreshScaleFocus;
        end




        %%
        function refreshPlotFocus(this)
            PlotFocus = this.ScalingView.getPlotFocus;
            PlotFocusMode = this.ScalingView.getPlotFocusMode;

            set(this.HG.BottomCheckBox,'Value',double(strcmpi(PlotFocusMode,'auto')));

            if isempty(PlotFocus);
                set(this.HG.BottomEdit(1),'String','');
                set(this.HG.BottomEdit(2),'String','');
            else
                set(this.HG.BottomEdit(1),'String',num2str(PlotFocus(1)));
                set(this.HG.BottomEdit(2),'String',num2str(PlotFocus(2)));
            end
        end
        %


        %%
        function refreshScaleFocus(this)
            ScaleFocus = this.ScalingView.getScaleFocus;
            ScaleFocusMode = this.ScalingView.getScaleFocusMode;

            set(this.HG.TopCheckBox,'Value',double(strcmpi(ScaleFocusMode,'auto')));

            if isempty(ScaleFocus);
                set(this.HG.TopEdit(1),'String','');
                set(this.HG.TopEdit(2),'String','');
            else
                set(this.HG.TopEdit(1),'String',num2str(ScaleFocus(1)));
                set(this.HG.TopEdit(2),'String',num2str(ScaleFocus(2)));
            end

        end



        %%
        function update(this)
            %Revisit case where system is not a SS model
            % Update Editor
        end



        %%
        function layout(this)
            % Lays GUI components out
            HG = this.HG;
            p = get(HG.Panel,'Position');
            fw = p(3);  fh = p(4);
            hBorder = 2; vBorder = .5;
            bh = 1.75;
            
            % Branched layout to address g738657
            if ismac
                th = 2;
            else
                th = 1.5;
            end


            % Position text and edit boxes
            bw = 16;
            y0 = vBorder;
            HBE = get(HG.Help,'Extent');
            HBW = max(HBE(3)+2,bw);
            set(HG.Help,'Position',[fw-HBW-1.5*hBorder y0 HBW bh])
            CBE = get(HG.Close,'Extent');
            CBW = max(CBE(3)+2,bw);
            set(HG.Close,'Position',[fw-(HBW+CBW)-2*hBorder y0 CBW bh])
            SBE = get(HG.Save,'Extent');
            SBW = max(SBE(3)+2,bw);
            set(HG.Save,'Position',[fw-(HBW+CBW+SBW)-2.5*hBorder y0 SBW bh])
            
            y0 = y0+2.25;
            set(HG.BottomText(1),'Position',[4 y0-.25 44 th])
            set(HG.BottomEdit(1),'Position',[48 y0 15 th])
            set(HG.BottomText(2),'Position',[63 y0-.25 5 th])
            set(HG.BottomEdit(2),'Position',[68 y0 15 th])
            set(HG.BottomCheckBox,'Position',[85 y0 15 th])

            y0 = y0+2.25;
            set(HG.TopText(1),'Position',[4 y0-.25 44 th])
            set(HG.TopEdit(1),'Position',[48 y0 15 th])
            set(HG.TopText(2),'Position',[63 y0-.25 5 th])
            set(HG.TopEdit(2),'Position',[68 y0 15 th])
            set(HG.TopCheckBox,'Position',[85 y0 15 th])
            %
        end

        %%
        function close(this)
            delete(this.Panel)
            delete(this)
        end

    end


    methods (Access = protected)
        %%
        function addScalingViewListeners(this)
            weakThis = matlab.lang.WeakReference(this);
            L1 = addlistener(this.ScalingView,'ScaleFocus','PostSet',@(x,y) refreshScaleFocus(weakThis.Handle));
            L2 = addlistener(this.ScalingView,'ScaleFocusMode','PostSet',@(x,y) refreshScaleFocus(weakThis.Handle));
            L3 = addlistener(this.ScalingView,'PlotFocus','PostSet',@(x,y) refreshPlotFocus(weakThis.Handle));
            L4 = addlistener(this.ScalingView,'PlotFocusMode','PostSet',@(x,y) refreshPlotFocus(weakThis.Handle));
        end
        
        %%
        function readFocus(this)
            % Reads settings from edit boxes
            HG = this.HG;
            % XSCALE focus
            strmin = strtrim(get(HG.TopEdit(1),'String'));
            strmax = strtrim(get(HG.TopEdit(2),'String'));
            if isempty(strmin) || isempty(strmax)
                this.ScaleFocus = [];
                set(HG.TopEdit,'String','','UserData','');
            else
                this.ScaleFocus = [str2double(strmin),str2double(strmax)];
            end
            % Plot focus
            strmin = strtrim(get(HG.BottomEdit(1),'String'));
            strmax = strtrim(get(HG.BottomEdit(2),'String'));
            
            if isempty(strmin) || isempty(strmax)
                this.PlotFocus = [];
                set(HG.BottomEdit,'String','','UserData','');
            else
                this.PlotFocus = [str2double(strmin),str2double(strmax)];
            end
        end


        %%
        function build(this)
            % Builds GUI
            HG = struct;
            Panel = uipanel('Parent',this.Parent);
            HG.Panel = Panel;
            set(Panel,'units','character')

            % Select frequency range where to maximize accuracy
            HG.TopText(1) = uicontrol(...
                'Parent',Panel,...
                'Style','text',...
                'HorizontalAlignment','left', ...
                'Units','character', ...
                'String', ...
                ctrlMsgUtils.message('Control:scalegui:ScaleFocusRangeLabel'));
            HG.TopText(2) = uicontrol(...
                'Parent',Panel,...
                'HorizontalAlignment','center', ...
                'Style','text',...
                'Units','character', ...
                'String',ctrlMsgUtils.message('Control:scalegui:strto'));
            HG.TopEdit(1) = uicontrol(...
                'Parent',Panel,...
                'Style','edit',...
                'Units','character');
            HG.TopEdit(2) = uicontrol(...
                'Parent',Panel,...
                'Style','edit',...
                'Units','character');
            HG.TopCheckBox = uicontrol(...
                'Parent',Panel,...
                'Style','CheckBox',...
                'String', ctrlMsgUtils.message('Control:scalegui:strAuto'),...
                'Units','character','UserData','');
            
            
            ScaleFocus = this.ScalingView.getScaleFocus;
            if isempty(ScaleFocus)
                str1 = '';  str2 = '';
            else
                str1 = num2str(ScaleFocus(1),'%.3g');
                str2 = num2str(ScaleFocus(2),'%.3g');
            end
            set(HG.TopCheckBox,'Callback',@(x,y) localUpdateScaleFocusMode(this))
            set(HG.TopEdit(1),'String',str1,'UserData',str1,...
                'Callback',@(x,y) localUpdateScaleFocus(this))
            set(HG.TopEdit(2),'String',str2,'UserData',str2,...
                'Callback',@(x,y) localUpdateScaleFocus(this))

            % Select frequency band to show in plots
            HG.BottomText(1) = uicontrol(...
                'Parent',Panel,...
                'Style','text',...
                'HorizontalAlignment','left', ...
                'Units','character', ...
                'String',...
                ctrlMsgUtils.message('Control:scalegui:PlotFocusRangeLabel'));
            HG.BottomText(2) = uicontrol(...
                'Parent',Panel,...
                'HorizontalAlignment','center', ...
                'Style','text',...
                'Units','character', ...
                'String',ctrlMsgUtils.message('Control:scalegui:strto'));
            HG.BottomEdit(1) = uicontrol(...
                'Parent',Panel,...
                'Style','edit',...
                'Units','character','UserData','');
            HG.BottomEdit(2) = uicontrol(...
                'Parent',Panel,...
                'Style','edit',...
                'Units','character','UserData','');
            
            HG.BottomCheckBox = uicontrol(...
                'Parent',Panel,...
                'Style','CheckBox',...
                'String', ctrlMsgUtils.message('Control:scalegui:strAuto'),...
                'Units','character','UserData','');
            set(HG.BottomCheckBox,'Callback',@(x,y) localUpdatePlotFocusMode(this))
            set(HG.BottomEdit(1),'Callback',@(x,y) localUpdatePlotFocus(this))
            set(HG.BottomEdit(2),'Callback',@(x,y) localUpdatePlotFocus(this))
            %
            % Save and reset buttons
            HG.Close = uicontrol(...
                'Parent',Panel,...
                'Style','pushbutton',...
                'Units','character', ...
                'String',ctrlMsgUtils.message('Control:scalegui:strClose'),...
                'Callback','');
            HG.Save = uicontrol(...
                'Parent',Panel,...
                'Style','pushbutton',...
                'Units','character', ...
                'String',ctrlMsgUtils.message('Control:scalegui:SaveScaling'),...
                'Callback','');
            HG.Help = uicontrol(...
                'Parent',Panel,...
                'Style','pushbutton',...
                'Units','character', ...
                'String',ctrlMsgUtils.message('Control:scalegui:strHelp'),...
                'Callback','');



            this.HG = HG;
        end


    end
end

%--------------------------------------------------------------------------
%%
function localUpdateScaleFocusMode(this)
if  get(this.HG.TopCheckBox,'Value')
    NewMode = 'auto';
    this.ScalingView.setScaleFocus([]);
else
    NewMode = 'manual';
end  
    
this.ScalingView.setScaleFocusMode(NewMode);
end


%%
function localUpdateScaleFocus(this)
set(this.HG.TopCheckBox,'Value',0)
[b1,minvalue] = localValidateInput(this.HG.TopEdit(1));
[b2,maxvalue] = localValidateInput(this.HG.TopEdit(2));
if b1 && b2 && (maxvalue>minvalue)
    this.ScalingView.setScaleFocus([minvalue,maxvalue]);    
end
end


function localUpdatePlotFocusMode(this)
if  get(this.HG.BottomCheckBox,'Value')
    NewMode = 'auto';
else
    NewMode = 'manual';
end  
    
this.ScalingView.setPlotFocusMode(NewMode);
end

function localUpdatePlotFocus(this)
set(this.HG.BottomCheckBox,'Value',0)
[b1,minvalue] = localValidateInput(this.HG.BottomEdit(1));
[b2,maxvalue] = localValidateInput(this.HG.BottomEdit(2));
if b1 && b2 && (maxvalue>minvalue)
    this.ScalingView.setPlotFocus([minvalue,maxvalue]);    
end
end


function [b,value] = localValidateInput(hedit)
    str = get(hedit,'String');
    value = str2double(str);
    if isempty(str) || (~isnan(value) && isreal(value) && isfinite(value) && (value>0))
        set(hedit,'UserData',str)
        b=true;
    else
        % Revert to previous value
        set(hedit,'String',get(hedit,'UserData'))
        b=false;
    end
end
    


    

