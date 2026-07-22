function defs = ltiplottypes(str)
%LTIPLOTTYPES  Return information about built-in LTI plot types.
%
%   NAMES = LTIPLOTTYPES('Name') returns the list of built-in LTI 
%   plot names.
%
%   ALIASES = LTIPLOTTYPES('Alias') returns the list of aliases used
%   to identify built-in LTI plot.

%   Author(s): Kamesh Subbarao
%   Copyright 1986-2011 The MathWorks, Inc. 

switch str
    case 'Alias'
        defs = ...
            {'step';
            'impulse';
            'lsim';
            'initial';
            'bode';
            'bodemag';
            'nyquist';
            'nichols';
            'sigma';
            'pzmap';
            'iopzmap'};
        
    case 'Name'
        defs = ...
            {getString(message('Control:analysis:strStep'));
            getString(message('Control:analysis:strImpulse'));
            getString(message('Control:analysis:strLinearSimulation'));
            getString(message('Control:analysis:strInitialCondition'));
            getString(message('Control:analysis:strBode'));
            getString(message('Control:analysis:strBodeMagnitude'));
            getString(message('Control:analysis:strNyquist'));
            getString(message('Control:analysis:strNichols'));
            getString(message('Control:analysis:strSingularValue'));
            getString(message('Control:analysis:strPoleZero'));
            getString(message('Control:analysis:strIOPoleZero'))};
end
