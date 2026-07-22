function [y,x,p,POD] = lsim_(sys,u,t,IC,pSpec,~,~)
% LTV/LPV simulation with LSIM.
% IC = operating condition just before start.

%   Copyright 2022-2024 The MathWorks, Inc.
Ts = getTs_(sys);
nx = sys.Nx_;
np = nparam(sys);
PNUM = isnumeric(pSpec);
POD = [];

% Check compatibility, put samples along column dimension
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
end
u = u.';  

% Resolve initial condition when specified as XINIT
if isa(IC,'RespConfig')
    IC = IC.InitialState;
end
if isnumeric(IC)
   % Convert XINIT to OperatingPoint data structure
   xinit = IC;
   if isempty(xinit)
      xinit = zeros(nx,1);
   elseif numel(xinit)~=nx
      error(message('Control:analysis:timeresp1'))
   end
   if Ts==0
      tk = t(1);
   else
      tk = round(t(1)/Ts);
   end
   if np>0
      if PNUM
         pinit = pSpec(:,1);
      else
         % p = F(t,x,u)
         try
            pinit = pSpec(tk,xinit,u(:,1));
         catch
            error(message('Control:analysis:rfinputs25'))
         end
         if ~isequal(size(pinit),[np 1])
            error(message('Control:analysis:rfinputs26',np))
         end
      end
   else
      pinit = [];
   end
   % Set past u,w,y to zero for backward compatibility
   opspec = ltioptions.findop(x=xinit,u=0,w=0,y=0);
   IC = setop_(sys,tk,pinit,opspec);
else
   % IC is an ltipack.OperatingCondition
   [ny,nu] = size(sys);
   checkSize(IC,nx,ny,nu,sys.Nfd_);
end

% Call solver
% Note: Uses IC.u, IC.y, IC.w as past values in the presence of delays
OPTS = struct('RELINPUT',false,'DIRAC',[],'NEEDX',nargout>1);
if Ts>0
   [y,x,p,WARN] = ltvpack.DSIM(sys.DataFunction_,u,t,pSpec,IC,OPTS);
elseif isnumeric(pSpec)
   [y,x,p,WARN] = ltvpack.TRBDF2(sys.DataFunction_,u,t,pSpec,IC,OPTS);
else
   [y,x,p,WARN] = ltvpack.TRBDF2x(sys.DataFunction_,u,t,pSpec,IC,OPTS);
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
