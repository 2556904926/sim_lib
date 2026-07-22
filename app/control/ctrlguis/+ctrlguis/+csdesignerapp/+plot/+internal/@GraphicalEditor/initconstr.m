function initconstr(this, Constr)
%INITCONSTR  Generic initialization of plot constraints.
%
%   Called by editor-specific addconstr.

%   Copyright 1986-2024 The MathWorks, Inc. 

% Initialize
% Constr.EventManager = this.EventManager;
Constr.Zlevel = this.getZLevel('constraint');
Constr.ButtonDownFcn = {@LocalButtonDownFcn, Constr, this};
% Constr.TextEditor = plotconstr.tooleditor(this.ConstraintEditor,this);

Prefs = this.Preferences;
set(Constr,'PatchColor',Prefs.RequirementColor)
render(Constr);

% Install generic listeners
% RE: Do after prop. init. for trouble-free undo, and before activation to 
%     enable pre-set listener on Activated
Constr.initialize

% Add listeners connecting the constraint to the Editor environment
% L1 = [handle.listener(Constr,'DataChanged',{@LocalUpdateLims this})];
% set(L1,'CallbackTarget',this);
L1 = event.listener(Constr,'DataChanged',@(h,evt) LocalUpdateLims(this));
L2 = addlistener(this.Axes,'LimitsChanged',@(es,ed) LocalRefresh(es,ed));
Constr.addlisteners(L1);

% Add undo/redo fcn handles for the constraint
Constr.undoDeleteInfo.fcnGetData    = @localGetUndoData;
Constr.undoDeleteInfo.fcnUndoDelete = {@localUndoDelete this};
Constr.undoDeleteInfo.fcnRedoDelete = {@localRedoDelete this};
end


function LocalUpdateLims(Editor)
% Side effect of constraint's DataChanged event
if strcmp(Editor.EditMode,'idle')
   % Normal mode: update limits
   updatelims(Editor);
   % notify(Editor.Axes,'LimitsChanged');
end
end


function LocalReframe(Editor,eventData)
% Callback during dynamic mouse edit
% Reframe axes if edited objects are out of scope and limits are auto range
Axes = Editor.Axes;
WorkingAxes = Axes.EventManager.SelectedContainer;
Data = eventData.Data;
iy = (WorkingAxes==getaxes(Axes));

if any(iy) && (strcmp(Axes.XlimMode,'auto') || strcmp(Axes.YlimMode{iy},'auto'))
    MovePtr = Editor.reframe(WorkingAxes,'xy',Data.XExtent,Data.YExtent);
    if MovePtr
        moveptr(WorkingAxes,'move',Data.X,Data.Y)
    end
end
end

function LocalRefresh(Constr,eventData)
% Refreshes constraint display when axes limits change
if ishandle(Constr), render(Constr), end
end

function LocalButtonDownFcn(hSrc, event, Constr, Editor)
% Sets the ButtonDown callback for constraint objects.
if strcmp(Editor.EditMode,'idle')
    Constr.mouseevent('bd',hSrc);
end
end

function data = localGetUndoData(Constr)

data.Data = Constr.save;
data.Type = Constr.describe('identifier');
end

function localUndoDelete(Editor,undoData)

cEditor = Editor.newconstr(undoData.Type);
% From the constraint editor construct a view
sisodb = Editor.up;
hC = cEditor.Requirement.getView(Editor);
hC.PatchColor = sisodb.Preferences.RequirementColor;
hC.load(undoData.Data);
% Add to constraint list (includes rendering)
Editor.addconstr(hC);
hC.Selected = 'off';

%Notify client listeners that new requirement added
ed = plotconstr.constreventdata(Editor,'RequirementAdded');
ed.Data = hC;
Editor.send('RequirementAdded',ed)
end

function localRedoDelete(Editor,redoData)

hAx    = getaxes(Editor.Axes);
CList  = plotconstr.findConstrOnAxis(hAx(1));
allUID = get(CList,{'uID'});
idx = strcmp(allUID,redoData.Data.uID);
delete(CList(idx))
end

% LocalWords:  plotconstr Lims
