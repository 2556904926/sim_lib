function TG = getGoal(this,method,varargin)
%getGoal  Get tuning goal at specific design point.
%
%   When tuning controllers for multiple operating conditions, the
%   "varyingGoal" object lets you adjust the tuning objectives as a
%   function of the design point. Use getGoal to evaluate a variable goal
%   at a particular design point or for particular values of the 
%   sampling variables (fields of VG.SamplingGrid).
%
%   TG = getGoal(VG,'index',K) returns the effective tuning goal TG at
%   the K-th design point. VG is a varyingGoal object and the absolute
%   index K is relative to the arrays of parameter values VG.Parameters
%   and the grid of design points VG.SamplingGrid when specified.
%
%   TG = getGoal(VG,'index',K1,K2,...) returns the effective tuning goal
%   TG at the design point with coordinates (K1,K2,...). These coordinates
%   are interpreted as indices into the multi-dimensional arrays contained
%   in VG.Parameters and VG.SamplingGrid.
%
%   When the design points are obtained by sampling one or more variables
%   and the sample values are specified in VG.SamplingGrid,
%      TG = getGoal(VG,'value',x1,x2,...)
%   lets you use the values x1,x2,... of these variables to refer to a
%   particular design point. For example, if VG.SamplingGrid specifies a
%   grid of design points (a,b),
%      TG = getGoal(VG,'value',-1,3)
%   returns the tuning goal at the design point (a,b)=(-1,3). If
%   (x1,x2,...) does not match any point in VG.SamplingGrid, getGoal 
%   returns the nearest point in a relative sense. See lti.SamplingGrid   
%   and tunableSurface for more detail on model sampling.
%
%   Note: getGoal returns TG=[] when any of the tuning goal parameters is
%   NaN at the specified design point. NaN values indicate that the goal
%   is inactive at this point.
%
%   See also varyingGoal, TuningGoal, tunableSurface, systune.

%   Copyright 1986-2015 The MathWorks, Inc.
narginchk(2,Inf)
method = ltipack.matchKey(method,{'index','value'});
if isempty(method)
   error(message('Control:tuning:getGoal1'))
elseif ~all(cellfun(@numel,varargin)==1)
   error(message('Control:tuning:getGoal2'))
end
% Build argument list
RP = this.Parameters_;
np = numel(RP);
args = cell(1,np);
switch method
   case 'index'
      try
         if numel(varargin)>1
            % Convert to absolute index
            k = sub2ind(size(RP{1}),varargin{:});
         else
            k = varargin{1};
         end
         for ct=1:np
            args{ct} = RP{ct}(k);
         end
      catch ME
         throw(ME)
      end
   case 'value'
      % Find absolute index of nearest design point
      if isempty(this.SamplingGrid_)
         error(message('Control:tuning:getGoal3'))
      elseif numel(varargin)~=numel(getVariable(this.SamplingGrid_))
         error(message('Control:tuning:getGoal4'))
      end
      C = cellfun(@(x) x(:),struct2cell(this.SamplingGrid),'UniformOutput',false);
      SGV = cat(2,C{:});  % values of sampling grid variables, columnwise
      rgap = abs(SGV-[varargin{:}])./max(abs(SGV),[],1);
      % rgap = bsxfun(@rdivide,abs(bsxfun(@minus,SGV,[varargin{:}])),max(abs(SGV),[],1));
      [~,k] = min(max(rgap,[],2));
      for ct=1:np
         args{ct} = RP{ct}(k);
      end
end
         
if any(cellfun(@isnan,args))
   % NaNs are used to indicate design points at which the
   % requirement does not apply
   TG = [];
else
   try
      TG = this.Template(args{:});
   catch ME
      str = sprintf('%0.3g,',args{:});
      error(message('Control:tuning:getGoal5',k,str(1:end-1),ME.message))
   end
   if ~(isa(TG,'TuningGoal.Generic') && ~isa(TG,'varyingGoal') && isscalar(TG))
      error(message('Control:tuning:getGoal6'))
   end
   % Configure goal
   if ~isempty(this.Settings)
      try
         TG = set(TG,this.Settings{:});
      catch ME
         error(message('Control:tuning:getGoal7',class(TG),ME.message))
      end
   end
   TG.Model = k;
   TG.Name = this.Name;
end
