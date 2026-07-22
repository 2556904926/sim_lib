function varargout = balred(sys,varargin)
%   BALRED is obsolete, use REDUCESPEC(SYS,'balanced') instead.
%
%   See also REDUCESPEC.

%   Copyright 1986-2020 The MathWorks, Inc.

% Old help
%BALRED  Model order reduction via balanced truncation.
%
%   Balanced truncation is a state-of-the-art model reduction technique
%   providing both stability and tight absolute or relative error control.
%
%   [RSYS,INFO] = BALRED(SYS,ORDER) computes a reduced-order approximation
%   RSYS of the LTI model SYS. The desired order (number of states) is
%   specified by ORDER. You can try multiple orders at once by setting
%   ORDER to a vector of integers, in which case RSYS is an array of
%   reduced models. BALRED also returns a structure INFO with fields:
%      HSV             Hankel singular values (state contributions to the
%                      input/output behavior).
%      ErrorBound      Bound on absolute or relative approximation error.
%                      INFO.ErrorBound(J+1) bounds the error for order J.
%      Regularization  Regularization level (for relative error only).
%      Rr, Ro          Cholesky factors of Gramians.
%   When SYS is unstable, only its stable part is reduced.
%
%   [~,INFO] = BALRED(SYS) just computes the Hankel singular values and
%   error bounds. You can use this information to select the reduced order
%   ORDER based on desired fidelity.
%
%   BALRED(SYS) displays the same information on a plot. See also HSVPLOT
%   if you need to customize this plot.
%
%   [...] = BALRED(SYS,...,OPTIONS) specifies additional options for
%   eliminating states, using absolute vs. relative error bounds,
%   emphasizing certain time or frequency bands, and separating the stable
%   and unstable modes. Use BALREDOPTIONS to create and configure the
%   option set OPTIONS.
%
%   When performance is a concern, use the syntax
%      [~,info] = balred(sys);
%      <select order, interactively or programmatically>
%      rsys = balred(sys,order,info);
%   to avoid computing the Hankel singular values twice.
%
%   Example 1: Use the Hankel singular value to select suitable order and
%   compute reduced-order model:
%      rng(0), sys = drss(40);
%      balred(sys)
%      % Select order 15 and reduce
%      rsys = balred(sys,15);
%      sigma(sys,sys-rsys)   % verify absolute error
%
%   Example 2: Compute the minimum-order approximation with a relative 
%   error below 1%:
%      rng(0), sys = rss(50);  sys.d = 0;  % model of order 50
%      opt = balredOptions('ErrorBound','relative','StateProjection','truncate');
%      [~,info] = balred(sys);
%      % Find minimum order with less than 1% relative error
%      order = find(info.ErrorBound>0.01,1,'last')
%      rsys = balred(sys,order,opt,info);
%      sigma(sys,sys-rsys,{1e-2,1e4})  % verify relative error
%
%   See also BALREDOPTIONS, HSVPLOT, ORDER, BALREAL, MINREAL, SMINREAL.

if numsys(sys)~=1
   error(message('Control:general:RequiresSingleModel','balred'))
elseif any(iosize(sys)==0)
   % System without input or output
   error(message('Control:transformation:NotSupportedNoInputsorOutputs','balred'))
end

% Parse and validate input list
narg = numel(varargin);
% ORDERS
if narg>0 && isnumeric(varargin{1})
   orders = varargin{1}(:);  varargin(:,1) = [];  narg = narg-1;
   if ~(isnumeric(orders) && isreal(orders) && all(rem(orders,1)==0 & orders>=0))
      error(message('Control:transformation:balred2'))
   end
else
   orders = [];
end
% INFO
ix = find(cellfun(@(x) isa(x,'ltipack.balredInfo'),varargin));
if ~isempty(ix)
   Info = varargin{ix};  varargin(:,ix) = [];  narg = narg-1;
else
   Info = [];
end
% Backward compatibility: ignore BALDATA struct
ix = find(cellfun(@isstruct,varargin));
varargin(:,ix) = [];  narg = narg-numel(ix);
% OPTIONS
if narg==1 && isa(varargin{1},'ltioptions.balred')
   % balred(sys,...,options)
   Options = varargin{1};
else
   % Handle pre-R2010a syntax:
   % balred(sys,orders,'AbsTol',ATOL,'RelTol',RTOL,'Offset',ALPHA,'Elimination',METHOD,'Balancing',BALDATA)
   varargin(:,strncmpi(varargin,'b',1)) = [];  % watch for 'Balancing' leftover
   try
      Options = balredOptions(varargin{:});
   catch ME
      throw(ME)
   end
end
Options = validate(Options); % may warn about unsupported combinations

if isempty(orders)
   % No orders specified
   try
      % Watch for REDUCESPEC supporting sparse and LPV
      R = reducespec(ss(sys),'balanced');
   catch
      % Conversion to SS failed
      error(message('Control:general:NotSupportedModelsofClass','balred',class(sys)))
   end
   R.Options = mapOptions(R.Options,Options);
   try
      R = process(R);
      if nargout>0
         % Return Info
         Info = getBalredInfo(R);
         varargout = {[] Info};
      else
         % Plot data
         view(R,'sigma')
      end
   catch ME
      throw(ME)
   end
else
   try
      [rsys,Info] = balred_(sys,orders,Info,Options);
   catch ME
      ltipack.throw(ME,'command','balred',class(sys))
   end
   % Clear notes, userdata, etc
   rsys.Name = '';  rsys.Notes = {};  rsys.UserData = [];
   varargout = {rsys Info};
end
