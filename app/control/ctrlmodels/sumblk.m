function M = sumblk(Formula,varargin)
%SUMBLK  Specify summing junctions in block diagrams.
%
%   You can use SUMBLK in conjunction with CONNECT to connect linear models
%   and build aggregate models of block diagrams.
%
%   S = SUMBLK(FORMULA) returns the transfer function S for the summing 
%   junction described by FORMULA. The string FORMULA specifies the equation  
%   relating the input and output signals. For example, the formula 
%   'e = r-y+d' specifies a summing junction with input names {'r';'y';'d'}, 
%   output name {'e'}, and equation e = r-y+d. All signals are assumed to be
%   scalar valued.
%
%   S = SUMBLK(FORMULA,SIGNALSIZE) specifies a summing junction involving 
%   vector-valued signals with SIGNALSIZE elements. For example, 
%      s = sumblk('v = u + d',2)
%   specifies the junction
%      v(1) = u(1)+d(1),   v(2) = u(2)+d(2).
%   The input and output names of S are {'u(1)';'u(2)';'d(1)';'d(2)'} and
%   {'v(1)';'v(2)'}, respectively.
%
%   You can use aliases in FORMULA to refer to signal names defined in a 
%   variable or another model. For example,
%      s = sumblk('%e = r - %y', C.u, G.y)
%   uses "%e" and "%y" to refer to the input names of C and output names 
%   of G. The signal "r" inherits its size from C.u and G.y. The number of 
%   extra arguments after FORMULA must match the number of occurrences of 
%   "%" in FORMULA.
%
%   Example: To model the summing junction
%      e(1) = setpoint(1) - alpha + d(1)
%      e(2) = setpoint(2) - q + d(2)
%   type
%      s = sumblk('e = setpoint - %y + d', {'alpha';'q'})
%   Note that "%y" is used as an alias for the 2-by-1 signal {'alpha';'q'}.
%
%   See also CONNECT, SERIES, PARALLEL.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.
ni = nargin;
if ni<1
   error(message('Control:combination:sumblk1'))
end

if isStringScalar(Formula)
    Formula = char(Formula);
end

try
   if ischar(Formula) && contains(Formula,'=')
      [InputNames,OutputNames,Signs] = localParseFormula(Formula,varargin{:});
   else
      % Pre-R2011b syntax
      [InputNames,OutputNames,Signs] = localObsoleteSyntax(Formula,varargin{:});
   end
catch ME
   throw(ME)
end

% Construct SUMBLK model
SignalWidth = numel(OutputNames);
Gain = kron(Signs,eye(SignalWidth)); % gain matrix
M = tf(Gain,'InputName',InputNames,'OutputName',OutputNames);
end

%--------------------- local functions -----------------------

function [InputNames,OutputNames,Signs] = localParseFormula(Formula,varargin)
% Parse syntax
%    SUMBLK('e = r - y')
%    SUMBLK('e = r - y',3)
%    SUMBLK('%e = r - %y',S1,S2)
nopt = numel(varargin);

% Validate signature
np = sum(Formula=='%');
if np==0
   % No aliases
   switch nopt
      case 0
         SignalWidth = 1;
      case 1
         SignalWidth = varargin{1};
         if ~(isnumeric(SignalWidth) && isscalar(SignalWidth) && ...
               isreal(SignalWidth) && SignalWidth>0 && rem(SignalWidth,1)==0)
            error(message('Control:combination:sumblk2'))
         end
      otherwise
         error(message('Control:combination:sumblk3'))
   end
else
   if np==nopt
      for ct=1:nopt
         [ok,varargin{ct}] = ltipack.isNameList(varargin{ct});
         if ~ok
            error(message('Control:combination:sumblk4'))
         end
      end
   else
      error(message('Control:combination:sumblk7'))
   end
end

% Add sign in front of first signal if not already there
if isempty(regexp(Formula,'=\s*[+-]','once'))
   Formula = regexprep(Formula,'=','=+','once');
end

% Look for = sign in correct place and remove it
Tokens = regexp(Formula,'[=+-]','match');
ieq = find(strcmp(Tokens,'='));
if isequal(ieq,1)
   Tokens = Tokens(2:end);
   Formula = Formula(Formula~='=');
else
   error(message('Control:combination:sumblk5'))
end

% Get signal strings
Signals = regexp(Formula,'\s*[+-]\s*','split');
if any(cellfun('isempty',Signals))
   error(message('Control:combination:sumblk6'))
end
nsig = numel(Signals);

% Replace %placeholders by actual signal names
if np>0
   ip = find(strncmp(Signals,'%',1));
   if numel(ip)~=np
      error(message('Control:combination:sumblk9'))
   end
   Signals(ip) = varargin;
   SignalWidth = numel(Signals{ip(1)});
   for ct=2:np
      if numel(Signals{ip(ct)})~=SignalWidth
         error(message('Control:combination:sumblk8',2,ct+1))
      end
   end
end      

% Process other signal names in formula
for ct=1:nsig
   s = Signals{ct};
   if ischar(s)
      if SignalWidth>1
         % Treat as vector signal
         snames = cell(SignalWidth,1);
         for j=1:SignalWidth
            snames{j} = sprintf('%s(%d)',s,j);
         end
         Signals{ct} = snames;
      else
         Signals{ct} = {s};
      end
   end   
end

% Build output arguments
OutputNames = Signals{1};
InputNames = cat(1,Signals{2:nsig});
Signs = ones(1,nsig-1);
Signs(strcmp(Tokens,'-')) = -1;

end


function [InputNames,OutputNames,Signs] = localObsoleteSyntax(OutputNames,varargin)
% Backward compatibility support for pre-R2011b syntax.
%
%   S = SUMBLK(OUTPUT,INPUT1,...,INPUTN) returns the transfer function S 
%   for the summing junction OUTPUT = INPUT1 + ... + INPUTN.   The output
%   signal name(s) OUTPUT and input signal name(s) INPUT1,...,INPUTN are 
%   specified as strings for scalar-valued signals, and commensurate
%   cell arrays of strings for vector-valued signals. For example,
%      s = sumblk('u','u1','u2','u3')
%   specifies the summing junction u = u1 + u2 + u3, and
%      s = sumblk({'v1','v2'},{'u1','u2'},{'d1','d2'})
%   specifies the summing junction v = u + d where u,d,v are vector-valued
%   signals of length two. For MIMO systems, use STRSEQ to quickly
%   generate numbered channel names like {'e1';'e2';'e3'}. For example to
%   define e = r-y for vectors of length n, type
%      ej = strseq('e',1:n); %{'e1';'e2';...}
%      rj = strseq('r',1:n); %{'r1';'r2';...}
%      yj = strseq('y',1:n); 
%      s = sumblk(ej,rj,yj,'+-');
%
%   S = SUMBLK(OUTPUT,INPUT1,...,INPUTN,SIGNS) further specifies a sign
%   for each input signal. For example
%      s = sumblk('e','r','y','+-')
%   specifies the relationship e = r - y.
ni = nargin;
if ischar(OutputNames)
   OutputNames = {OutputNames};
elseif ~iscellstr(OutputNames)
   error(message('Control:combination:sumblkObsolete1'))
end
SignalWidth = numel(OutputNames);  % width of signal vector

% Look for sign input
if ni<3
   error(message('Control:combination:sumblkObsolete3'))
else
   SignStr = varargin{ni-1};
   if ischar(SignStr) && all(SignStr=='+' | SignStr=='-')
      nu = ni-2;
      if numel(SignStr)~=nu
         error(message('Control:combination:sumblkObsolete2'))
      end
      Signs(1,SignStr=='+') = 1;
      Signs(1,SignStr=='-') = -1;
   else
      nu = ni-1;
      Signs = ones(1,nu);
   end
   if nu<2
      error(message('Control:combination:sumblkObsolete3'))
   end
end

% Process inputs
for ct=1:nu
   Inct = varargin{ct};
   if ischar(Inct)
      Inct = {Inct};
   elseif ~iscellstr(Inct)
      error(message('Control:combination:sumblkObsolete4'))
   elseif length(Inct)~=SignalWidth
      error(message('Control:combination:sumblkObsolete5'))
   end
   varargin{ct} = Inct(:);
end
InputNames = cat(1,varargin{1:nu});
end



