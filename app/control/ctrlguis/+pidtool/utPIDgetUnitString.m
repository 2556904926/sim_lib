function [TimeUnitMsg FreqUnitMsg FreqUnit] = utPIDgetUnitString(TimeUnit)
% UTPIDGETUNITSTRING  Return time/freq unit strings for display and
% frequency unit based on time unit.
%
 
% Author(s): Rong Chen 27-Oct-2010
% Copyright 2010 The MathWorks, Inc.

if strcmp(TimeUnit,'seconds')
    FreqUnit = 'rad/s';
else
    FreqUnit = ['rad/' TimeUnit(1:end-1)];
end
strings = controllibutils.utGetValidTimeUnits;
TimeUnitMsg = ctrlMsgUtils.message(strings{strcmp(TimeUnit,strings(:,1)),2});
strings = controllibutils.utGetValidFrequencyUnits;
FreqUnitMsg = ctrlMsgUtils.message(strings{strcmp(FreqUnit,strings(:,1)),2});
