function varargout = margin(a,b,c,d)
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

%Old help
%MARGIN Gain margin, phase margin, and crossover frequencies.
%   [Gm,Pm,Wcg,Wcp] = MARGIN(A,B,C,D) returns gain margin Gm,
%   phase margin Pm, and associated frequencies Wcg and Wcp, given
%   the continuous state-space system (A,B,C,D).
%
%   [Gm,Pm,Wcg,Wcp] = MARGIN(NUM,DEN) returns the gain and phase
%   margins for a system in s-domain transfer function form (NUM,DEN).
%
%   [Gm,Pm,Wcg,Wcp] = MARGIN(MAG,PHASE,W)  returns the gain and phase
%       margins given the Bode magnitude, phase, and frequency vectors 
%   MAG, PHASE, and W from a system.  In this case interpolation is 
%   performed between frequency points to find the values. This works
%   for both continuous and discrete systems.
%
%   When invoked without left hand arguments, MARGIN(A,B,C,D) plots
%   the Bode plot with the gain and phase margins marked with a 
%   vertical line. The gain margin, Gm, is defined as 1/G where G 
%   is the gain at the -180 phase frequency. 
%   20*log10(Gm) gives the gain margin in dB.  
%
%   See also IMARGIN.

%   Note: if there is more than one crossover point, margin will
%   return the worst case gain and phase margins. 

%   Andrew Grace 12-5-91
%   Copyright 1986-2011 The MathWorks, Inc.
ni = nargin;
no = nargout;
if ni==0,
   eval('exresp(''margin'')')
   return
end
narginchk(2,4);

% Validation for MARGIN(MAG,PHASE,W)
if ni==3
   nf = numel(c);  % w
   c = c(:);
   if ~(isnumeric(a) && isnumeric(b) && isnumeric(c) && ...
      isreal(a) && isreal(b) && isreal(c) && ...
      numel(a)==nf && numel(b)==nf)
      error(message('Control:analysis:margin2','margin'))
   elseif any(c<0) || any(diff(c)<=0)
      error(message('Control:analysis:margin3','margin'))
   elseif any(a(:)<0)
      error(message('Control:analysis:margin4','margin'))
   end
end

try
   if no==0,
      switch ni
         case 2
            margin(tf(a,b));
         case 3
            % This code path is NOT obsolete
            imargin(a(:),b(:),c(:));
         case 4
            margin(ss(a,b,c,d));
      end
   else
      switch ni
         case 2
            [varargout{1:no}] = margin(tf(a,b));
         case 3
            % This code path is NOT obsolete
            [varargout{1:no}] = imargin(a(:),b(:),c(:));
         case 4
            [varargout{1:no}] = margin(ss(a,b,c,d));
      end
   end
catch E
   throw(E)
end
