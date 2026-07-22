function Code = evaluateAlongDim(dim,FH,pNames)
% Generates code that evaluates and caches the function values along
% dimension DIM of multi-dimensional basis functions.

%   Copyright 1986-2017 The MathWorks, Inc.
Finfo = functions(FH);
if endsWith(Finfo.file,'polyBasis.m')
   % Created with POLYBASIS
   deg = Finfo.workspace{1}.m;  % degree>0
   Code = [
      "% Evaluate monic terms for variable " + pNames
      "deg = " + deg + ";"];
   if contains(Finfo.function,'canonical','IgnoreCase',true)
      % 1,x,...,x^deg
      Code = [Code
         "Y? = coder.nullcopy(zeros(deg+1,1,'like',ZERO));"
         "Y?(1) = 1;"
         "Y?(2) = " + pNames + ";"
         "for i?=2:deg"
         "   Y?(i?+1) = " + pNames + " * Y?(i?);"
         "end"
         ""];
   else
      Code = [Code
         "Y? = coder.nullcopy(zeros(deg+1,1,'like',ZERO));"
         "Y?(1) = 1;"
         "Y?(2) = " + pNames + ";"
         "for i?=2:deg"
         "   Y?(i?+1) = (2.0*" + pNames + ") * Y?(i?) - Y?(i?-1);"
         "end"
         ""];
   end
   Code = strrep(Code,"?",string(dim));
   
elseif endsWith(Finfo.file,'fourierBasis.m')
   % Created with FOURIERBASIS
   m = Finfo.workspace{1}.m;  % >0
   Code = [
      "% Evaluate Fourier series terms for variable " + pNames
      "m = " + m + ";"
      "PI_X = pi * " + pNames + ";"
      "Y? = coder.nullcopy(zeros(2*m+1,1,'like',ZERO));"
      "Y?(1) = 1;"
      "Y?(2) = cos(PI_X);"
      "Y?(3) = sin(PI_X);"
      "for i?=2:m"
      "   aux = i? * PI_X;"
      "   Y?(2*i?) = cos(aux);"
      "   Y?(2*i?+1) = sin(aux);"
      "end"
      ""];
   Code = strrep(Code,"?",string(dim));
   
else
   % User-specified basis
   expr = getExpression(Finfo,pNames);
   pstr = sprintf('%s,',pNames);
   Code = [
      "% Evaluate terms for variable " + pstr(1:end-1)
      "Y" + dim + " = [ 1 , " + expr + " ];"
      ""];
end