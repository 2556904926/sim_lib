function varargout = aboutcst
%ABOUTCST  About Control System Toolbox (splash)

%   Author(s): A. DiVergilio
%   Copyright 1986-2024 The MathWorks, Inc.

%---Re-use the figure if its already open
persistent f
if isempty(f) || ~isvalid(f)
    %---Figure
    fw = 330;
    fh = 420;
    sp = 25;
    f = uifigure(Name=getString(message('Control:general:strAboutCST')),...
        Position=[0 0 fw fh],...
        Tag='AboutCST');...
    f.WindowButtonDownFcn = @(es,ed) spinlogo(f,es,ed);
    centerfig(f);
    gl = uigridlayout(f,[3 2]);
    gl.RowHeight = {'1x','fit'};
    gl.ColumnWidth = {'4x','1x'};
    %---Axes
    ax = uiaxes(gl,Position=[sp fh-sp-(fw-2*sp) fw-2*sp fw-2*sp],...
        XLim=[-1 1],...
        YLim=[-1 1],...
        Visible='off',...
        NextPlot='add');
    ax.Layout.Row = 1;
    ax.Layout.Column = [1 2];
    ax.ButtonDownFcn = @(es,ed) spinlogo(f);
    axtoolbar(ax,{});

    %---CST info
    verstruct = ver('control');
    verstring = sprintf('  V%s',verstruct.Version);
    lbl = uilabel(gl,Text={[getString(message('Control:general:strCST')) verstring]...
        getString(message('Control:general:strCopyright',verstruct.Date(end-3:end))),...
        getString(message('Control:general:strMathowrksInc'))},FontWeight='bold',...
        Tag='ProductInfoText',Visible=false);
    lbl.Layout.Row = 2;
    lbl.Layout.Column = 1;
    %---OK
    btn = uibutton(gl,Text=getString(message('Control:general:strOK')),...
        Tag='OKButton',ButtonPushedFcn=@(es,ed) close(f),Visible='off',Interruptible='off');
    btn.Layout.Row = 2;
    btn.Layout.Column = 2;
end
%---Animate
f.Visible = true;
spinlogo(f);
if nargout
    varargout{1} = f;
end
end

%%%%%%%%%%%%
% spinlogo %
%%%%%%%%%%%%
function spinlogo(f,varargin)
% arguments
%     f (1,1) matlab.ui.Figure
% end
%---Animate CST splash screen

if ~isvalid(f)
    return;
end

%---Temporarily disable re-animation
f.WindowButtonDownFcn = [];
f.Pointer = "watch";

%---Axes handle
gl = f.Children;
ax = gl.Children(1);
infoLbl = gl.Children(2);
okBtn = gl.Children(3);

if f.CurrentPoint(1) >= okBtn.Position(1) && f.CurrentPoint(1) <= okBtn.Position(1)+okBtn.Position(3) &&...
        f.CurrentPoint(2) >= okBtn.Position(2) && f.CurrentPoint(2) <= okBtn.Position(2)+okBtn.Position(4)
    return; % Ignore if ok clicked
end

%---Clean up
delete(ax.Children);
infoLbl.Visible = false;
okBtn.Visible = false;

%---Create a zgrid
[lh,th] = zpchart(ax);

%---Delete the text, make the lines bold
delete(th)
set(lh,LineWidth=2,LineStyle='-')
matlab.graphics.internal.themes.specifyThemePropertyMappings(lh(1:end-1),"Color","--mw-graphics-colorOrder-8-primary");
matlab.graphics.internal.themes.specifyThemePropertyMappings(lh(end),"EdgeColor","--mw-graphics-colorOrder-8-primary");

%---Animate
X = [-90 -82 -69 -55 -40 -25 -5 25 40 55 69 82 90];
C1 = [180 100  30  15  12  10  9  8  7  6  5  4  3];
C2 = [3.5 4.0 4.5  5  5.5  5.8  6 6.1 6.2 6.3 6.4 6.5 6.6];
for x = 1:length(X)
    ax.CameraViewAngle = C1(x);
    ax.View = [X(x)+90 -X(x)];
    pause(.01)
end
for x = 1:length(X)-1
    ax.CameraViewAngle = C2(x);
    ax.View = [X(length(X)-x)+90 -X(length(X)-x)];
    pause(.01)
end
ax.CameraViewAngle = get(groot,'DefaultAxesCameraViewAngle');

%---Add some nice data to plot
z = [-0.1984+0.2129i -0.1984-0.2129i];
p = [ 0.0447+0.4558i 0.0447-0.4558i 0.1848+0.1586i 0.1848-0.1586i -0.3560+0.3916i -0.3560-0.3916i];
k = 0.5059;
sys = zpk(z,p,k,1);
R = rlocus(sys);
l1 = line(ax,real(R(1,1)),imag(R(1,1)),LineWidth=3,HitTest='off',Clipping='off');
l2 = line(ax,real(R(2,1)),imag(R(2,1)),LineWidth=3,HitTest='off',Clipping='off');
matlab.graphics.internal.themes.specifyThemePropertyMappings([l1;l2],"Color","--mw-graphics-colorOrder-5-primary");
l3 = line(ax,real(R(3,1)),imag(R(3,1)),LineWidth=3,HitTest='off',Clipping='off');
l4 = line(ax,real(R(4,1)),imag(R(4,1)),LineWidth=3,HitTest='off',Clipping='off');
matlab.graphics.internal.themes.specifyThemePropertyMappings([l3;l4],"Color","--mw-graphics-colorOrder-7-primary");
l5 = line(ax,real(R(5,1)),imag(R(5,1)),LineWidth=3,HitTest='off',Clipping='off');
l6 = line(ax,real(R(6,1)),imag(R(6,1)),LineWidth=3,HitTest='off',Clipping='off');
matlab.graphics.internal.themes.specifyThemePropertyMappings([l5;l6],"Color","--mw-graphics-colorOrder-6-primary");
s1 = scatter(ax,real(p),imag(p),LineWidth=2,Marker='x',SizeData=100);
matlab.graphics.internal.themes.specifyThemePropertyMappings(s1,"MarkerEdgeColor","--mw-graphics-colorOrder-10-primary");
s2 = scatter(ax,real(z),imag(z),LineWidth=2,Marker='o',SizeData=64);
matlab.graphics.internal.themes.specifyThemePropertyMappings(s2,"MarkerEdgeColor","--mw-graphics-colorOrder-11-primary");
for n=2:2:length(R(1,:))
    set(l1,XData=real(R(1,1:n)),YData=imag(R(1,1:n)));
    set(l2,XData=real(R(2,1:n)),YData=imag(R(2,1:n)));
    set(l3,XData=real(R(3,1:n)),YData=imag(R(3,1:n)));
    set(l4,XData=real(R(4,1:n)),YData=imag(R(4,1:n)));
    set(l5,XData=real(R(5,1:n)),YData=imag(R(5,1:n)));
    set(l6,XData=real(R(6,1:n)),YData=imag(R(6,1:n)));
    pause(.01);
end

infoLbl.Visible= true;
okBtn.Visible = true;

%---Activate lines for re-animation
f.WindowButtonDownFcn = @(es,ed) spinlogo(f,es,ed);
f.Pointer = "arrow";
end