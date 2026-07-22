function [varargout] = hsvplot(varargin)
%   HSVPLOT is obsolete, use REDUCESPEC and the VIEW method instead.
%
%   See also REDUCESPEC, MOR.VIEW.

% Old help
%HSVPLOT  Plots the Hankel singular values of an LTI model.
%
%   HSVPLOT(SYS) plots the Hankel singular values (HSVs) of the LTI model 
%   SYS. See BALRED for details on the meaning and purpose of HSVs. The
%   HSVs for the stable and unstable modes of SYS are shown in blue and 
%   red, respectively. Reduced-order models of various orders can be
%   obtained by dropping the states associated with the smallest HSVs.
%   HSVPLOT also shows the maximum approximation error as a function 
%   of the approximation order (number of states in reduced-order model).
%
%   HSVPLOT(AX,SYS,...) attaches the plot to the axes AX.
%
%   HSVPLOT(...,NUMOPTIONS,PLOTOPTIONS) specifies additional options for 
%   computing and plotting the results. Use BALREDOPTIONS to create 
%   NUMOPTIONS and HSVOPTIONS to create PLOTOPTIONS.
%
%   H = HSVPLOT(...) returns the handle H to the Hankel singular 
%   value plot. You can use this handle to customize the plot 
%   with the GETOPTIONS and SETOPTIONS commands. See HSVOPTIONS
%   for a list of available plot options.
%
%   Example:
%      sys = rss(20);
%      % Plot HSVs for relative-error method
%      numopt = balredOptions('ErrorBound','relative');
%      h = hsvplot(sys,numopt);
%      % Switch to linear scale
%      setoptions(h,'Yscale','linear')
%
%   See also HSVOPTIONS, BALREDOPTIONS, BALRED.

%   Copyright 1986-2024 The MathWorks, Inc.
no = nargout;

% Check for parent argument
if ishghandle(varargin{1})
    hParent = varargin{1};
    varargin(1) = [];
else
    hParent = [];
end

% Get system
sys = varargin{1};

% Validate data and read options
if nmodels(sys)~=1
   error(message('Control:general:RequiresSingleModel','hsvplot'))
elseif any(iosize(sys)==0)
   % System without input or output
   error(message('Control:transformation:NotSupportedNoInputsorOutputs','hsvplot'))
end

% Options
ixn = find(cellfun(@(x) isa(x,'ltioptions.balred'),varargin));
ixp = find(cellfun(@(x) isa(x,'plotopts.HSVOptions'),varargin));
if isempty(ixp)
   PlotOptions = [];
   if isempty(ixn)
      % Watch for obsolete PV pair syntax:
      % hsvplot(sys,'offset',1.5,'AbsTol',1e-5,'RelTol',1e-4,'FreqIntervals',[0 2],'TimeIntervals',[3 5]);
      try
         NumOptions = balredOptions(varargin{2:end});
      catch ME
         error(ME.identifier,strrep(ME.message,'balred','hsvplot'))
      end
   else
      NumOptions = varargin{ixn};
   end
else
   PlotOptions = varargin{ixp};
   if isempty(ixn)
      % Backward compatibility: Remap BALRED options that used to live in hsvoptions
      NumOptions = balredOptions();
      NumOptions.AbsTol = PlotOptions.AbsTol;
      NumOptions.RelTol = PlotOptions.RelTol;
      NumOptions.Offset = PlotOptions.Offset;
      NumOptions.FreqIntervals = PlotOptions.FreqIntervals;
      NumOptions.TimeIntervals = PlotOptions.TimeIntervals;
   else
      NumOptions = varargin{ixn};
   end
end

% Get MOR data
try
   % Watch for REDUCESPEC supporting sparse and LPV
   R = reducespec(ss(sys),'balanced');
catch
   % Conversion to SS failed
   error(message('Control:general:NotSupportedModelsofClass','hsvplot',class(sys)))
end
R.Options = mapOptions(R.Options,NumOptions);
try
   R = process(R);
catch ME
   throw(ME)
end

% Create plot
if isempty(PlotOptions)
    viewOpts = struct();
else
    viewOpts = get(PlotOptions);
end
if ~isempty(hParent)
    viewOpts.Parent = hParent;
end
viewOpts = namedargs2cell(viewOpts);
try
    h = view(R,'sigma',viewOpts{:});
catch ME
    throw(ME)
end

% Return handle if requested
if no>0
   varargout = {h};
end
