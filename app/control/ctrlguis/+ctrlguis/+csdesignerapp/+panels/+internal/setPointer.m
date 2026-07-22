function currPointer = setPointer(fig,pointerType)
%% SETPOINTER - Sets specified mouse pointer
%
%  CURRPOINTER = SETPOINTER(FIG,POINTERTYPE) set mouse pointer of FIG to
%  POINTERTYPE and return CURRPOINTER.

%  Copyright 2020 The MathWorks, Inc.

if isempty(fig) || ~isvalid(fig)
    currPointer = [];
    return
end

currPointer = fig.Pointer;
fig.Pointer = pointerType;

%drawnow
end
