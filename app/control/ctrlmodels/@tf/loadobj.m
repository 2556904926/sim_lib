function sys = loadobj(s)
%LOADOBJ  Load filter for tf objects

%   Copyright 1986-2011 The MathWorks, Inc.
if isa(s,'tf')
   % MCOS
   sys = DynamicSystem.updateMetaData(s);
   sys.Version_ = ltipack.ver();
else
   % Issue warning
   updatewarn
   % Upgrade
   if isfield(s,'num')
      % Versions 1-4
      sys = tf(s.num,s.den);
      sys = reload(sys,s.lti);
      sys.Variable = s.Variable;
      loadver = s.lti.Version;
   else
      % Versions 5-9 (LTI2 - two-layer architecture)
      sys = tf;
      sys = reload(sys,s.lti);
      sys.Variable = s.Variable;
      loadver = s.lti.dynamicsys.Version;
   end
   % Remap q to z^-1 starting with R2009a
   if loadver<9 && strcmp(sys.Variable,'q')
      sys.Variable = 'z^-1';
   end
end


