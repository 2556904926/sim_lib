function sys = loadobj(s)
%LOADOBJ  Load filter for zpk objects

%   Author(s): G. Wolodkin
%   Copyright 1986-2011 The MathWorks, Inc.
if isa(s,'zpk')
   % MCOS
   sys = DynamicSystem.updateMetaData(s);
   sys.Version_ = ltipack.ver();
else
   % Issue warning
   updatewarn
   % Upgrade
   if isfield(s,'z')
      % Versions 1-4
      sys = zpk(s.z,s.p,s.k);
      sys = reload(sys,s.lti);
      sys.Variable = s.Variable;
      if isfield(s,'DisplayFormat')
         % Note: DisplayFormat introduced in R13, but version was not
         % changed (remained V3)...
         sys.DisplayFormat = s.DisplayFormat;
      end
      loadver = s.lti.Version;
   else
      % Versions 5-9 (LTI2 - two-layer architecture)
      sys = zpk;
      sys = reload(sys,s.lti);
      sys.Variable = s.Variable;
      sys.DisplayFormat = s.DisplayFormat;
      loadver = s.lti.dynamicsys.Version; 
   end
   % Remap q to z^-1 starting with R2009a
   if loadver<9 && strcmp(sys.Variable,'q')
      sys.Variable = 'z^-1';
   end
end


