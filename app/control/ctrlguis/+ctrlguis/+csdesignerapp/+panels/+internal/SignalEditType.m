classdef SignalEditType < int32
    % Enum for signal edit action in the list panel.
    
    %  Copyright 2020 The MathWorks, Inc.
    
    enumeration
        None(0)
        Initialization(1)
        Add(2)
        MoveUp(3)
        MoveDown(4)
        Remove(5)
    end
end