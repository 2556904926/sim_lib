function Model = utApproxDelay(Model)
% Helper function for approximating delays

%   Copyright 1986-2009 The MathWorks, Inc.

if hasdelay(Model)
    if isequal(getTs(Model),0)
        PadeOrder = 2;
        Model = pade(Model,PadeOrder,PadeOrder,PadeOrder);
    else
        Model = delay2z(Model);
    end
end