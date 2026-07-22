function [y,t,focus,x,ysd,p] = timeresp_(sys,RespType,t,pSpec,Config)
% LTV/LPV simulation with STEP/IMPULSE/INITIAL.

%   Copyright 2022 The MathWorks, Inc.
[ny,nu] = size(sys);
nx = sys.Nx_;
nfd = sys.Nfd_;
Ts = abs(sys.Ts);
ysd = [];
NEEDX = (nargout>3);
INITIAL = strcmp(RespType,'initial');
LPV = isLPV(sys);
np = nparam(sys);
PNUM = isnumeric(pSpec);

% Interpret T (start, stop, step size)
[t,t0,tf,dt] = ltipack.util.getTimeInfo(t,Ts);
focus = [t0,tf];
if isempty(t)
   if Ts>0
      t = (t0:dt:tf).';
   elseif PNUM && ~isempty(pSpec)
      t = linspace(t0,tf,size(pSpec,1)).';
   else
      t = linspace(t0,tf,1001).';
   end
end
Ns = numel(t);

% Quick exit for systems w/o inputs (step/impulse only)
if nu==0 && ~INITIAL
   y = zeros(Ns,ny,0);  x = zeros(Ns,nx,0);
   if LPV
      p = zeros(Ns,np,0);
   else
      p = [];
   end
   return
end

% Check parameters, put samples along column dimension
if PNUM
   if np>0
      if size(pSpec,2)~=np
         if isempty(pSpec)
            error(message('Control:analysis:LPV2'))
         else
            error(message('Control:analysis:rfinputs23'))
         end
      end
      pSpec = pSpec.';
   else
      pSpec = zeros(0,numel(t));
   end
else
   if np>0 && Ts==0 && strcmp(RespType,'impulse')
      error(message('Control:analysis:LPV1'))
   end
end

% Choose solver
DF = sys.DataFunction_;
if Ts>0
   ODEFUN = @ltvpack.DSIM;
   tk0 = round(t0/Ts);  % t0 or k0
else
   if isnumeric(pSpec)
      ODEFUN = @ltvpack.TRBDF2;
   else
      ODEFUN = @ltvpack.TRBDF2x;
   end
   tk0 = t0;
end
OPTS = struct('RELINPUT',false,'DIRAC',[],'NEEDX',NEEDX); % solver options


if INITIAL
   % Initial response (free response with u(t)=u0(t) and x(t0)=x0)
   OPTS.RELINPUT = true;
   ut = zeros(nu,Ns);
   xinit = Config.InitialState; % value
   if numel(xinit)~=nx
      error(message('Control:analysis:timeresp1'))
   end
   if np>0
      % Resolve PINIT
      if isnumeric(pSpec)
         pinit = pSpec(:,1);
      else
         % PINIT required for p=F(t,x,u)
         pinit = Config.InitialParameter;
         if isempty(pinit)
            error(message('Control:analysis:rfinputs30'))
         elseif numel(pinit)~=np
            error(message('Control:analysis:rfinputs31',np))
         end
      end
   else
      pinit = zeros(0,1);
   end
   opspec = ltioptions.findop(x=xinit,u=0,w=0,y=0);
   IC = setop_(sys,tk0,pinit,opspec);
   [y,x,p,WARN] = ODEFUN(DF,ut,t,pSpec,IC,OPTS);

else
   % STEP and IMPULSE
   Config = validate(Config,nu);
   xinit = Config.InitialState; % [], value, or 'x0'
   uinit = Config.Bias;
   du = Config.Amplitude;
   nDelay = Config.Delay/(t(2)-t(1)); % step/impulse delay in sampling periods
   OPTS.RELINPUT = (ischar(uinit));
   X0IC = (ischar(xinit));
   IMPLICIT_IC = (OPTS.RELINPUT || X0IC || isempty(xinit));
   if ~(X0IC || isempty(xinit) || numel(xinit)==nx)
      error(message('Control:analysis:timeresp1'))
   end

   % Resolve implicit initial condition (done once for all sims)
   if IMPLICIT_IC
      % Resolve PINIT and evaluate offsets X0 and UW0
      pinit = zeros(0,1);
      if LPV
         if PNUM
            pinit = pSpec(:,1);
         elseif np>0
            % PINIT must be specified when P(t) and U(t) or X(t0) are implicit
            pinit = Config.InitialParameter;
            if isempty(pinit)
               error(message('Control:analysis:rfinputs27'))
            elseif numel(pinit)~=np
               error(message('Control:analysis:rfinputs31',np))
            end
         end
         [~,~,~,~,~,~,x0,uw0] = DF(tk0,pinit);
      else
         [~,~,~,~,~,~,x0,uw0] = DF(tk0);
      end
      if X0IC
         % XINIT is x0(t0,p(t0))
         if isempty(x0)
            xinit = zeros(nx,1);
         else 
            xinit = x0;
         end
      end
      if OPTS.RELINPUT
         % Bias is [u0;w0](t0,p(t0))
         if isempty(uw0)
            uw0 = zeros(nu+nfd,1);
         end
         if isempty(xinit)
            % Find steady x for u=u0(t0,p(t0)) and w=w0(t0,p(t0)). When
            % dx0=0 and z0=w0, this gives x=x0(t0,p(t0)) which corresponds
            % to the steady-state operating condition (x0,u0,w0). 
            [IC,SINGULAR] = findop(sys,tk0,pinit,u=uw0(1:nu,:),w=uw0(nu+1:end,:),dw=NaN);
            if SINGULAR
               error(message('Control:analysis:step4'))
            end
         else
            % Unsteady IC, assume y=0 prior to start
            opspec = ltioptions.findop(x=xinit,u=uw0(1:nu,:),w=uw0(nu+1:end,:),y=0);
            IC = setop_(sys,tk0,pinit,opspec);
         end
      else
         % Bias is explicitly specified as UINIT
         if isempty(xinit)
            % Find steady-state IC for constant input
            [IC,SINGULAR] = findop(sys,tk0,pinit,u=uinit);
            if SINGULAR
               error(message('Control:analysis:step2'))
            end
         else
            % Unsteady IC, assume w,y=0 prior to start
            opspec = ltioptions.findop(x=xinit,u=uinit,w=0,y=0);
            IC = setop_(sys,tk0,pinit,opspec);
         end
      end
   end

   % Allocate
   y = zeros(Ns,ny,nu);
   if NEEDX
      x = zeros(Ns,nx,nu);
   else
      x = zeros(0,0,nu);
   end
   p = zeros(Ns,np,nu);
   WARN = false(Ns,nu);

   % Simulate each channel
   for j=1:nu
      % Input signal
      if OPTS.RELINPUT
         ut = zeros(nu,Ns); % relative to u0(t)
      else
         ut = repmat(uinit,[1 Ns]);
      end
      if RespType(1)=='s'
         kx = round(nDelay)+1:Ns;   ut(j,kx) = ut(j,kx)+du(j);
      elseif Ts==0
         uP = zeros(nu,1);   uP(j) = du(j);
         OPTS.DIRAC = struct('j',j,'nDelay',nDelay,'u',uP);
      else
         kx = round(nDelay)+1;   ut(j,kx) = ut(j,kx)+du(j)/dt;
      end

      % Resolve explicit IC (values of XINIT,UNIT explicitly specified)
      if ~IMPLICIT_IC
         pinit = zeros(0,1);
         if np>0
            % Resolve PINIT (depends on u(t0) in p=F(t,x,u) case)
            if PNUM
               pinit = pSpec(:,1);
            else
               try
                  pinit = pSpec(tk0,xinit,ut(:,1));
               catch
                  error(message('Control:analysis:rfinputs25'))
               end
               if ~isequal(size(pinit),[np 1])
                  error(message('Control:analysis:rfinputs26',np))
               end
            end
         end
         opspec = ltioptions.findop(x=xinit,u=uinit,w=0,y=0);
         IC = setop_(sys,tk0,pinit,opspec);
      end

      % Call solver
      [y(:,:,j),x(:,:,j),p(:,:,j),WARN(:,j)] = ODEFUN(DF,ut,t,pSpec,IC,OPTS);
   end
   WARN = any(WARN,2);
end

% Warn when failed to solver nonlinear equations to full accuracy
if any(WARN)
   tWarn = t(WARN);
   s1 = sprintf('%.2e',tWarn(1));  s2 = sprintf('%.2e',tWarn(end));
   if Ts>0
      warning(message('Control:analysis:LTV4',s1,s2))
   else
      warning(message('Control:analysis:LTV3',s1,s2))
   end
end
