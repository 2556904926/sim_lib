function r = createResponse(this,View,Systems,Styles,varargin)
%CREATERESPONSE  Creates one response per system for a given plot.

%   Copyright 1986-2022 The MathWorks, Inc. 

PlotType = View.Tag;

for ct=1:length(Systems)

   r = View.addresponse(Systems);
   switch PlotType
      case {'step','impulse'}
         r.DataFcn = {'timeresp' Systems(ct) PlotType r []};
         r.Context = struct('Type',PlotType);
         if strcmpi(PlotType,'step')
             DefinedCharacteristics = Systems(ct).getCharacteristics('step');
             DefinedCharacteristics(end+1) = struct(...
            'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
            'CharacteristicID', 'MultipleModelView', ...
            'CharacteristicData', 'resppack.UncertainStepData', ...
            'CharacteristicView', 'resppack.UncertainTimeView', ...
            'CharacteristicGroup', 'MultiModel');
             r.setCharacteristics(DefinedCharacteristics); 

         else
             DefinedCharacteristics = Systems(ct).getCharacteristics('impulse');
             DefinedCharacteristics(end+1) = struct(...
                 'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
                 'CharacteristicID', 'MultipleModelView', ...
                 'CharacteristicData', 'resppack.UncertainImpulseData', ...
                 'CharacteristicView', 'resppack.UncertainTimeView', ...
                 'CharacteristicGroup', 'MultiModel');
             r.setCharacteristics(DefinedCharacteristics); 
         end
      case 'initial'
         r.DataFcn = {'timeresp' Systems(ct) PlotType r [] varargin{:}};
         r.Context = struct('Type',PlotType,'IC',[]);
         % The new initial state must match the systems size to be added
         if nargin>=6 && isStateSpace(Systems(ct).Model)
            x0 = varargin{2};
            order = size(Systems(ct).Model,'order');
            if isscalar(order) && order==length(x0)
               r.Context.IC = x0;
            end
         end
         DefinedCharacteristics = Systems(ct).getCharacteristics('initial');
         r.setCharacteristics(DefinedCharacteristics);
      case 'lsim'
         r.DataFcn = {'lsim' Systems(ct) r};
         r.Context = struct('InputIndex',[],'IC',[]);
         % The size of the new initial state must match the # of states in the added
         % systems
         if nargin>=6 && isStateSpace(Systems(ct).Model)
            order = size(Systems(ct).Model,'order');
            x0 = varargin{2};
            if isscalar(order) && order==length(x0)
               r.Context = struct('InputIndex',[],'IC',x0);
            end
         end
      case {'bode','bodemag'}
         r.DataFcn = {'magphaseresp' Systems(ct) 'bode' r []};
         DefinedCharacteristics = Systems(ct).getCharacteristics('bode');
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
         r.DataFcn = {'magphaseresp' Systems(ct) 'nichols' r  []};
         DefinedCharacteristics = Systems(ct).getCharacteristics('nichols');
         r.setCharacteristics(DefinedCharacteristics);
      case 'nyquist'
         r.DataFcn = {'nyquist',Systems(ct),r,[]};
         DefinedCharacteristics = Systems(ct).getCharacteristics('nyquist');
%          DefinedCharacteristics(end+1) = struct(...
%              'CharacteristicLabel', ctrlMsgUtils.message('Control:compDesignTask:strMultiModelDisplay'), ...
%              'CharacteristicID', 'MultipleModelView', ...
%              'CharacteristicData', 'resppack.UncertainMagPhaseData', ...
%              'CharacteristicView', 'resppack.UncertainNyquistView', ...
%              'CharacteristicGroup', 'MultiModel');
         r.setCharacteristics(DefinedCharacteristics);
      case 'sigma'
         r.DataFcn = {'sigma',Systems(ct),r,[]};
         DefinedCharacteristics = Systems(ct).getCharacteristics('sigma');
         r.setCharacteristics(DefinedCharacteristics);
      case 'pzmap'
         r.DataFcn = {@LocalPZMapDataFcn 'pzmap' Systems(ct) r this};
%          DefinedCharacteristics = Systems(ct).getCharacteristics('pzmap');
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
         r.DataFcn = {@LocalIOPZMapDataFcn 'pzmap' Systems(ct) r 'io' this};
         DefinedCharacteristics = Systems(ct).getCharacteristics('iopzmap');
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

PadeOrder = this.Parent.Preferences.PadeOrder;
wf = wchar.Parent; % parent waveform
for ct=1:length(wchar.Data)
   % Propagate exceptions
   wchar.Data(ct).Exception = wf.Data(ct).Exception;
   if ~wchar.Data(ct).Exception
      getUncertainPZData(wf.DataSrc,wf,wchar.Data,ioflag,PadeOrder);
   end
end

