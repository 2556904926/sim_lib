function waitBar = setWaitingInsideDialog(waitFlag,dialog,waitBar)
% Utility function to create waiting
% flag true means set waiting, false means clear waiting

% Copyright 2016-2020 The MathWorks, Inc.

arguments
    waitFlag
    dialog
    waitBar = []
end

if isgraphics(dialog)
    if waitFlag
        dialog.Pointer = 'watch';
    else
        dialog.Pointer = 'arrow';
    end
end
