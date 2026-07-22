function r = createResponse(this,View,Systems,Styles,varargin)
%CREATERESPONSE  Creates one response per system for a given plot.

%   Authors: Kamesh Subbarao
%   Copyright 1986-2010 The MathWorks, Inc. 

PlotType = View.Tag;

for ct=1:length(Systems)
   src = Systems(ct);
   r = View.addresponse(Systems);
   switch PlotType
      case {'step','impulse'}
         r.DataFcn = {'timeresp' src PlotType r};
         r.Context = struct('Type',PlotType,'Time',[],'Parameter',[],'Config',RespConfig());
         if strcmpi(PlotType,'step')
             DefinedCharacteristics = src.getCharacteristics('step');
             DefinedCharacteristics(end+1) = struct(...
            'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
            'CharacteristicID', 'MultipleModelView', ...
            'CharacteristicData', 'resppack.UncertainStepData', ...
            'CharacteristicView', 'resppack.UncertainTimeView', ...
            'CharacteristicGroup', 'MultiModel');
             r.setCharacteristics(DefinedCharacteristics); 

         else
             DefinedCharacteristics = src.getCharacteristics('impulse');
             DefinedCharacteristics(end+1) = struct(...
                 'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
                 'CharacteristicID', 'MultipleModelView', ...
                 'CharacteristicData', 'resppack.UncertainImpulseData', ...
                 'CharacteristicView', 'resppack.UncertainTimeView', ...
                 'CharacteristicGroup', 'MultiModel');
             r.setCharacteristics(DefinedCharacteristics); 
         end
      case 'initial'
         r.DataFcn = {'timeresp' src PlotType r};
         Config = struct('InitialState',[]);
         r.Context = struct('Type','initial','Time',[],'Parameter',[],'Config',Config);
         DefinedCharacteristics = src.getCharacteristics('initial');
         r.setCharacteristics(DefinedCharacteristics);
      case 'lsim'
         r.DataFcn = {'lsim' src r};
         r.Context = struct('InputIndex',[],'IC',[]);
         % The size of the new initial state must match the # of states in the added
         % systems
      case {'bode','bodemag'}
         r.DataFcn = {'magphaseresp' src 'bode' r []};
         DefinedCharacteristics = src.getCharacteristics('bode');
         DefinedCharacteristics(end+1) = struct(...
             'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
             'CharacteristicID', 'MultipleModelView', ...
             'CharacteristicData', 'resppack.UncertainMagPhaseData', ...
             'CharacteristicView', 'resppack.UncertainBodeView', ...
             'CharacteristicGroup', 'MultiModel');
         r.setCharacteristics(DefinedCharacteristics);
         wchar = r.initializeCharacteristic('MultipleModelView');
         wchar.DataFcn = {@LocalMultiModelMagPhaseDataFcn wchar 'bode' this};
      case 'nichols'
         r.DataFcn = {'magphaseresp' src 'nichols' r  []};
         DefinedCharacteristics = src.getCharacteristics('nichols');
         r.setCharacteristics(DefinedCharacteristics);
      case 'nyquist'
         r.DataFcn = {'nyquist',src,r,[]};
         DefinedCharacteristics = src.getCharacteristics('nyquist');
%          DefinedCharacteristics(end+1) = struct(...
%              'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
%              'CharacteristicID', 'MultipleModelView', ...
%              'CharacteristicData', 'resppack.UncertainMagPhaseData', ...
%              'CharacteristicView', 'resppack.UncertainNyquistView', ...
%              'CharacteristicGroup', 'MultiModel');
         r.setCharacteristics(DefinedCharacteristics);
      case 'sigma'
         r.DataFcn = {'sigma',src,r,[]};
         DefinedCharacteristics = src.getCharacteristics('sigma');
         r.setCharacteristics(DefinedCharacteristics);
      case 'pzmap'
         r.DataFcn = {@LocalPZMapDataFcn 'pzmap' src r this};
%          DefinedCharacteristics = src.getCharacteristics('pzmap');
         DefinedCharacteristics(1) = struct(...
             'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
             'CharacteristicID', 'MultipleModelView', ...
             'CharacteristicData', 'resppack.UncertainPZData', ...
             'CharacteristicView', 'resppack.UncertainPZView', ...
             'CharacteristicGroup', 'MultiModel');
         r.setCharacteristics(DefinedCharacteristics);
         wchar = r.initializeCharacteristic('MultipleModelView');
         wchar.DataFcn = {@LocalMultiModelPZDataFcn wchar [] this};
      case 'iopzmap'
         r.DataFcn = {@LocalIOPZMapDataFcn 'pzmap' src r 'io' this};
         DefinedCharacteristics = src.getCharacteristics('iopzmap');
         r.setCharacteristics(DefinedCharacteristics);
   end
   % Styles and preferences
   initsysresp(r,PlotType,View.Options)
   r.Style = Styles(ct);
end


%%%%%%%%%%%%%%%%%%%%
% LocalPZMapDataFcn %
%%%%%%%%%%%%%%%%%%%%
function LocalPZMapDataFcn(PlotType,Src,r,this)
PadeOrder = this.Preferences.PadeOrder;
sw = warning('off','Control:transformation:StateSpaceScaling');[lw,lwid] = lastwarn;
feval(PlotType,Src,r,[],PadeOrder);
warning(sw); lastwarn(lw,lwid);

function LocalIOPZMapDataFcn(PlotType,Src,r,ioflag,this)
PadeOrder = this.Preferences.PadeOrder;
sw = warning('off','Control:transformation:StateSpaceScaling');[lw,lwid] = lastwarn;
feval(PlotType,Src,r,ioflag,PadeOrder);
warning(sw); lastwarn(lw,lwid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LocalMultiModelMagPhaseDataFcn %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalMultiModelMagPhaseDataFcn(wchar,PlotType,this)
sw = warning('off','Control:analysis:ScalingIssue');[lw,lwid] = lastwarn;
wf = wchar.Parent; % parent waveform
for ct=1:length(wchar.Data)
   % Propagate exceptions
   wchar.Data(ct).Exception = wf.Data(ct).Exception;
   if ~wchar.Data(ct).Exception
       % REVIST
      getUncertainMagPhaseData(wf.DataSrc,PlotType,wf,wchar.Data,this.Preferences.getMultiModelFrequency);
   end
end
warning(sw); lastwarn(lw,lwid);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LocalMultiModelPZDataFcn       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalMultiModelPZDataFcn(wchar,ioflag,this)

PadeOrder = this.Preferences.PadeOrder;
wf = wchar.Parent; % parent waveform
for ct=1:length(wchar.Data)
   % Propagate exceptions
   wchar.Data(ct).Exception = wf.Data(ct).Exception;
   if ~wchar.Data(ct).Exception
      getUncertainPZData(wf.DataSrc,wf,wchar.Data,ioflag,PadeOrder);
   end
end

