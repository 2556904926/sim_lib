% Control System Toolbox -- Linear analysis.
%
% Graphical analysis.
%   linearSystemAnalyzer   - Time and frequency response app.
%
% Model characteristics.
%   <a href="matlab:help InputOutputModel/size">size</a>               - Size of model or model array.
%   isct               - Check if model is continuous.
%   isdt               - Check if model is discrete.
%   isproper           - Check if model is proper (relative degree <= 0).
%   <a href="matlab:help InputOutputModel/issiso">issiso</a>             - Check if model is single-input/single-output.
%   <a href="matlab:help InputOutputModel/isempty">isempty</a>            - Check if model is empty.
%
% System dynamics.
%   pole               - System poles.
%   zero               - Zeros and gain of SISO system.
%   tzero              - Invariant zeros of MIMO system.
%   order              - System order (number of states).
%   pzmap              - Pole-zero map.
%   iopzmap            - Input/output pole-zero map.
%   damp               - Natural frequency and damping of poles or zeros.
%   esort              - Sort continuous poles by real part.
%   dsort              - Sort discrete poles by magnitude.
%
% Modal and spectral decompositions.
%   modalsep           - Modal decomposition.
%   modalsum           - Sum of modal components.
%   stabsep            - Stable/unstable decomposition.
%   freqsep            - Slow/fast decomposition.
%   spectralfact       - Spectral factorization.
%
% Time-domain analysis.
%   step               - Step response.
%   stepinfo           - Step response characteristics (rise time, ...)
%   impulse            - Impulse response.
%   initial            - Free response with initial conditions.
%   lsim               - Response to user-defined input signal.
%   lsiminfo           - Linear response characteristics.
%   gensig             - Generate input signal for LSIM.
%   covar              - Covariance of response to white noise.
%
% Frequency-domain analysis.
%   bode               - Bode diagrams of the frequency response.
%   bodemag            - Bode magnitude diagram only.
%   nyquist            - Nyquist plot.
%   nichols            - Nichols plot.
%   sigma              - Singular value plot for MIMO frequency response.
%   freqresp           - Frequency response over a frequency grid.
%   evalfr             - Evaluate frequency response at given frequency.
%   dcgain             - Steady-state (D.C.) gain.
%   bandwidth          - System bandwidth.
%   getPeakGain        - Compute peak gain of frequency response.
%   getGainCrossover   - Gain crossover frequencies.
%   <a href="matlab:help DynamicSystem/norm">norm</a>               - H2 and Hinfinity norms of LTI systems.
%   mag2db             - Convert magnitude to decibels (dB).
%   db2mag             - Convert decibels (dB) to magnitude.
%
% Stability analysis.
%   <a href="matlab:help DynamicSystem/isstable">isstable</a>           - Check if system is stable.
%   margin             - Gain and phase margins.
%   allmargin          - All crossover frequencies and gain/phase margins.
%
% Passivity and sector bounds.
%   isPassive          - Check if linear system is passive.
%   getPassiveIndex    - Compute passivity index.
%   getSectorIndex     - Compute conic sector index.
%   getSectorCrossover - Crossover frequencies for sector bound.
%   passiveplot        - Plot passivity index vs. frequency.
%   sectorplot         - Plot sector index vs. frequency.

%   Copyright 1986-2015 The MathWorks, Inc. 