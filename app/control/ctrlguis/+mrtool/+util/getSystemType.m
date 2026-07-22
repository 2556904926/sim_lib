function SystemType = getSystemType(System)
    [ny,nu] = iosize(System);
    type = class(System);
    SystemType = sprintf('%dx%d %s',ny,nu,type);
end
    

