function R = reducespec(sys,method)
%REDUCESPEC  Model order reduction (MOR) gateway.
%
%   Use this function to access various techniques for reducing the
%   complexity of dense or sparse LTI models.
%
%   R = REDUCESPEC(SYS,METHOD) creates a model reduction specification for
%   the dense or sparse LTI model SYS. METHOD selects the model reduction
%   algorithm among the following:
%      'balanced'   Balanced truncation.
%      'ncf'        Balanced truncation of normalized coprime factors
%                   (requires Robust Control Toolbox).
%      'pod'        Proper orthogonal decomposition.
%      'modal'      Modal truncation.
%      'zpk'        Zero/pole/gain truncation.
%      'frfit'      Frequency response fitting.
%   The properties of R depend on model type and method, type "help(R)" for
%   details. Use R.Options to further configure R, type "help(R.Options)"
%   for details.
%
%   For any MOR spec R,
%     * R = PROCESS(R) runs the MOR algorithm and populates R.
%     * VIEW(R,...) provides visual aids for order selection.
%     * [rsys,INFO] = GETROM(R,...) obtains a reduced-order model with the
%       desired characteristics.
%     * Use FINDOP to compute matching steady-state initial conditions for
%       the reduced-order model.
%   Type one of the following for details on VIEW and GETROM options:
%      help(R),
%      view(R,'-help')
%      getrom(R,'-help')
%
%   Example: Workflow for reducing a 30th-order state-space model using
%   balanced truncation:
%      sys = rss(30);
%      R = reducespec(sys,'balanced');
%      % Run algorithm once (optional, recommended for sparse)
%      R = process(R);
%      % Select order graphically
%      view(R)
%      % Get a reduced model of order 7
%      rsys = getrom(R,Order=7)
%
%   See also MOR.PROCESS, MOR.VIEW, MOR.GETROM, DynamicSystem/findop.

%   Copyright 2023 The MathWorks, Inc.
narginchk(2,2)
if nmodels(sys)~=1
   error(message('Control:transformation:ROM4'))
end
method = ltipack.matchKey(method,{'balanced','ncf','pod','modal','zpk','frfit'});
if isempty(method)
   error(message('Control:transformation:ROM5'))
end
try
   switch method
      case 'balanced'
         if isTimeVarying(sys)
            error(message('Control:transformation:ROM8'))
         elseif issparse(sys)
            R = mor.SparseBalancedTruncation(sys);
         else
            R = mor.BalancedTruncation(sys);
         end
      case 'ncf'
         if isTimeVarying(sys) || issparse(sys)
            error(message('Control:transformation:ROM7'))
         else
            R = mor.NCFBalancedTruncation(sys);
         end
      case 'pod'
         if isTimeVarying(sys)
            error(message('Control:transformation:ROM10'))
         else
            R = mor.ProperOrthogonalDecomposition(sys);
         end
      case 'modal'
         if isTimeVarying(sys)
            error(message('Control:transformation:ROM6'))
         elseif issparse(sys)
            R = mor.SparseModalTruncation(sys);
         else
            R = mor.ModalTruncation(sys);
         end
      case 'zpk'
         if isTimeVarying(sys)
            error(message('Control:transformation:ROM6'))
         else
            R = mor.SparseZeroPoleTruncation(sys);
         end
      case 'frfit'
         if isTimeVarying(sys)
            error(message('Control:transformation:ROM11'))
         else
            R = mor.FrequencyResponseFitting(sys);
         end
   end
catch ME
   throw(ME)
end
