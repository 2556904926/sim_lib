function [out,constrClassTypes] = newconstr(this,keyword,CurrentConstr)
%NEWCONSTR  Interface with dialog for creating new constraints.
%
%   [LIST,CLASSTYPES] = NEWCONSTR(Editor) returns the list of all available
%   constraint types for this editor.
%
%   CONSTR = NEWCONSTR(Editor,TYPE) creates a constraint of the 
%   specified type.

%   Author(s): P. Gahinet
%   Copyright 1986-2023 The MathWorks, Inc. 

ReqDB = {...
       'UpperGainLimit', getString(message('Control:compDesignTask:strUpperGainLimit')),  ...
                'editconstr.BodeGain', 'srorequirement.bodegain'; ...
       'LowerGainLimit', getString(message('Control:compDesignTask:strLowerGainLimit')), ...
                'editconstr.BodeGain', 'srorequirement.bodegain'; ...
       'GPMargins', getString(message('Control:compDesignTask:strGainAndPhaseMargin')),  ...
                'editconstr.GainPhaseMargin', 'srorequirement.gainphasemargin'};

ni = nargin;
if ni==1
    % Return list of constraints that can be added. Check don't already have 
    % @bodegpm constraint
    currConstr = this.findconstr;
    noGPM = true;
    ct = 1;
    while ct <= numel(currConstr) && noGPM
       noGPM = noGPM && ~isa(currConstr(ct),'plotconstr.bodegpm');
       ct = ct + 1;
    end
    if noGPM
       idx = 1:size(ReqDB,1);
    else
       idx = [1 2];
    end
    out = ReqDB(idx,[1 2]);
    if nargout == 2
       constrClassTypes = unique(ReqDB(idx,3));
    end  
else
   keyword = localCheckKeyword(keyword,ReqDB);
   idx     = strcmp(keyword,ReqDB(:,1));
   Class   = ReqDB{idx,3};
   dClass  = ReqDB{idx,4};
   switch keyword
      case 'UpperGainLimit'
         Type   = 'upper';
         xUnits = char(this.Axes.FrequencyUnit);
         yUnits = char(this.Axes.MagnitudeUnit);

      case 'LowerGainLimit'
         Type   = 'lower';
         xUnits = char(this.Axes.FrequencyUnit);
         yUnits = char(this.Axes.MagnitudeUnit);

      case 'GPMargins'
         Type   = 'both';
         yUnits = char(this.Axes.MagnitudeUnit);  %Magnitude
         xUnits = char(this.Axes.PhaseUnit);  %Phase
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
      Constr.setDisplayUnits('xunits',xUnits);
      Constr.setDisplayUnits('yunits',yUnits);
   end
    
   %Special initialization for bode gain constr
   if strcmp(Class,'editconstr.BodeGain')
      % Set sample time and units
      Constr.Ts = this.Data.Ts;
      % Make sure constraint is below Nyquist freq.
      if Constr.Ts
         Constr.Requirement.setData('xData',(pi/Constr.Ts) * [0.01 0.1]);
      end
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

%Now check display strings for matching keyword, may need to translate kIn
%from an earlier saved version
strEng = {...
    'Upper gain limit'; ...
    'Lower gain limit'; ...
    'Gain & Phase margins'};
strTr = ReqDB(:,2);
idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
if any(idx)
   kOut = ReqDB{idx,1};
else
   kOut = [];
end

