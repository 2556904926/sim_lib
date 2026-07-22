classdef (CaseInsensitiveProperties, TruncatedProperties) genmat < ltipack.StaticLFT
   % Generalized matrices.
   %
   %   Generalized matrices are rational expressions involving tunable or
   %   uncertain parameters (see REALP, UREAL, UCOMPLEX, UCOMPLEXM). They can
   %   be used for parameter studies, worst-case analysis, or parameter tuning.
   %   They are also useful for building generalized state-space or FRD models
   %   (see GENSS and GENFRD). The class GENMAT implements the concept of
   %   generalized matrix.
   %
   %   Generalized matrices typically arise when combining parameter objects
   %   such as REALP or UREAL using +, -, *, /, \, ^. For example, if a and b
   %   are two real parameters, the expression M=a+b is represented as a
   %   generalized matrix. The internal GENMAT data structure keeps track of
   %   how M depends on a,b and the property M.Blocks lists the independent
   %   parameters a,b.
   %
   %   You can also create generalized matrices by converting numeric arrays
   %   or static Control Design blocks to the GENMAT class. For example,
   %      M = genmat([1 -2])
   %   creates a 1x2 generalized matrix with no independent parameter while
   %      a = realp('a',1)
   %      M = genmat(a)
   %   converts the real parameter "a" into a generalized matrix.
   %
   %   Example: Create the parametric matrix M = [1 a+b;0 a*b] where a and b are real
   %   parameters with initial values -1 and 3:
   %      a = realp('a',-1)
   %      b = realp('b',3)
   %      M = [1 a+b;0 a*b]
   %   M is a generalized matrix with current value [1 2;0 -3] from the values of a,b.
   %   Change the value of the parameter "a" and re-evaluate:
   %      M.Blocks.a.Value = -3;
   %      double(M)
   %   The value of M is now [1 0;0 -9].
   %
   %   See also realp, getValue, umat, genss, genfrd, ControlDesignBlock.
   
   %   Author(s): P. Gahinet
   %   Copyright 2009-2011 The MathWorks, Inc.
   
   % Add static method to be included for compiler
   %#function genmat.loadobj
   %#function genmat.make
   
   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)
      
      function T = toClosed(~)
         T = 'genmat';
      end

      function T = superiorTypes()
         T = {'genmat'};
      end
            
      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.Dynamic = false;
         A.FRD = false;
         A.Sparse = false;
      end
      
      function T = toDynamic()
         T = 'genss';
      end
      
      function T = toVarying()
         T = 'ltvss';
      end

      function T = toFRD()
         T = 'genfrd';
      end
      
   end
   
   methods
      
      function M = genmat(D)
         if nargin==0
            % GENMAT()
            M.Data_ = ltipack.lftdataM([],ltipack.LFTBlockWrapper.emptyBlockList());
            M.IOSize_ = [0 0];
         elseif strcmp(class(D),'genmat') %#ok<STISA>
            % Handle conversion GENMAT(D) where D is @genmat
            M = D;
         elseif isnumeric(D)
            % GENMAT(double)
            B = ltipack.LFTBlockWrapper.emptyBlockList();
            D = double(full(D));
            s = [size(D) ones(1,2)];
            Data = createArray(s(3:end),'ltipack.lftdataM');
            for ct=1:numel(Data)
               Data(ct).IC = D(:,:,ct);
               Data(ct).Blocks = B;
            end
            M.Data_ = Data;
            M.IOSize_ = s(1:2);
         else
            ctrlMsgUtils.error('Control:general:InvalidSyntaxForCommand','genmat','genmat')
         end
      end
      
   end
   
   
   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access=protected)
      
      function displaySize(M,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         nb = nblocks(M);
         if length(sizes)==2,
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENMAT1',ny,nu,nb))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENMAT2',ArrayDims(1:end-1)))
            if isempty(nb)
               nb = 0;
            else
               nb = nb(:);
            end
            if all(nb==nb(1))
               disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENMAT3',ny,nu,nb(1)))
            else
               disp(ctrlMsgUtils.message('Control:lftmodel:SizeGENMAT4',ny,nu,min(nb),max(nb)))
            end
         end
      end
      
   end
   
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access = protected)
      
      %% MODEL CHARACTERISTICS
      function M = checkDataConsistency(M)
         % REVISIT
      end
      
      function varargout = lftdata_(M,varargin)
         % LFTDATA support for generalized LFT models
         [varargout{1:nargout}] = lftdata_(umat_(M),varargin{:});
      end
      
      %% INDEXING
      function M = indexasgn_(M,indices,rhs,ioSize,ArrayMask)
         % Data management in M(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.
         
         % Construct template initial value for new entries in system array
         D0 = ltipack.lftdataM(zeros(ioSize),ltipack.LFTBlockWrapper.emptyBlockList());
         % Update data
         M.Data_ = ltipack.reassignData(M.Data_,indices,rhs.Data_,ioSize,ArrayMask,D0);
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(M.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            M.SamplingGrid_ = reassign(M.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(M.Data_));
         end
      end
      
      %% TRANSFORMATIONS
      function M = getNominal_(M)
         % Returns nominal value
         [M,NoBlocks] = foldUncertainty_(M);
         if NoBlocks
            M = double(M);
         end
      end
      
   end
   
   %% STATIC METHODS
   methods(Static, Hidden)
      
      function M = make(D,IOSize)
         % Constructs GENMAT model from nonempty ltipack.lftdataM array
         M = genmat;
         M.Data_ = D;
         if nargin>1
            M.IOSize_ = IOSize;  % support for empty model arrays
         else
            M.IOSize_ = iosize(D(1));
         end
      end
      
      function blk = loadobj(s)
         % Load filter for GENMAT objects
         if isa(s,'genmat')
            blk = s;
            blk.Version_ = ltipack.ver();
         end
      end
      
      function M = convert(X)
         % Safe conversion to GENMAT
         if isnumeric(X)
            M = genmat(X);
         else
            M = copyMetaData(X,genmat_(X));
         end
      end
      
   end
   
   %% OBSOLETE
   methods (Hidden)
      view(varargin)
   end
   
end
