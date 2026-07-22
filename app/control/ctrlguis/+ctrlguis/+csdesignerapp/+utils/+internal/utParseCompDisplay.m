function [PZString, GainString, lenString] = utParseCompDisplay( ...
                                             selectedCompensator)
    % UTPARSECOMPDISPLAY Summary of this function goes here
    %   Detailed explanation goes here
    

    % Get the selected compensator
    Compensator = selectedCompensator; %getSelectedCompensator(parent);

    % Get list of poles and zeros
    [ZString, PString] = getDisplayString(Compensator);
    lenString = max(length(ZString), length(PString));
    if isempty(ZString) && isempty(PString)
        % Three line breaks
        PZString = '';
        GainString = sprintf('%0.5g', getFormattedGain(Compensator));
    else
%         PZString = sprintf('<center>%s</center><hr><center>%s</center>', ...
%                     ZString, PString);
        fString = '\; \times \; \frac';
        PZString = sprintf('$$%s{%s}{%s}$$', fString, ZString, PString);
        GainString = sprintf('%0.5g', getFormattedGain(Compensator));
    end
    
    
end

