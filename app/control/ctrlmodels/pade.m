function [a,b,c,d] = pade(T,n)
%PADE  Pade approximation of time delays.
%
%   [NUM,DEN] = PADE(T,N) returns the Nth-order Pade approximation 
%   of the continuous-time delay exp(-T*s) in transfer function form.
%   The row vectors NUM and DEN contain the polynomial coefficients  
%   in descending powers of s.
%
%   When invoked without left-hand argument, PADE(T,N) plots the
%   step and phase responses of the N-th order Pade approximation 
%   and compares them with the exact responses of the time delay
%   (Note: the Pade approximation has unit gain at all frequencies).
%
%   SYSX = PADE(SYS,N) returns a delay-free approximation SYSX of 
%   the continuous-time delay system SYS by replacing all delays 
%   by their Nth-order Pade approximation.  The default is N=1.
%
%   SYSX = PADE(SYS,NU,NY,NINT) specifies independent approximation
%   orders for each input, output, and I/O or internal delay.  
%   Here NU, NY, and NINT are integer arrays such that
%     * NU is the vector of approximation orders for the input channels
%     * NY is the vector of approximation orders for the output channels
%     * NINT are the approximation orders for the I/O delays (TF or
%       ZPK models) or internal delays (state-space models)
%   You can use scalar values for NU, NY, or NINT to specify a uniform 
%   approximation order.  You can also set some entries of NU, NY, or 
%   NINT to Inf to prevent approximation of the corresponding delays.
%
%   See also DELAY2Z, C2D, LTI.

%   Andrew C.W. Grace 8-13-89
%   P. Gahinet   7-22-96, 5-98
%   Copyright 1986-2009 The MathWorks, Inc.

%  Reference:  Golub and Van Loan, Matrix Computations, John Hopkins
%              University Press, pp. 557ff.
arguments
    T (1,1) double {mustBeNonnegative,mustBeFinite}
    n (1,1) double {mustBeNonnegative,mustBeInteger}
end

% Compute coefficients
try
   [num,den] = padecoef(T,n);
catch E
   throw(E);
end
s = tf('s');
sys = exp(-s*T);
sysApprox = tf(num,den);

no = nargout;
if no==0
    % Graphical Output if no left hand arguments (step response and Bode plot)
    if T==0
        warning(message('Control:analysis:PadeZeroDelay'))
        return
    end

    f = gcf();
    clf(f);
    t = tiledlayout(f,2,1);
    t.Title.String = getString(message('Control:analysis:strPadeApproximationOrderN',n));
    t.Title.FontSize = get(cstprefs.tbxprefs,'TitleFontSize');
    t.Title.FontWeight = get(cstprefs.tbxprefs,'TitleFontWeight');
    t.Title.FontAngle = get(cstprefs.tbxprefs,'TitleFontAngle');

    sp = stepplot(t,sysApprox,sys,'--',2*T);
    sp.Responses(1).Name = getString(message('Control:analysis:strPadeApproximation'));
    sp.Responses(2).Name = getString(message('Control:analysis:strPureDelay'));
    sp.LegendVisible = true;
    sp.LegendLocation = "southeast";
    sp.Title.String = getString(message('Control:analysis:strStepComparison'));
	sp.Layout.Tile = 1;

    % Get frequency Wc where phase error becomes significant
    wc = log10(2*pi/T);        % initial guess
    w = logspace(wc-1,wc+3,50);
    fr = squeeze(freqresp(sysApprox,w));
    phase = unwrap(atan2(imag(fr),real(fr)));
    phase0 = -w'*T;               % exact phase shift
    idiff = find(abs(phase-phase0) > 0.1*abs(phase));
    wc = w(idiff(1));
    lwc = floor(log10(wc));
    if wc/10^lwc<5
        wc = lwc;
    else
        wc = lwc+1;
    end
    % Get detailed phase profile around Wc
    wmin = 10^(wc-1);
    wmax = 10^(wc+1);

    bp = bodeplot(t,sysApprox,sys,'--',{wmin,wmax});
    bp.MagnitudeVisible = false;
    bp.PhaseMatchingEnabled = true;
    bp.Responses(1).Name = getString(message('Control:analysis:strPadeApproximation'));
    bp.Responses(2).Name = getString(message('Control:analysis:strPureDelay'));
    bp.Title.String = getString(message('Control:analysis:strPhaseComparison'));
	bp.Layout.Tile = 2;
    if n ~= 0 %Limit to no more than twice minimum phase of approx
        phase1 = qeGetData(bp.Responses(1)).MatchedPhase{1};
        if strcmp(bp.PhaseUnit,"deg")
            phase1 = rad2deg(phase1);
        end
        bp.YLimits(1) = max(bp.YLimits(1),2*min(phase1));
    end
elseif no<=2
    % Return NUM and DEN
    a = sysApprox.Numerator{1};
    b = sysApprox.Denominator{1};
elseif no==3
    % Return Z,P,K
    sysApprox = zpk(sysApprox);
    a = sysApprox.Z{1};
    b = sysApprox.P{1};
    c = sysApprox.K;
else
    % Return A,B,C,D
    sysApprox = ss(sysApprox);
    a = sysApprox.A;
    b = sysApprox.B;
    c = sysApprox.C;
    d = sysApprox.D;
end
