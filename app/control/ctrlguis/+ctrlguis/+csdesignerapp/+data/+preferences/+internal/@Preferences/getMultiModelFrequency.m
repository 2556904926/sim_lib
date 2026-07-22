function FreqData = getMultiModelFrequency(this)
%getMultiModelFrequency  

%   Copyright 1986-2015 The MathWorks, Inc.

if this.MultiModelFrequencySelectionData.UseAutoMode
    if isempty(this.MultiModelFrequencySelectionData.AutoModeData)
        %Recompute
        localComputeFreqGrid(this)
    end
    FreqData= this.MultiModelFrequencySelectionData.AutoModeData;
else
    FreqData = this.MultiModelFrequencySelectionData.UserModeData;
end

Ts = getTs(getArchitecture(this.Target.getData));
if Ts ~= 0
    FreqData = FreqData(FreqData<=pi/Ts);
end
    
    
function localComputeFreqGrid(this)

P = this.Target.LoopData.Plant.getP;

if isa(P,'ltipack.frddata')
    NewData = P.Frequency;
    
else
    for ct = 1:length(P)
        [~,~,~,FocusInfo(ct,1)] = freqresp(P(ct),3,[],false);
    end
    
    Focus = ltipack.mrgfocus(cat(1,FocusInfo.Focus),cat(1,FocusInfo.Soft));
    if any(isnan(Focus))
        Focus = [.1, 100];
    end
    
    Upper = ceil(log10(Focus(2)))+1;
    Lower = floor(log10(Focus(1)))-1;
    NewData = logspace(Lower,Upper,(Upper-Lower)*50);
end

this.MultiModelFrequencySelectionData.AutoModeData = NewData;
