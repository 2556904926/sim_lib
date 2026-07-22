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
[M,C,K,B,F,G,D] = mechssdata(sys);
nq = size(K,1);

% Creat axes
ax = controllib.chart.internal.utils.getEntryAxesForChart(hParent);
fig = ancestor(ax,'figure');

% Parameters
MSIZE = 2*get(fig,'defaultlinemarkersize');
COLORS = struct('MCK',[0  4.4700e-01  7.4100e-01],...
   'B',[9.2900e-01   6.9400e-01   1.2500e-01],...
   'FG',[4.6600e-01   6.7400e-01   1.8800e-01],...
   'D',[8.5000e-01   3.2500e-01   9.8000e-02],...
   'WATERMARK',[.8 .8 .8]);

% Create plot
[i,j] = localFind(M);
LM = line(j,i,'Parent',ax,'Color',COLORS.WATERMARK,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','M');
[i,j] = localFind(C);
LC = line(j,i,'Parent',ax,'Color',COLORS.WATERMARK,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','C');
[i,j] = localFind(K);
LK = line(j,i,'Parent',ax,'Color',COLORS.MCK,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','K');
[i,j] = localFind(B);
LB = line(j+nq,i,'Parent',ax,'Color',COLORS.B,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','B');
[i,j] = localFind(G);
LG = line(j,i+nq,'Parent',ax,'Color',COLORS.WATERMARK,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','G');
[i,j] = localFind(F);
LF = line(j,i+nq,'Parent',ax,'Color',COLORS.FG,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','F');
[i,j] = localFind(D);
LD = line(j+nq,i+nq,'Parent',ax,'Color',COLORS.D,...
   'LineStyle','none','Marker','.','Markersize',MSIZE,'Tag','D');
LINES = [LM ; LC ; LK ; LB ; LF ; LG ; LD];

set(ax,'xlim',[0 nq+nu+1],'ylim',[0 nq+ny+1],'ydir','reverse', ...
   'plotboxaspectratio',[nq+nu+1 nq+ny+1 1]);
title(ax,localNNZ('M',nnz(M),'C',nnz(C),'K',nnz(K),'B',nnz(B),...
   'F',nnz(F),'G',nnz(G),'D',nnz(D)))
xlabel(ax,getString(message('Control:ltiobject:spy4')),'FontSize',10)

% Show partition
localShowPartition(ax,sys.StateInfo)

% Legend
legend([LK LB LF LD],{'K','B','F','D'},'Location','NorthEastOutside');

% Create context menu for managing selected matrices
cm = uicontextmenu(fig);
ax.ContextMenu = cm;
mMCK = [uimenu(cm,'Text','M');uimenu(cm,'Text','C');...
   uimenu(cm,'Text','K','Checked','on')];
set(mMCK,'MenuSelectedFcn',...
   @(mh,~) localSelect(mh,mMCK,LINES,COLORS))
mFG = [uimenu(cm,'Text','F','Separator','on','Checked','on');...
   uimenu(cm,'Text','G')];
set(mFG,'MenuSelectedFcn',...
   @(mh,~) localSelect(mh,mFG,LINES,COLORS))

% Install listener to clear context menu when spy plot is cleared
cm.UserData = listener(LK,'ObjectBeingDestroyed',@(~,~) delete(cm));

%--------------------------------------------------
function localSelect(mh,mMENU,LINES,COLORS)
isSelected = (mh==mMENU);
mh.Checked = 'on';
set(mMENU(~isSelected),'Checked','off')
if strcmp(mMENU(1).Text,'M')
   mLINES = LINES(1:3,:);   mCOLOR = COLORS.MCK;
else
   mLINES = LINES(5:6,:);   mCOLOR = COLORS.FG;
end
set(mLINES(isSelected),'Color',mCOLOR)
set(mLINES(~isSelected),'Color',COLORS.WATERMARK)
isHIDDEN = cellfun(@(C) isequal(C,COLORS.WATERMARK),get(LINES,'Color'));
LHIDE = LINES(isHIDDEN,:);
LSHOW = LINES(~isHIDDEN,:);
ax = LINES(1).Parent;
ax.Children(end-numel(LINES)+1:end) = [LSHOW;LHIDE];
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