function [indx,w] = sectorplot(varargin)
%SECTORPLOT  Plots sector index as a function of frequency.
%
%   SECTORPLOT(H,Q) plots the relative sector indices (R-indices) as a
%   function of frequency. These indices measure by how much the sector
%   bound is satisfied (R<1) or violated (R>1) at a given frequency. The
%   frequency range and number of points are chosen automatically.
%
%   SECTORPLOT(H,...,{WMIN,WMAX}) plots the R-indices for frequencies
%   ranging between WMIN and WMAX in radians/TimeUnit (relative to the
%   time units specified in H.TimeUnit, the default being seconds).
%
%   SECTORPLOT(H,...,W) uses the frequency vector W (in radians/TimeUnit)
%   to evaluate the frequency response. See LOGSPACE to generate
%   logarithmically spaced frequency vectors.
%
%   SECTORPLOT(H1,H2,...,Q,...) draws the  R-indices of several systems
%   H1,H2,... on a single plot. You can also specify a color, line style,
%   and marker for each system, for example,
%      sectorplot(H1,'r',H2,'y--',H3,'gx',Q).
%
%   [INDX,W] = SECTORPLOT(H,Q) return the R-index data INDX and frequency
%   points W used in the plot. No plot is drawn on the screen. The matrix
%   INDX has length(W) columns and INDX(:,k) gives the R-indices in
%   descending order at the frequency W(k). The frequencies W are in
%   rad/TimeUnit.
%
%   INDX = SECTORPLOT(H,Q,W) explicitly specify the vector W of frequency
%   points.
%
%   Note: If Q = W1*W1'-W2*W2' is a decomposition of Q into its positive
%   and negative parts, this plot only makes sense when W2'*H has a proper
%   stable inverse, in which case the R-indices are the singular values of
%   (W1'*H(jw))/(W2'*H(jw)).
%
%   Example: Use SECTORPLOT to check if the I/O trajectories of
%   G(s)=(s+2)/(s+1) belong to the sector 0.1*u^2 < u*y < 10*u^2. The Q
%   matrix for this sector is
%       a = 0.1;  b = 10;  Q = [1 -(a+b)/2 ; -(a+b)/2 a*b];
%   Plot the R-index for Q and H=[G;1]:
%       G = tf([1 2],[1 1]);
%       sectorplot([G;1],Q)
%   It can be seen from the plot that the R-index is less than one at all
%   frequencies so the graph of G fits in the specified sector Q.
%
%   See also sectorplotoptions, getSectorIndex, passiveplot, sigma, bode, nyquist.

%   Copyright 1986-2015 The MathWorks, Inc.

% Handle various calling sequences
try
    if nargout>0
        % Call with output arguments
        [sysList,Extras] = DynamicSystem.parseRespFcnInputs(varargin);
        [sysList,~,M0,W1,W2,wspec] = DynamicSystem.checkSectorInputs(sysList,Extras);
        sys = sysList(1).System;
        if (numel(sysList)>1 || nmodels(sys)~=1)
            error(message('Control:analysis:RequiresSingleModelWithOutputArgs','sectorplot'))
        end
        % Compute index vs frequency
        [indx,w,FocusInfo,InfFlag] = sectorresp_(sys,M0,W1,W2,wspec);
        if InfFlag
            error(message('Control:analysis:sectorplot4'))
        end
        % For auto-generated W, make W(1) and W(end) entire decades
        if isempty(wspec) || iscell(wspec)
            userFocus = ltipack.getFreqFocus(wspec,sys.Ts,'log');
            [w,isel] = ltipack.util.roundFreqFocus(userFocus,FocusInfo.Focus,w);
            indx = indx(:,isel);
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

        [sysList,Q,~,~,~,w] = DynamicSystem.checkSectorInputs(sysList,Extras);


        TimeUnits = sysList(1).System.TimeUnit; % first system determines units
        % Check time unit consistency when specifying w or {wmin,wmax}
        if ~(isempty(w) || ltipack.hasMatchingTimeUnits(TimeUnits,sysList.System))
            error(message('Control:analysis:AmbiguousFreqSpec'))
        end
        controllib.chart.internal.utils.ltiplot("sector",hParent,...
            SystemData=sysList,Frequency=w,Q=Q,Options=OptionsObject);

    end
catch E
    throw(E)
end
