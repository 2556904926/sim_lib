function [ValidFlags,Systems,InvalidType] = isValidSystem(Systems)
% Assumes Systems are cell array of Dynamic System

%   Copyright 2015-2020 The MathWorks, Inc.
InvalidType = '';
ValidFlags = false(size(Systems));
for ct=1:length(Systems)
    sys = Systems{ct};
    if isa(sys,'DynamicSystem')
        if issparse(sys)
            ValidFlags(ct) = true;
        else
            try
                % if not above, convert to ss
                sys = ss(sys);
                ValidFlags(ct) = true;
            catch
                ValidFlags(ct) = false;
            end
        end
    end
    
    %% verify that
    % single model, no delay, without inputs and outputs, not static
    if ValidFlags(ct) 
        if numsys(sys)>1
            InvalidType = 'ltiarray';
            ValidFlags(ct) = false;
        elseif any(iosize(sys)==0)
            InvalidType = 'io';
            ValidFlags(ct) = false;
        elseif ~issparse(sys) && ~isproper(sys,true)
            InvalidType = 'improper';
            ValidFlags(ct) = false;
        elseif isstatic(sys)
            InvalidType = 'static';
            ValidFlags(ct) = false;
        else
            % discrete system
            if isdt(sys)
                % absorb delay
                if hasdelay(sys)
                    Systems{ct} = absorbDelay(sys);
                end
                % unspecified sample time
                if sys.Ts<0
                    Systems{ct}.Ts = 1;
                end
            else
                if hasdelay(sys)
                    InvalidType = 'delay';
                    ValidFlags(ct) = false;
                end
            end                    
        end
    end    
end
end