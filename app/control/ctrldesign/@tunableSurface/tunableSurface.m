classdef (CaseInsensitiveProperties, TruncatedProperties) ...
      tunableSurface < tunableBlock & StaticModel
   %TUNABLESURFACE  Create tunable gain surface.
   %
   %   In gain-scheduled controllers, the gains change with the operating 
   %   condition and are "scheduled" as a function of one or more variables. 
   %   Tunable surfaces are used to parameterize and tune gain schedules.
   %   A tunable gain surface is a scalar- or matrix-valued function
   %      G(x) = G0 + f1(n(x)) G1 + ... + fm(n(x)) Gm
   %   where
   %     * x=(a,b,c,...) is the vector of scheduling variables
   %     * n(x) is a normalization function
   %     * f1,...,fm is a user-selected basis function expansion
   %     * G0,G1,...,Gm are tunable coefficients.
   %   The gain surface is shaped by tuning G0,G1,...,Gm over a set of
   %   a,b,c,... values called "design points" (see SYSTUNE).
   %
   %   GS = tunableSurface(NAME,G0,DOMAIN,SHAPEFCN) creates a tunable gain
   %   surface GS with design points DOMAIN and basis functions SHAPEFCN.
   %   The string NAME identifies the gain surface. The struct DOMAIN has
   %   fields a,b,c,... containing the scheduling variable values at each
   %   design point (type "help lti.SamplingGrid" for details). The function
   %   SHAPEFCN must take the normalized values of a,b,c,... as inputs and
   %   return the vector f=[f1,...,fm] of basis function values. The tunable
   %   surface GS is initialized to the constant gain G(x) = G0.
   %
   %   GS = tunableSurface(NAME,G0,DOMAIN) creates a flat surface with 
   %   constant gain. This is equivalent to using tunableGain(NAME,G0).
   %
   %   Note: 
   %     * The design points need not lay on a rectangular grid and can be 
   %       scattered across the operating range.
   %     * By default, the normalization function n(x) is chosen to map the
   %       ranges of a,b,c,... values in DOMAIN to [-1,1]^m. For example,
   %       if "a" ranges from amin to amax, then its normalized value is
   %                 a-(amin+amax)/2
   %           a_n = ---------------
   %                  (amax-amin)/2
   %       See "help tunableSurface.Normalization" to specify different 
   %       offsets and scaling factors.
   %
   %   Example 1: Create a cubic gain surface with scheduling variable t and
   %   design points t=[0:0.1:1]:
   %      Domain = struct('t',0:0.1:1)
   %      ShapeFcn = polyBasis('canonical',3); % x,x^2,x^3
   %      GS = tunableSurface('G',0,Domain,ShapeFcn);
   %   This parameterizes the gain as
   %      G(t) = G0 + x G1 + x^2 G2 + x^3 G3
   %   where x(t)=(t-0.5)/0.5 varies in [-1,1].
   % 
   %   Example 2: Using the 5x5 grid of design points:
   %      [alpha,V] = ndgrid(linspace(0,20,5),linspace(700,1300,5))
   %   create a multi-linear gain surface with scheduling variables alpha,V:
   %      Domain = struct('alpha',alpha,'V',V)
   %      ShapeFcn = @(x,y) [x y x*y]
   %      GS = tunableSurface('G',0,Domain,ShapeFcn);
   %   This parameterizes the gain as
   %      G(alpha,V) = G0 + x G1 + y G2 + x*y G3
   %   where x(alpha)=(alpha-10)/10 and y(V)=(V-1000)/300 vary in [-1,1].
   %
   %   See also GETDATA, SETDATA, POLYBASIS, FOURIERBASIS, NDBASIS, EVALSURF, 
   %   VIEWSURF, CODEGEN, GENMAT, GENSS, CONTROLDESIGNBLOCK, SYSTUNE.
   
%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.

   properties (Dependent)
      % Basis function expansion (function handle).
      %
      % Function that takes a vector x_n = n(x) of normalized scheduling
      % variable values and returns the vector [f1(x_n),...,fm(x_n)] of
      % basis function values at x_n. The default normalization function
      % n(x) improves the conditioning of gain surface tuning by centering
      % and scaling the scheduling variables x to keep them in the range
      % [-1,1]. Type "help tunableSurface" for details on the nomenclature.
      % Type "help tunableSurface.Normalization" to adjust the normalization
      % function.
      %
      % Use polyBasis to generate standard polynomial expansions, and use
      % fourierBasis to generate Fourier series expansions of gains that
      % must be periodic in the scheduling variables. For multi-dimensional
      % gain surfaces, you can use different basis function expansions for
      % each scheduling variable and use ndBasis to combine them into one
      % multi-dimensional basis function expansion.
      BasisFunctions
      % Tunable coefficients (realp).
      %
      % Vector or matrix [G0,G1,...,Gm] of tunable coefficients in the gain
      % surface parameterization:
      %    G(x) = G0 + f1(n(x)) G1 + ... + fm(n(x)) Gm .
      % This is what the tuning algorithm (systune) works with.
      Coefficients
      % Design points (struct).
      %
      % Here "design point" refers to one particular combination of
      % scheduling variable values used for tuning. The gain surface is
      % tuned by imposing tuning goals over a grid of design points that
      % adequately covers the operating range (range of values taken by 
      % the scheduling variables). 
      %
      % Specify the set of design points as a structure whose fields are 
      % named after the scheduling variables (type "help lti.SamplingGrid" 
      % for details and examples). The design points need not lie on a
      % rectangular grid and may be scattered throughout the operating range.
      SamplingGrid
      % Normalization (struct).
      %
      % Structure with fields InputOffset (vector), InputScaling (vector),
      % and OutputScaling (scalar). The gain value is computed as 
      %    G(x) = OutputScaling * (G0 + f1(n(x)) G1 + ... + fm(n(x)) Gm)
      % where 
      %    n(x) = (x-InputOffset)./InputScaling
      % is the normalized scheduling vector. Use normalization to compress
      % and equalize the numerical ranges of the scheduling variables, and
      % use OutputScaling to keep the tuned coefficients G0,...,Gm close to
      % one in magnitude.
      %
      % By default, OutputScaling=1 and InputOffset,InputScaling are 
      % computed to map the SamplingGrid domain to [-1,1]^m. Set the  
      % "Normalization" property to [] to revert to this default.
      Normalization
   end 
   
   properties (Access = protected)
      BasisFunctions_     % function handle
      Coefficients_       % realp
      SamplingGrid_       % ltipack.SamplingGrid
      nVar_               % scalar, number of variables
      nFun_               % scalar, number of basis functions
      % struct array caching user-defined normalization parameters.
      % Default is [] (normalization derived from SamplingGrid)
      Normalization_
   end
      
   %% TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genmat';
      end
      
      % Note: getAttributes never called (first converted to GENMAT)
   end
    
   %% PUBLIC METHODS
   methods
      
      function blk = tunableSurface(name,G0,Domain,ShapeFcn)
         ni = nargin;
         if ni==0
            blk.nVar_ = 0;  blk.nFun_ = 0;  blk.IOSize_ = [0 0];  return
         elseif ni<3
            error(message('Control:general:InvalidSyntaxForCommand',...
               'tunableSurface','tunableSurface'))
         end
         if ~isvarname(name)
            error(message('Control:lftmodel:BlockName1'))
         elseif ~(isnumeric(G0) && isreal(G0) && ismatrix(G0))
            error(message('Control:lftmodel:tunableSurface1'))
         end
         ios = size(G0);
         blk.IOSize_ = ios;
         % Domain
         try
            SG = ltipack.SamplingGrid(Domain);
         catch ME
            throw(ME)
         end
         nVars = numel(getVariable(SG));
         blk.SamplingGrid_ = SG;
         blk.nVar_ = nVars;
         % Basis functions
         if ni<4 || isempty(ShapeFcn)
            blk.nFun_ = 0;
         else
            if ~isa(ShapeFcn,'function_handle')
               error(message('Control:lftmodel:tunableSurface2'))
            elseif nargin(ShapeFcn)~=nVars
               error(message('Control:lftmodel:tunableSurface3'))
            end
            try
               args = repmat({0},1,nVars);
               value = ShapeFcn(args{:});  % evaluate at (0,...,0)
            catch ME
               error(message('Control:lftmodel:tunableSurface4'))
            end
            if isempty(value)
               blk.nFun_ = 0;
            else
               if ~(isnumeric(value) && isreal(value) && isvector(value))
                  error(message('Control:lftmodel:tunableSurface5'))
               end
               blk.nFun_ = numel(value);
               blk.BasisFunctions_ = ShapeFcn;
            end
         end
         % Create REALP parameterization of tunable coefficients
         % [G0,G1,...,Gt]
         p = realp(name,[G0 , zeros(ios(1),blk.nFun_*ios(2))]);
         blk.Coefficients_ = p;
         blk.Name_ = name;
      end
                  
      function Value = get.BasisFunctions(blk)
         % GET function for BasisFunctions property
         Value = blk.BasisFunctions_;
      end
      
      function Value = get.Coefficients(blk)
         % GET function for Coefficients property
         Value = blk.Coefficients_;
      end
      
      function Value = get.SamplingGrid(blk)
         % GET function for SamplingGrid property
         if isempty(blk.SamplingGrid_)
            Value = struct;  % default
         else
            Value = getData(blk.SamplingGrid_);
         end
      end
            
      function Value = get.Normalization(blk)
         % GET function for Normalization property
         Value = blk.Normalization_;
         if isempty(Value)
            % Use default based on SamplingGrid data
            Value = tunableSurface.getDefaultNormalization(...
               getData(blk.SamplingGrid_));
         end
      end
            
      function blk = set.BasisFunctions(blk,f)
         % SET function for BasisFunctions property
         if isa(f,'function_handle')
            if nargin(f)~=blk.nVar_
               error(message('Control:lftmodel:tunableSurface10'))
            end
            try
               args = repmat({0},1,blk.nVar_);
               value = f(args{:});  % evaluate at (0,...,0)
            catch ME
               error(message('Control:lftmodel:tunableSurface11'))
            end
         elseif isempty(f)
            value = [];
         else
            error(message('Control:lftmodel:tunableSurface9'))
         end
         if isempty(value)
            if blk.nFun_>0
               error(message('Control:lftmodel:tunableSurface6'))
            else
               blk.BasisFunctions_ = [];
            end
         else
            if ~(isnumeric(value) && isreal(value) && isvector(value))
               error(message('Control:lftmodel:tunableSurface12'))
            elseif numel(value)~=blk.nFun_
               error(message('Control:lftmodel:tunableSurface6'))
            else
               blk.BasisFunctions_ = f;
            end
         end
      end
      
      function blk = set.Coefficients(blk,p)
         % SET function for BasisFunctions property
         refSize = size(blk.Coefficients_);
         if ~(isa(p,'realp') && isequal(size(p),refSize))
            error(message('Control:lftmodel:tunableSurface7',mat2str(refSize)))
         end
         p.Name = blk.Name_;  % ignore name mismatch
         blk.Coefficients_ = p;
      end
      
      function blk = set.SamplingGrid(blk,Value)
         % SET function for SamplingGrid property
         try
            SG = ltipack.SamplingGrid(Value);
         catch ME
            throw(ME)
         end
         if numel(getVariable(SG))~=blk.nVar_
            error(message('Control:lftmodel:tunableSurface8'))
         end
         blk.SamplingGrid_= SG;
      end
      
      function blk = set.Normalization(blk,Value)
         % SET function for Normalization property
         if isequal(Value,[])
            blk.Normalization_ = [];  % revert to default normalization
         else
            % Validate struct
            if ~(isstruct(Value) && isequal(sort(fieldnames(Value)),...
                  {'InputOffset';'InputScaling';'OutputScaling'}))
               error(message('Control:lftmodel:tunableSurface23'))
            end
            % Validate InputOffset
            aux = Value.InputOffset;
            if ~(isvector(aux) && isnumeric(aux) && isreal(aux) && numel(aux)==blk.nVar_ && ...
                  allfinite(aux))
               error(message('Control:lftmodel:tunableSurface24',blk.nVar_))
            end
            % Validate InputScaling
            aux = Value.InputScaling;
            if ~(isvector(aux) && isnumeric(aux) && isreal(aux) && numel(aux)==blk.nVar_ && ...
                  all(isfinite(aux) & aux>0))
               error(message('Control:lftmodel:tunableSurface25',blk.nVar_))
            end
            % Validate OutputScaling
            aux = Value.OutputScaling;
            if ~(isscalar(aux) && isnumeric(aux) && isreal(aux) && isfinite(aux) && aux>0)
               error(message('Control:lftmodel:tunableSurface26'))
            end
            blk.Normalization_= Value;
         end
      end
      
   end

   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)

      function blk = setName_(blk,Value)
         % Force Name to be a variable name
         if isvarname(Value)
            blk.Name_ = Value;
            blk.Coefficients_.Name = Value;
         else
            error(message('Control:lftmodel:BlockName1'))
         end
      end
      
      function displaySize(blk,sizes)
         % Display for "size(M)"
         sizes = [sizes ones(1,4-numel(sizes))];
         gridSize = sprintf('%dx',sizes(3:end));
         if all(sizes(1:2)==1)
            disp(getString(message('Control:lftmodel:SizeTunableSurf1',...
               blk.nVar_,blk.nFun_,gridSize(1:end-1))))
         else
            disp(getString(message('Control:lftmodel:SizeTunableSurf2',...
               sizes(1),sizes(2),blk.nVar_,blk.nFun_,gridSize(1:end-1))))
         end
      end
                  
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
            
      %% Characteristics
      function boo = isfinite_(blk,~)
         boo = isfinite(blk.Coefficients_);
      end

      %% INDEXING
      function M = createLHS(~)
         % Creates LHS in assignment.
         % Returns 0x0 GENMAT
         M = genmat();
      end
      
      %% CONVERSIONS
      function A = double_(blk)
         A = numeric_array(blk);
      end
      
      function sys = ss_(blk,optflag)
         % Converts to @ss
         sys = ss.make(ltipack_ssdata(blk));
         if nargin>1
            sys = ss(sys,optflag);
         end
      end
      
      function M = genmat_(blk)
         % Converts to @genmat
         [ny,nu] = iosize(blk);
         nf = blk.nFun_;
         CG = tunableSurface.applyNormalization(...
            getCellData(blk.SamplingGrid_),blk.Normalization);
         fVals = tunableSurface.evalBF(CG,blk.BasisFunctions_,nf);
         B = ltipack.LFTBlockWrapper(blk.Coefficients_);
         D = createArray(size(CG{1}),'ltipack.lftdataM');
         for ct=1:numel(D)
            D(ct).IC = [zeros(ny,nu) eye(ny) ; kron(fVals(:,ct),eye(nu)) zeros(nu*(nf+1),ny)];
            D(ct).Blocks = B;
         end
         M = genmat.make(D);
         M.SamplingGrid = blk.SamplingGrid;
      end
      
      function M = umat_(blk)
         % Converts to @umat (only defined for uncertain static blocks)
         M = umat_(genmat_(blk));
      end
      
      function sys = genss_(blk)
         % Converts to @genss
         [ny,nu] = iosize(blk);
         nf = blk.nFun_;
         rs = ny+nu*(nf+1);   cs=ny+nu;
         CG = tunableSurface.applyNormalization(...
            getCellData(blk.SamplingGrid_),blk.Normalization);
         fVals = tunableSurface.evalBF(CG,blk.BasisFunctions_,nf);
         B = ltipack.LFTBlockWrapper(blk.Coefficients_);
         D = createArray(size(CG{1}),'ltipack.lftdataSS');
         for ct=1:numel(D)
            IC = [zeros(ny,nu) eye(ny) ; kron(fVals(:,ct),eye(nu)) zeros(nu*(nf+1),ny)];
            D(ct).IC = ltipack.ssdata([],zeros(0,cs),zeros(rs,0),IC,[],0);
            D(ct).Blocks = B;
         end
         sys = genss.make(D);
         sys.SamplingGrid = blk.SamplingGrid;
      end
      
      function sys = uss_(blk)
         % Converts to @uss
         sys = uss_(genss_(blk));
      end
      
      function sys = genfrd_(blk,freq)
         % Converts to @genfrd
         [ny,nu] = iosize(blk);
         nf = blk.nFun_;
         CG = tunableSurface.applyNormalization(...
            getCellData(blk.SamplingGrid_),blk.Normalization);
         fVals = tunableSurface.evalBF(CG,blk.BasisFunctions_,nf);
         B = ltipack.LFTBlockWrapper(blk.Coefficients_);
         D = createArray(size(CG{1}),'ltipack.lftdataFRD');
         for ct=1:numel(D)
            IC = [zeros(ny,nu) eye(ny) ; kron(fVals(:,ct),eye(nu)) zeros(nu*(nf+1),ny)];
            D(ct).IC = ltipack.frddata(repmat(IC,[1 1 numel(freq)]),freq,0);
            D(ct).Blocks = B;
         end
         sys = genfrd.make(D);
         sys.SamplingGrid = blk.SamplingGrid;
      end
      
      function sys = ufrd_(blk,freq)
         % Converts to @ufrd
         sys = ufrd_(genfrd_(blk,freq));
      end
      
      %% TRANSFORMATIONS
      function M = repmat_(blk,s)
         M = repmat_(genmat(blk),s);
      end
      
      function M = uminus_(blk)
         M = uminus_(genmat(blk));
      end
      
      function blk = setBlockValue_(blk,S)
         % Sets value of tunable coefficients
         BlockName = blk.Name;
         if isfield(S,BlockName)
            blk.Coefficients = setValue(blk.Coefficients,S.(BlockName));
         end
      end
            
   end
   
   
   %% HIDDEN INTERFACES
   methods (Hidden)
      
      function s = getArraySize(blk)
         s = getSize(blk.SamplingGrid_);
      end
      
      % CONTROLDESIGNBLOCK
      function D = ltipack_ssdata(blk,varargin)
         % Converts to ltipack.ssdata
         d = numeric_array(blk,varargin{:});
         s = size(d);
         D = createArray(s(3:end),'ltipack.ssdata');
         for ct=1:numel(D)
            D(ct) = ltipack.ssdata([],zeros(0,s(2)),zeros(s(1),0),d(:,:,ct),[],0);
         end
      end

      function D = ltipack_frddata(blk,freq,varargin)
         % Converts to ltipack.frddata
         d = numeric_array(blk,varargin{:});
         s = size(d);
         D = createArray(s(3:end),'ltipack.frddata');
         for ct=1:numel(D)
            D(ct) = ltipack.frddata(repmat(d(:,:,ct),[1 1 length(freq)]),freq,0);
         end
      end
      
      function M = numeric_array(blk,~,S)
         % Converts to double array. Evaluates blk-S when S supplied
         % (R is always [] for non-uncertain blocks)
         ni = nargin;
         [ny,nu] = iosize(blk);
         nf = blk.nFun_;
         CG = tunableSurface.applyNormalization(...
            getCellData(blk.SamplingGrid_),blk.Normalization);
         fVals = tunableSurface.evalBF(CG,blk.BasisFunctions_,nf);
         G = getScaledCoefficients(blk);
         gridSize = size(CG{1});
         M = zeros([ny nu gridSize]);
         for ct1=1:prod(gridSize)
            MM = G(:,1:nu);
            jG = nu;
            for ct2=2:nf+1
               MM = MM + fVals(ct2,ct1) * G(:,jG+1:jG+nu);
               jG = jG+nu;
            end
            if ni>1
               MM = MM-S;
            end
            M(:,:,ct1) = MM;
         end
      end
      
      function Offset = getOffset(~)
         % Not used (replaced by REALP in LFT models)
         Offset = NaN;
      end
      
      function str = getDescription(~,~)
         % Not used
         str = '';
      end
                  
      function S = getBlocks(blk)
         S = struct(blk.Name_,blk.Coefficients_);
      end

      function blk = setValue(varargin) %#ok<STOUT>
         error(message('Control:lftmodel:setValue4'))
      end

      function showValue(blk)
         % Displays coefficient values
         Name = blk.Name_;
         Value = blk.Coefficients_.Value;
         if isscalar(Value)
            fprintf('%s = \nTunable surface coefficient: %.3g\n',Name,Value)
         else
            s = evalc('disp(Value)');
            fprintf('%s =\nTunable surface coefficients:\n%s\n',Name,deblank(s))
         end
      end

      function blk = frd(varargin) %#ok<STOUT>
         error(message('Control:lftmodel:tunableSurface18'))
      end

      function BlockList = getTunableBlocks(blk)
         % Gets list of tunable blocks
         BlockList = {blk.Coefficients_};
      end
      
      function Coeffs = getScaledCoefficients(blk)
         % Returns current value of coefficients including the
         % OutputScaling
         Coeffs = blk.Coefficients_.Value;
         if ~isempty(blk.Normalization_)
            OS = blk.Normalization_.OutputScaling;
            if OS~=1
               Coeffs = OS * Coeffs;
            end
         end
      end
   
   end
   
   
   %% PROTECTED METHODS
   methods (Access = protected)
      % Indexing operations (see RedefinesParen)

      function M = parenReference(blk, indexingOperation)
         % Indexing forces conversion to GENMAT
         % Note: This should never return a derived tunableSurface because
         % this would compromise the ability to tune the original gain
         % surface through expressions like 2*G(1,1)-G(2,2). While this is
         % more meaningful for REALP, consistency dictates it'd also be
         % done for tunableSurface.
         M = parenReference(genmat(blk), indexingOperation);
      end

   end
   
         
   methods (Static, Hidden)
      
      function blk = loadobj(s)
         % Load filter for @tunableSurface objects
         if isstruct(s)
         else
            % Update version
            blk = s;
            % Name_ did not exist before R2017a
            blk.Name_ = blk.Coefficients_.Name;
            % Normalization_ was always default before 17b
            if s.Version_<19
               blk.Normalization_ = [];
            end
            blk.Version_ = ltipack.ver();
         end
      end
      
      function NS = getDefaultNormalization(SamplingGrid)
         % Computes normalizing transformation
         %       n(x) = (x-InputOffset)./InputScaling 
         % that maps the SamplingGrid range of variation to [-1,1]^m.
         % OutputScaling is set to 1 by default.
         CG = struct2cell(SamplingGrid);
         nv = numel(CG);
         InputOffset = zeros(1,nv);
         InputScaling = ones(1,nv);
         for ct=1:nv
            x = CG{ct}(:);
            xmin = min(x);
            xmax = max(x);
            InputOffset(ct) = (xmin+xmax)/2;
            if xmin~=xmax
               InputScaling(ct) = (xmax-xmin)/2;
            end
         end
         NS = struct('InputOffset',InputOffset,...
            'InputScaling',InputScaling,...
            'OutputScaling',1);
      end
      
      function CG = applyNormalization(CG,NS)
         % Apply normalization n(x) to grid CG (in cell format)
         nv = numel(CG);
         for ct=1:nv
            CG{ct} = (CG{ct}-NS.InputOffset(ct))/NS.InputScaling(ct);
         end
      end
      
      function M = evalBF(CG,f,nf)
         % Returns the array
         %           [       1 ...       1  ] 
         %           [  y(1,1) ...  y(1,np) ]
         %           [     ...              ]
         %           [ y(nf,1) ... y(nf,np) ] 
         % where np is the number of grid points, nf the number of basis 
         % functions, and y(i,j) is the value of the i-th basis function
         % at the j-th grid point. CG is the evaluation grid in cell
         % format. It should include the normalizatin transformation n(x).
         nv = numel(CG);
         np = numel(CG{1});
         M = zeros(nf+1,np);
         M(1,:) = 1;
         x = cell(1,nv);
         try
            for ctP=1:np
               for ctV=1:nv
                  x{ctV} = CG{ctV}(ctP);
               end
               M(2:nf+1,ctP) = f(x{:});
            end
         catch
            if numel(x)>1
               xv = sprintf('%.3g,',x{:});
               xv = sprintf('(%s)',xv(1:end-1));
            else
               xv = sprintf('%.3g',x{1});
            end
            error(message('Control:lftmodel:tunableSurface19',xv))
         end
      end
      
   end
end
