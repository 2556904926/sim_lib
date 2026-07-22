function W = gram(sys,type,varargin)
%GRAM  Controllability and observability gramians.
%
%   Wc = GRAM(SYS,'c') computes the controllability gramian of
%   the state-space model SYS (see SS).
%
%   Wo = GRAM(SYS,'o') computes its observability gramian.
%
%   In both cases, the state-space model SYS should be stable.
%   The gramians are computed by solving the Lyapunov equations:
%
%     *  A*Wc + Wc*A' + BB' = 0  and   A'*Wo + Wo*A + C'C = 0
%        for continuous-time systems
%               dx/dt = A x + B u  ,   y = C x + D u
%
%     *  A*Wc*A' - Wc + BB' = 0  and   A'*Wo*A - Wo + C'C = 0
%        for discrete-time systems
%           x[n+1] = A x[n] + B u[n] ,  y[n] = C x[n] + D u[n].
%
%   Wc = GRAM(SYS,'c',OPTIONS) computes the time/frequency limited
%   controllability gramian of the state-space model SYS (see SS). 
%   Time and frequency intervals are defined in OPTIONS (see GRAMOPTIONS).
%
%   Wo = GRAM(SYS,'o',OPTIONS) computes its time/frequency limited
%   observability gramian.
%
%   For arrays of LTI models SYS, Wc and Wo are double arrays
%   such that
%      Wc(:,:,j1,...,jN) = GRAM(SYS(:,:,j1,...,jN),'c') .
%      Wo(:,:,j1,...,jN) = GRAM(SYS(:,:,j1,...,jN),'o') .
%
%   Rc = GRAM(SYS,'cf') and Ro = GRAM(SYS,'of') return the Cholesky
%   factors of gramians (Wc = Rc'*Rc and Wo = Ro'*Ro).
%
%   See also SS, BALREAL, CTRB, OBSV.

%   Laub, A., "Computation of Balancing Transformations", Proc. JACC
%     Vol.1, paper FA8-E, 1980.

if isStringScalar(type)
    type = char(type);
end

% type check
if ~(ischar(type) && any(lower(type(1))=='co'))
   error(message('Control:foundation:gram2'))
end

try
    if nargin<3
        Options = gramOptions;
    else
        if isa(varargin{1},'ltioptions.gram')
            Options = varargin{1};
        else     
            Options = gramOptions(varargin{:});
        end
    end
    % Compute gramians
    W = gram_(sys,type,Options);
catch E
    ltipack.throw(E,'command','gram',class(sys))
end

if hasdelay(sys)
   % Warn about ignoring delays
   warning(message('Control:analysis:GramIgnoreDelay'))
end

