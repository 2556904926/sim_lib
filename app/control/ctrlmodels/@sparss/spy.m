function spy(varargin)
%SPY  Visualize sparsity pattern of SPARSS and MECHSS models.
%
%   SPY(SYS) plots the sparsity pattern of the SPARSS or MECHSS model SYS.
%
%   SPY(PARENT,SYS) puts the plot in the specified parent container. 
%
%   When SYS is constructed by interfacing or interconnecting components,
%   use SPY(XSORT(SYS)) to view the underlying block arrow structure.
%
%   See also SPARSS, MECHSS, XSORT.

%   Copyright 2020 The MathWorks, Inc. 
% Parse inputs
narginchk(1,2)
if nargin==2
    hParent = varargin{1};
    controllib.chart.internal.utils.validators.mustBeChartParent(hParent);
    sys = varargin{2};
else
    hParent = [];
    sys = varargin{1};
end

% System data
[ny,nu,nsys] = size(sys);
if nsys>1
   error(message('Control:ltiobject:spy2'))
elseif hasInternalDelay(sys)
   error(message('Control:ltiobject:spy3'))
end
[A,B,C,D,E] = sparssdata(sys);
nx = size(A,1);

% Creat axes
ax = controllib.chart.internal.utils.getEntryAxesForChart(hParent);
fig = ancestor(ax,'figure');

% Parameters
MSIZE = 2*get(fig,'defaultlinemarkersize');
COLORS = struct('AE',[0  4.4700e-01  7.4100e-01],...
   'B',[9.2900e-01   6.9400e-01   1.2500e-01],...
   'C',[4.6600e-01   6.7400e-01   1.8800e-01],...
   'D',[8.5000e-01   3.2500e-01   9.8000e-02],...
   'WATERMARK',[.8 .8 .8]);

% Create plot
[i,j] = localFind(E);
LE = line(j,i,'Parent',ax,'Color',COLORS.WATERMARK,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','E');
[i,j] = localFind(A);
LA = line(j,i,'Parent',ax,'Color',COLORS.AE,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','A');
[i,j] = localFind(B);
LB = line(j+nx,i,'Parent',ax,'Color',COLORS.B,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','B');
[i,j] = localFind(C);
LC = line(j,i+nx,'Parent',ax,'Color',COLORS.C,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','C');
[i,j] = localFind(D);
LD = line(j+nx,i+nx,'Parent',ax,'Color',COLORS.D,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','D');
LINES = [LA ; LE ; LB ; LC ; LD];

set(ax,'xlim',[0 nx+nu+1],'ylim',[0 nx+ny+1],'ydir','reverse', ...
   'plotboxaspectratio',[nx+nu+1 nx+ny+1 1]);
title(ax,localNNZ('A',nnz(A),'E',nnz(E),'B',nnz(B),'C',nnz(C),'D',nnz(D)))
xlabel(ax,getString(message('Control:ltiobject:spy4')),'FontSize',10)

% Show partition
localShowPartition(ax,sys.StateInfo)

% Legend
legend([LA LB LC LD],{'A','B','C','D'},'Location','NorthEastOutside');

% Create context menu for managing selected matrices
cm = uicontextmenu(fig);
ax.ContextMenu = cm;
mAE = [uimenu(cm,'Text','A','Checked','on');uimenu(cm,'Text','E')];
set(mAE,'MenuSelectedFcn',...
   @(mh,~) localSelect(mh,mAE,LINES,COLORS))

% Install listener to clear context menu when spy plot is cleared
cm.UserData = listener(LA,'ObjectBeingDestroyed',@(~,~) delete(cm));

%--------------------------------------------------
function localSelect(mh,mAE,LINES,COLORS)
isSelected = (mh==mAE);
mh.Checked = 'on';
mAE(~isSelected).Checked = 'off';
mLINES = LINES(1:2);
mLINES(isSelected).Color = COLORS.AE;
mLINES(~isSelected).Color = COLORS.WATERMARK;
LSHOW = [mLINES(isSelected);LINES(3:5)];
LHIDE = mLINES(~isSelected);
ax = LHIDE.Parent;
ax.Children(end-4:end) = [LSHOW;LHIDE];
legend(LSHOW,get(LSHOW,'Tag'),'Location','NorthEastOutside');

function localShowPartition(ax,StateInfo)
% Components
if ~isempty(StateInfo)
   PART = cumsum([StateInfo.Size]);
   for ct=1:numel(PART)
      aux = [PART(ct) PART(ct)]+0.5;
      line(aux,ax.YLim,'Parent',ax,'Color','m',...
         'LineStyle',':','LineWidth',0.5)
      line(ax.XLim,aux,'Parent',ax,'Color','m',...
         'LineStyle',':','LineWidth',0.5)
   end
end

function [i,j] = localFind(X)
[i,j] = find(X);
if isempty(i)
   i = NaN; j = NaN;
end

function str = localNNZ(varargin)
str = "nnz: ";
for ct=1:2:nargin
   if varargin{ct+1}>0
      str = str + varargin{ct} + "=" + varargin{ct+1} + ", ";
   end
end
n = strlength(str);
str = replaceBetween(str,n-1,n,".");