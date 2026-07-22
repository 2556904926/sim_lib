function Code = genScalarCode(TS)
% EML code generation for scalar-valued tunable surface.

%   Author(s): P. Gahinet
%   Copyright 1986-2017 The MathWorks, Inc.
Coeffs = getScaledCoefficients(TS);
BasisFcn = TS.BasisFunctions;
NS = TS.Normalization;

% Get parameter names
pNames = fieldnames(TS.SamplingGrid) + "_";

% Header
args = sprintf('%s,',pNames);
reftype = sprintf('%s+',pNames);
Code = [...
   "function Gain_ = fcn(" + args(1:end-1) + ")"
   "%#codegen"
   ""];
if isempty(BasisFcn)
   % Gain is constant
   Code = [Code
      "Gain_ = cast(" + mat2str(Coeffs) + ",'like'," + reftype(1:end-1) + ");"];
else
   % Varying gain
   if isscalar(pNames)
      Code = [Code
         "% Tuned gain surface coefficients"
         "ZERO = zeros(1,1,'like'," + pNames + ");"];
   else
      Code = [Code
         "% Type casting"
         "ZERO = zeros(1,1,'like'," + reftype(1:end-1) + ");"
         pNames + " = cast(" + pNames + ",'like',ZERO);"
         ""
         "% Tuned gain surface coefficients"];
   end
   Code = [Code
      "Coeffs = cast(" + mat2str(Coeffs) + ",'like',ZERO);"
      "Offsets = cast(" + mat2str(NS.InputOffset) + ",'like',ZERO);"
      "Scalings = cast(" + mat2str(NS.InputScaling) + ",'like',ZERO);"
      ""];
   
   % Normalization
   if isscalar(pNames)
      IX = "";
   else
      IX = "(" + (1:numel(pNames))' + ")";
   end
   Code = [Code
      "% Normalization "
      pNames + " = (" + pNames + " - Offsets" + IX + ")/Scalings" + IX + ";"
      ""];
   
   % Set up basis outer product
   Finfo = functions(BasisFcn);
   if contains(Finfo.function,'utFcnBasisOuterProduct(FDATA_')
      % Basis constructed with helper POLYBASIS, FOURIERBASIS, NDBASIS
      FH = Finfo.workspace{1}.FDATA_;
   else
      FH = {BasisFcn};
   end
   ndim = numel(FH);
   if ndim==1
      % Generate code for single basis
      Code = [Code ; localSingleDim(FH{1},pNames)];
   else
      % Generate code for outer product of bases
      k = 0;
      for ct=1:ndim
         nargs = nargin(FH{ct});
         Code = [Code ; evaluateAlongDim(ct,FH{ct},pNames(k+1:k+nargs))];
         k = k+nargs;
      end
      % Generate code for weighted outer product
      Code = [Code ; localWeightedOuterProduct(ndim)];
   end
end

Code = sprintf('%s\n',Code);


%--------------------

function Code = localSingleDim(FH,pNames)
% Generates code for problems with single dimension, e.g.
%    Gain = sum Coeffs(k) Y(k)
% where Y = F(X) = [F1(X) ... FN(X)]. Note that X may be a vector, or,
% more precisely, F can take multiple inputs, as in
%    F = @(x,y) [x y x*y]
Finfo = functions(FH);
if endsWith(Finfo.file,'polyBasis.m')
   % Created with POLYBASIS
   deg = Finfo.workspace{1}.m;  % degree>0
   if contains(Finfo.function,'canonical','IgnoreCase',true)
      Code = [
         "% Compute weighted sum of monic terms"
         "deg = " + deg + ";"
         "Y = " + pNames + ";"
         "Gain_ = Coeffs(1) + Y * Coeffs(2);"
         "for i=2:deg"
         "   Y = Y * " + pNames + ";"
         "   Gain_ = Gain_ + Coeffs(i+1) * Y;"
         "end"];
   else
      Code = [
         "% Compute weighted sum of Chebyshev terms"
         "deg = " + deg + ";"
         "Y1 = 1;"
         "Y2 = " + pNames + ";"
         "Gain_ = Coeffs(1) + Y2 * Coeffs(2);"
         "for i=2:deg"
         "   Ynext = (2.0 * " + pNames + ") * Y2 - Y1;"
         "   Gain_ = Gain_ + Coeffs(i+1) * Ynext;"
         "   Y1 = Y2;"
         "   Y2 = Ynext;"
         "end"];
   end
elseif endsWith(Finfo.file,'fourierBasis.m')
   % Created with FOURIERBASIS
   m = Finfo.workspace{1}.m;  % >0
   Code = [
      "% Compute weighted sum of Fourier series terms"
      "m = " + m + ";"
      "PI_X = pi * " + pNames + ";"
      "Gain_ = Coeffs(1) + cos(PI_X) * Coeffs(2) + sin(PI_X) * Coeffs(3);"
      "for i=2:m"
      "   aux = i * PI_X;"
      "   Gain_ = Gain_  + cos(aux) * Coeffs(2*i) + sin(aux) * Coeffs(2*i+1);"
      "end"];
else
   % User-specified basis
   expr = getExpression(Finfo,pNames);
   Code = [
      "% Compute weighted sum of terms"
      "Y = [ " + expr + " ];"
      "Gain_ = Coeffs(1);"
      "for i=1:numel(Y)"
      "   Gain_ = Gain_ + Coeffs(i+1) * Y(i);"
      "end"];
end


function Code = localWeightedOuterProduct(ndim)
% Writes code to compute weighted sum of outer product of several
% vectors or arrays:
%    Gain = sum  Coeffs(i1,i2,...,iN) Y1(i1) Y2(i2) ... YN(iN)
% where Y1,Y2,...,YN are vectors or arrays with DIMS(1),...,DIMS(N)
% entries. The indices i1,...,iN run throught the length of each
% vector.
INDENT = "";
Code = [...
   "% Compute weighted sum of Yj's outer product:"
   "%     Gain = sum  Coeffs(i1,i2,...,iN) Y1(i1) Y2(i2) ... YN(iN)"
   "Gain_ = ZERO;"
   "k = 1;"
   ];
PROD = "";
for ct=ndim:-1:1
   aux = strrep([INDENT + "for i?=1:numel(Y?)"," * Y?(i?)" + PROD],...
      "?",string(ct));
   Code(end+1) = aux(1); %#ok<*AGROW>
   PROD = aux(2);
   INDENT = INDENT + "   ";
end
Code = [Code
   INDENT + "Gain_ = Gain_ + Coeffs(k)" + PROD + ";";
   INDENT + "k = k+1;"];
for ct=1:ndim
   INDENT = extractBefore(INDENT,strlength(INDENT)-2);
   Code(end+1,1) = INDENT + "end";
end