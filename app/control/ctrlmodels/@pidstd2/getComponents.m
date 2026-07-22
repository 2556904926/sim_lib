function [out1, out2] = getComponents(PIDS2,looptype)
%%GETCOMPONENTS extracts two SISO control components from a 2-DOF PID controller
%
% [C,X] = getComponents(C2,LOOPTYPE) returns two SISO control components C
% and X based on a given closed loop structure LOOPTYPE. C is a PID object
% and X is a transfer function in ZPK form. The string LOOPTYPE specifies a
% loop structure for 2-DOF PID control implementation. The following loop
% structures are supported:
%
% 1. 'feedforward'
%    In this loop structure, X is implemented as a feedforward controller.
%    C is implemented as a conventional SISO feedback controller taking the error signal
%    as its input.
%
%
%                  +-------[ X ]------+
%                  |                  |
%                  |      e           v  u
%           r -----+--->O--->[ C ]----O---->[ G ]---+---> y
%                     - |             +             |
%                       |                           |
%                       +---------------------------+
%
% 2. 'feedback'
%    In this loop structure, X is implemented as a feedback controller from y to u.
%    C is implemented as a conventional SISO feedback controller taking the error signal
%    as its input.
%
%                         e          -  u
%           r --------->O--->[ C ]---O--->[ G ]---+---> y
%                     - |            ^            |
%                       |            |            |
%                       |          [ X ]          |
%                       |            |            |
%                       +------------+------------+
%
% 3. 'filter'
%    In this loop structure, X is implemented as a pre-filter to the reference signal.
%    C is implemented as a conventional SISO feedback controller taking the error signal
%    as its input.
%
%                         e        u
%         r -->[ X ]--->O--->[ C ]--->[ G ]---+---> y
%                     - |                     |
%                       |                     |
%                       +---------------------+
%
% If no LOOPTYPE is specified, 'feedforward' is taken as the default value.
%
%  See also pid2/make1DOF, pidstd2/make1DOF.

%   Author(s): B. Singh Copyright 2015 The MathWorks, Inc.

if nargin > 2
    error(message('MATLAB:narginchk:tooManyInputs'));
end

% get LOOPTYPE form input arguments
if nargin == 2
    if isStringScalar(looptype)
        % If string, convert to char
        looptype = char(looptype);
    end
    if ~ischar(looptype)
        error(message('Control:design:pidtune12'))
    end
    N = length(looptype);
    validValues = {'feedforward';'feedback';'filter'};
    if ~any(strncmpi(looptype,validValues,N))
        error(message('Control:ltiobject:pidOperationsGetComponents1'))
    end
    id = find(strncmpi(looptype,validValues,N));
    looptype = validValues{id(1)};
else
    looptype = 'feedforward';
end

Data = PIDS2.Data_;

% Get output data objects
c1Data = createArray(size(Data),'ltipack.piddataS');
xData = createArray(size(Data),'ltipack.zpkdata');

switch looptype
    case 'feedforward'
        for ct=1:numel(Data)
            c1Data(ct) = make1DOF(Data(ct));
            [~,xData(ct),~] = get2DOFComponents(Data(ct));
        end
    case 'feedback'
        for ct=1:numel(Data)
            [c1DataZPK,cfData,~] = get2DOFComponents(Data(ct));
            xData(ct) = -cfData; % Cfb = -Cf
            Options.IFormula = Data(ct).IFormula;
            Options.DFormula = Data(ct).DFormula;
            c1Data(ct) = pidstd(c1DataZPK,Options);
        end
    case 'filter'
        for ct=1:numel(Data)
            c1Data(ct) = make1DOF(Data(ct));
            [~,~,xData(ct)] = get2DOFComponents(Data(ct));
        end
end

% Convert to required output types
out1 = pidstd.make(c1Data);
out2 = zpk.make(xData);
out1.TimeUnit = PIDS2.TimeUnit;
out2.TimeUnit = PIDS2.TimeUnit;
out1.SamplingGrid = PIDS2.SamplingGrid;
out2.SamplingGrid = PIDS2.SamplingGrid;
end
