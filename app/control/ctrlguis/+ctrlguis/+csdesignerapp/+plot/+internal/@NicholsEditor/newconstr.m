function [out,constrClassTypes] = newconstr(this, keyword, CurrentConstr)
%NEWCONSTR  Interface with dialog for creating new constraints.
%
%   [LIST,CLASSTYPES] = NEWCONSTR(Editor) returns the list of all available
%   constraint types for this editor.
%
%   CONSTR = NEWCONSTR(Editor,TYPE) creates a constraint of the 
%   specified type.

%   Author(s): P. Gahinet, B. Eryilmaz
%   Revised: A. Stothert
%   Copyright 1986-2011 The MathWorks, Inc. 

ReqDB = {...
      'PhaseMargin', ...
            getString(message('Controllib:graphicalrequirements:lblPhaseMargin')), ...
            'editconstr.GainPhaseMargin', 'srorequirement.gainphasemargin';...
      'GainMargin', ...
            getString(message('Controllib:graphicalrequirements:lblGainMargin')), ....
            'editconstr.GainPhaseMargin', 'srorequirement.gainphasemargin';...
      'CLPeakGain', ...
            getString(message('Controllib:graphicalrequirements:lblClosedLoopPeakGain')), ...
            'editconstr.NicholsPeak',     'srorequirement.nicholspeak'; ...
      'GPRequirement', ...
            getString(message('Controllib:graphicalrequirements:lblGainPhaseRequirement')), ...
            'editconstr.NicholsLocation', 'srorequirement.nicholslocation'};

if nargin == 1
   % Return list of valid constraints
   out = ReqDB(:,[1 2]);
   if nargout == 2
      constrClassTypes = ReqDB(:,3);
   end
else
   keyword = localCheckKeyword(keyword,ReqDB);
   idx     = strcmp(keyword,ReqDB(:,1));
   Class   = ReqDB{idx,3};
   dClass  = ReqDB{idx,4};
   switch keyword
      case 'PhaseMargin'
         Type  = 'phase';
      case 'GainMargin'
         Type  = 'gain';
      case 'CLPeakGain'
         Type  = 'upper';
      case 'GPRequirement'
         Type  = 'lower';
   end
   
   % Create instance
   if nargin > 2 && isa(CurrentConstr, Class)
      % Recycle existing instance
      Constr = CurrentConstr; 
      Constr.Requirement.setData('type',Type);
   else
      % Create new instance
      reqObj = feval(dClass);
      reqObj.setData('type',Type);
      Constr = feval(Class,reqObj);
      Constr.setDisplayUnits('xunits',this.Axes.PhaseUnit);
      Constr.setDisplayUnits('yunits','dB');
   end
   out = Constr;
end

%--------------------------------------------------------------------------
function kOut = localCheckKeyword(kIn,ReqDB)
%Helper function to check keyword is correct, mainly needed for backwards
%compatibility with old saved constraints

if any(strcmp(kIn,ReqDB(:,1)))
   %Quick return is already an identifier
   kOut = kIn;
   return
end

%Handle case where gainphasemargin requirement is one object
if strcmp(kIn,'GainPhaseMargin')
   kOut = 'PhaseMargin';
   return
end

%Now check display strings for matching keyword, may need to translate kIn
%from an earlier saved version
strEng = {...
    'Phase margin'; ...
    'Gain margin'; ...
    'Closed-Loop peak gain'; ...
    'Gain-Phase requirement'};
strTr = ReqDB(:,2);
idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
if any(idx)
   kOut = ReqDB{idx,1};
else
   kOut = [];
end
