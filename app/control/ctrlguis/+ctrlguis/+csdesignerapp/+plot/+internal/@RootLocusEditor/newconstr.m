function [out,constrClassTypes] = newconstr(this,keyword,CurrentConstr)
%NEWCONSTR  Interface with dialog for creating new constraints.
%
%   [LIST,CLASSTYPES] = NEWCONSTR(Editor) returns the list of all available
%   constraint types for this editor.
%
%   CONSTR = NEWCONSTR(Editor,TYPE) creates a constraint of the
%   specified type.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% RE: Editor.newconstr(type,currentconstr) is reserved for calls by newdlg

ReqDB = {...
    'SettlingTime', ...
            getString(message('Control:compDesignTask:strSettlingTimeL')), ...
            'editconstr.SettlingTime',     'srorequirement.settlingtime';...
    'PercentOvershoot', ...
            getString(message('Control:compDesignTask:strPercentOvershootL')), ...
            'editconstr.DampingRatio',     'srorequirement.dampingratio';...
    'DampingRatio', ...
            getString(message('Control:compDesignTask:strDampingRatioL')), ...
            'editconstr.DampingRatio',     'srorequirement.dampingratio'; ...
    'NaturalFrequency', ...
            getString(message('Control:compDesignTask:strNaturalFrequencyL')), ...
            'editconstr.NaturalFrequency', 'srorequirement.naturalfrequency'; ...
    'RegionConstraint', ...
            getString(message('Control:compDesignTask:strRegionConstraintL')), ...
            'editconstr.PZLocation',       'srorequirement.pzlocation'};

ni = nargin;
if ni==1
    % Return list of valid constraints
    out = ReqDB(:,[1 2]);
    if nargout == 2
        constrClassTypes = unique(ReqDB(:,3));
    end
else
    keyword = localCheckKeyword(keyword,ReqDB);
    idx     = strcmp(keyword,ReqDB(:,1));
    Class   = ReqDB{idx,3};
    dClass  = ReqDB{idx,4};
    
    % Create instance
    reuseInstance = ni>2 && isa(CurrentConstr,Class);
    if reuseInstance && (strcmpi(keyword,'PercentOvershoot') || strcmpi(keyword,'DampingRatio'))
        if strcmp(keyword,'PercentOvershoot') && strcmp(CurrentConstr.Type,'damping') || ...
                strcmp(keyword,'DampingRatio') && strcmp(CurrentConstr.Type,'overshoot')
            reuseInstance = false;
        end
    end
    if reuseInstance
        % Recycle existing instance if of same class
        Constr = CurrentConstr;
    else
        %Create new requirement instance
        reqObj    = feval(dClass);
        %Ensure requirement has correct feedback sign
        reqObj.FeedbackSign = 1;
        %Create corresponding requirement editor class
        Constr    = feval(Class,reqObj);
        Constr.Ts = this.Data.Ts;
        
        if strcmp(keyword,'PercentOvershoot')
            Constr.Type = 'overshoot';
        elseif strcmp(keyword,'DampingRatio')
            Constr.Type = 'damping';
        elseif strcmp(keyword,'NaturalFrequency')
            if Constr.Ts, Constr.Requirement.setData('xdata',1/Constr.Ts); end
            Constr.setDisplayUnits('xunits',this.Preferences.FrequencyUnits);
        elseif strcmp(keyword,'SettlingTime') && Constr.Ts
            Constr.Requirement.setData('xData',10*Constr.Ts);
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
    'Settling time'; ...
    'Percent overshoot'; ...
    'Damping ratio'; ...
    'Natural frequency'; ...
    'Region constraint'};
strTr = ReqDB(:,2);
idx = strcmp(kIn,strTr) | strcmp(kIn,strEng);
if any(idx)
    kOut = ReqDB{idx,1};
else
    kOut = [];
end
