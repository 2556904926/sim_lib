function [Gmout,Pm,Wcg,Wcp,isStable] = margin(varargin)
%MARGIN  Gain and phase margins and crossover frequencies.
%
%   [Gm,Pm,Wcg,Wcp] = MARGIN(SYS) computes the gain margin Gm, the phase
%   margin Pm, and the associated frequencies Wcg and Wcp, for the SISO
%   open-loop model SYS (continuous or discrete). The gain margin Gm is
%   defined as 1/G where G is the gain at the -180 phase crossing. The
%   phase margin Pm is in degrees. The frequencies Wcg and Wcp are in
%   radians/TimeUnit (relative to the time units specified in SYS.TimeUnit,
%   the default being seconds).
%
%   The gain margin in dB is derived by
%      Gm_dB = 20*log10(Gm)
%   The loop gain at Wcg can increase or decrease by this many dBs before
%   losing stability, and Gm_dB<0 (Gm<1) means that stability is most
%   sensitive to loop gain reduction.  If there are several crossover
%   points, MARGIN returns the smallest margins (gain margin nearest to
%   0dB and phase margin nearest to 0 degrees).
%
%   For a S1-by...-by-Sp array of linear systems, MARGIN returns
%   arrays of size [S1 ... Sp] such that
%      [Gm(j1,...,jp),Pm(j1,...,jp)] = MARGIN(SYS(:,:,j1,...,jp)) .
%
%   [Gm,Pm,Wcg,Wcp] = MARGIN(SYS,Focus=[FMIN,FMAX]) computes the gain and
%   phase margins in the frequency range [FMIN,FMAX]
%
%   [Gm,Pm,Wcg,Wcp] = MARGIN(MAG,PHASE,W) derives the gain and phase margins
%   from the Bode magnitude, phase, and frequency vectors MAG, PHASE, and W
%   produced by BODE. MARGIN expects gain values MAG in absolute units and
%   phase values PHASE in degrees. Interpolation is performed between
%   frequency points to approximate the true stability margins.
%
%   MARGIN(SYS), by itself, plots the open-loop Bode plot with the gain
%   and phase margins marked with a vertical line.
%
%   MARGIN(SYS,{WMIN,WMAX}) draws the Bode plot for frequencies between
%   WMIN and WMAX in radians/TimeUnit (relative to the time units specified
%   in SYS.TimeUnit, the default being seconds).
%
%   MARGIN(SYS,W) uses the vector W of frequencies (in radians/TimeUnit) to
%   evaluate the frequency response. This is required for sparse models.
%
%   See also ALLMARGIN, DISKMARGIN, BODEPLOT, BODE, LTIVIEW, DYNAMICSYSTEM.

%   Andrew Grace, P.Gahinet, A.DiVergilio, J.Glass 1-02
%   Copyright 1986-2013 The MathWorks, Inc.

%   Note: if there is more than one crossover point, margin will
%   return the worst case gain and phase margins.

%#function resppack.MinStabilityMarginData
%#function resppack.MarginPlotCharView
if ishghandle(varargin{1})
   hParent = varargin{1};
   varargin(1) = [];
else
   hParent = [];
end
sys = varargin{1};
if ~issiso(sys)
    error(message('Control:analysis:margin1'))
end

% Handle case when called w/o output argument
if nargout
    % Compute margins
    if ~any(nargin==[1 3]) || ~isempty(hParent)
        error(message('Control:analysis:margin5'))
    end
    try
        s = allmargin(sys,varargin{2:end});
    catch E
        error(E.identifier,strrep(E.message,'allmargin','margin'))
    end

    % Initialize output arrays
    asizes = size(s);
    nsys = prod(asizes);  % number of models
    Gmout = zeros(asizes);  Wcg = zeros(asizes);
    Pm = zeros(asizes);  Wcp = zeros(asizes);
    isStable = zeros(asizes);
    for m=1:nsys
        % Compute min (worst-case) gain margins
        [Gmout(m),Pm(m),~,Wcg(m),Wcp(m),isStable(m)] = ltipack.getMinMargins(s(m));
    end

    if nsys==1 && s.Stable==0
        warning(message('Control:analysis:MarginUnstable'))
    end
else
    % Plot margins

    try
        varargin(1) = argname2sysname(varargin(1),{inputname(1)});
        [sysList,Extras,OptionsObject] = DynamicSystem.parseRespFcnInputs(varargin);
        if numel(sysList)>1
            error(message('Control:general:InvalidSyntaxForCommand','margin','margin'))
        elseif nmodels(sysList.System)~=1
            error(message('Control:analysis:RequiresSingleModelWithNoOutputArgs','margin'))
        end
    catch E
        throw(E)
    end

    % Bode response plot

    if controllibutils.CSTCustomSettings.getCSTPlotsVersion == 2
        h = bodeplot(varargin{:});
        h.Characteristics.MinimumStabilityMargins.Visible = true;
        addMarginSubtitle(h);
    else
        % Create plot (visibility ='off')
        try
            [sysList,w] = DynamicSystem.checkBodeInputs(sysList,Extras);
        catch ME
            throw(ME)
        end
        ax = gca;
        h = ltiplot(ax,'bode',sys.InputName,sys.OutputName,OptionsObject,cstprefs.tbxprefs);

        % Handle
        TimeUnits = sys.TimeUnit;
        if isnumeric(w)
            w = unique(w);
        end
        h.setFreqFocus(w,['rad/' TimeUnits]);  % w is in rad/TimeUnit

        % Create responses
        src = resppack.ltisource(sys,'Name',sysList.Name);
        r = h.addresponse(src);
        r.DataFcn = {'magphaseresp' src 'bode' r w};
        % Styles and preferences
        initsysresp(r,'bode',h.Options,sysList.Style)

        % Add margin display
        r.addchar('Stability Margins','resppack.MinStabilityMarginData', ...
            'resppack.MarginPlotCharView');

        % Draw now
        if strcmp(h.AxesGrid.NextPlot,'replace')
            h.Visible = 'on';  % new plot created with Visible='off'
        else
            draw(h);  % hold mode
        end

        % Right-click menus
        ltiplotmenu(h,'margin');
    end
end
