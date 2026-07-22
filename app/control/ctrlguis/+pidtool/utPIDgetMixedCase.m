function out = utPIDgetMixedCase(in)
%MIXEDCASE

if ~ischar(in)
    error('Input should be a string');
else
    if numel(in) <= 1
        out = upper(in(1));
    else
        out = [upper(in(1)) lower(in(2:end))];
    end
end
end