function [indx,w] = passiveplot(varargin)
%passiveplot  Plots passivity index as a function of frequency.
%
%   passiveplot(G) plots the relative passivity indices as a function of
%   frequency. When I+G is minimum phase, these are the singular values
%   of (I-G(jw))/(I+G(jw)). The largest singular value R(w) measures the
%   relative excess (R<1) or shortage (R>1) of passivity at each frequency
%   w. The frequency range and number of points are chosen automatically.
%
%   passiveplot(G,'input') plots the input passivity index NU as a function
%   of frequency. This is the smallest eigenvalue of (G(jw)+G'(jw))/2.
%
%   passiveplot(G,'output') plots the output passivity index RHO as a
%   function of frequency. When G is minimum phase, this is the smallest
%   eigenvalue of (inv(G(jw))+inv(G(jw))')/2.
%
%   passiveplot(G,'io') plots the I/O passivity index TAU as a function
%   of frequency. When I+G is minimum phase, this is the largest TAU(w)
%   such that
%       G(jw)+G'(jw) > 2 * TAU(w) * (I+G'(jw)*G(jw))
%   at all frequencies w.
%
%   passiveplot(G,...,{WMIN,WMAX}) plots the passivity index for
%   frequencies ranging between WMIN and WMAX in radians/TimeUnit (relative
%   to the time units specified in G.TimeUnit, the default being seconds).
%
%   passiveplot(G,...,W) uses the frequency vector W (in radians/TimeUnit)
%   to evaluate the frequency response. See LOGSPACE to generate
%   logarithmically spaced frequency vectors.
%
%   passiveplot(G1,G2,...) draws the passivity indices of several systems
%   G1,G2,... on a single plot. You can also specify a color, line style,
%   and marker for each system, for example,
%      passiveplot(G1,'r',G2,'y--',G3,'gx').
%
%   [INDX,W] = passiveplot(G) and [INDX,W] = passiveplot(G,STRING) return
%   the passivity index data INDX and the frequency points W used in
%   the plot. No plot is drawn on the screen. The matrix INDX has length(W)
%   columns and INDX(:,k) gives the passivity index (in descending order)
%   at the frequency W(k). The frequencies W are in rad/TimeUnit.
%
%   INDX = passiveplot(G,W) and INDX = passiveplot(G,STRING,W) explicitly
%   specify the vector W of frequency points.
%
%   Example: Plot the input passivity index of G(s) = (s+2)/(s+1).
%       G = tf([1 2],[1 1]);
%       passiveplot(G,'input')
%   It can be seen from the figure that the input passivity index is
%   greater than 0 so the system G is passive.
%
%   See also isPassive, getPassiveIndex, getSectorIndex, sectorplot,
%   SIGMAPLOT, BODE, NICHOLS, NYQUIST, FREQRESP, LTIVIEW, DYNAMICSYSTEM.

%   Copyright 1986-2015 The MathWorks, Inc.


% Note on passivity Index type: 1 for input passivity index, 2 for output
% passivity index, 3 for I/O passivity index and 4 for relative


% Get input/output size of dynamic systems
for ct = 1:nargin
    if isa(varargin{ct},'DynamicSystem') || isa(varargin{ct},'iddata')
        [ny,nu] = iosize(varargin{ct});
        break;
    end
end

% sys must be non-empty square system
if (ny ~= nu) || (ny < 1)
    error(message('Control:analysis:isPassiveSquare'));
end


% Specify the index type with one of the following strings: 'input',
% 'output' and 'io'. If more than one index type is specified, then only
% the first index type is applied.
type = 4;
for ct = 1:nargin
    if ischar(varargin{ct}) || isStringScalar(varargin{ct})
        if strncmpi(varargin{ct},'input',2)
            varargin{ct} = [];
            type = 1; % input passivity index
            break;
        elseif strncmpi(varargin{ct},'output',3)
            varargin{ct} = [];
            type = 2; % output passivity index
            break;
        elseif strncmpi(varargin{ct},'io',2)
            varargin{ct} = [];
            type = 3; % I/O passivity index
            break;
        end
    end
end


% Handle various calling sequences
try
    if nargout>0
        % Call with output arguments
        [sysList,Extras] = DynamicSystem.parseRespFcnInputs(varargin);
        [sysList,M0,W1,W2,wspec] = DynamicSystem.checkPassivityInputs(sysList,Extras,type);
        sys = sysList(1).System;
        if (numel(sysList)>1 || nmodels(sys)~=1)
            error(message('Control:analysis:RequiresSingleModelWithOutputArgs','passiveplot'))
        end

        % Compute index vs frequency
        if (type == 1) || (type == 2) % IFP/OFP
            [indx,w,FocusInfo,InfFlag] = ifpofpresp_(sys,type,wspec);
        end
        if (type == 3) || (type == 4) % Relative/IO
            sys = [sysList(1).System;eye(nu)]; % Pass [H;I] to sectorresp
            [indx,w,FocusInfo,InfFlag] = sectorresp_(sys,M0,W1,W2,wspec);
        end
        if InfFlag
            error(message('Control:analysis:passiveplot'))
        end

        % For auto-generated W, make W(1) and W(end) entire decades
        if isempty(wspec) || iscell(wspec)
            userFocus = ltipack.getFreqFocus(wspec,sys.Ts,'log');
            [w,isel] = ltipack.util.roundFreqFocus(userFocus,FocusInfo.Focus,w);
            indx = indx(:,isel);
        end

        % Calculate the IO index from relative indices
        if (type ==3) %IO
            nf = size(indx,2);
            if nu > 1
                Index = max(indx);
                indx = zeros(1,nf);
            else
                Index = indx;
            end
            for ct = 1:nf
                if isnan(Index(ct))
                    indx(ct) = NaN;
                elseif isinf(Index(ct))
                    indx(ct) = -1/2;
                else
                    indx(ct) = 1/2*(1-Index(ct)^2)/(1+Index(ct)^2);
                end
            end
        end

    else
        % Plot index vs frequency
        ni = nargin;
        ArgNames = cell(ni,1);
        for ct=1:ni
            ArgNames(ct) = {inputname(ct)};
        end

        % Check for axes argument
        if ishghandle(varargin{1})
            hParent = varargin{1};
            varargin(1) = [];
            ArgNames(1) = [];
        else
            hParent = [];
        end

        [sysList,Extras,OptionsObject] = DynamicSystem.parseRespFcnInputs(varargin,ArgNames);
        if ~isempty(OptionsObject) && ~isa(OptionsObject,'plotopts.SectorPlotOptions')
            error('Controllib:plots:InvalidPlotOptions',...
                getString(message('Controllib:plots:InvalidPlotOptions','sectorplotoptions')));
        end
        [sysList,~,~,~,w] = DynamicSystem.checkPassivityInputs(sysList,Extras,type);

        TimeUnits = sysList(1).System.TimeUnit; % first system determines units
        % Check time unit consistency when specifying w or {wmin,wmax}
        if ~(isempty(w) || ltipack.hasMatchingTimeUnits(TimeUnits,sysList.System))
            error(message('Control:analysis:AmbiguousFreqSpec'))
        end

        % Create passiveplot using control charts
        switch type
            case 1
                type = 'input';
            case 2
                type = 'output';
            case 3
                type = 'io';
            case 4
                type = 'relative';
        end
        controllib.chart.internal.utils.ltiplot("passive",hParent,...
            SystemData=sysList,Frequency=w,Type=type,Options=OptionsObject);
    end
catch E
    throw(E)
end