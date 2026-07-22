classdef ControlDesignBlock < InputOutputModel
   % Control Design Block objects.
   %
   %   Control Design blocks are a special type of input/output models designed to 
   %   facilitate tasks like control system tuning and robustness analysis. These 
   %   blocks can be combined with regular LTI models to construct hybrid models 
   %   that keep track of their tunable and uncertain components (see genlti).
   %   When necessary, you can use commands like TF or SS to convert any Control 
   %   Design block into an ordinary transfer function or state-space model.
   %
   %   All Control Design Block objects derive from the @ControlDesignBlock
   %   superclass. This class is not user-facing and cannot be instantiated. 
   %   User-facing subclasses of @ControlDesignBlock include:
   %     * Tunable blocks such as realp, tunablePID, tunableTF, and tunableSS
   %       (see tunableBlock for details)
   %     * Uncertain blocks such as ureal, ucomplex, ucomplexm, ultidyn,
   %       and umargin (see UncertainBlock for details)
   %     * Analysis point blocks for marking signals of interest and loop 
   %       opening locations (see AnalysisPoint).
   %
   %   You can use commands like SYSTUNE and LOOPTUNE to automatically tune 
   %   parametric Control Design blocks, and commands like ROBUSTSTAB and 
   %   WCGAIN to analyze models with uncertain blocks.
   %
   %   See also tunableBlock, UncertainBlock, AnalysisPoint, genlti, ulti, 
   %   systune, looptune, hinfstruct, InputOutputModel.

%   Author(s): P. Gahinet
%   Copyright 1986-2014 The MathWorks, Inc.

   % CONTROL DESIGN BLOCK INTERFACE
   methods (Abstract, Hidden)
      % Low-level recipe for converting to ltipack.ssdata
      D = ltipack_ssdata(blk)
      % Low-level recipe for converting to ltipack.frddata
      D = ltipack_frddata(blk,freq,varargin)
   end
   
   %% PUBLIC
   methods
      
      function blk = setValue(blk,Value)
         %SETVALUE  Modifies value of tunable block.
         %
         %   BLK = setValue(BLK,VAL) updates the parameter values in the tunable
         %   block BLK to best match the specified value VAL. An exact match is
         %   only guaranteed when VAL matches the structure and attributes of BLK.
         %
         %   See also getValue, tunableBlock.
         try
            sv = size(Value);
            if numel(sv)>2
               error(message('Control:lftmodel:setValue3',blk.Name))
            elseif ~isequal(sv,iosize(blk))
               error(message('Control:lftmodel:setValue2',blk.Name))
            end
            blk = setValue_(blk,Value);
         catch ME
            throw(ME)
         end
      end
      
   end

   
   %% DATA ABSTRACTION INTERFACE
   methods (Access=protected)
      
      blk = setValue_(blk,Value)

      %% InputOutputModel
      function blk = setName_(blk,Value)
         % Force Name to be a variable name
         if isvarname(Value)
            blk.Name_ = Value;
         else
            error(message('Control:lftmodel:BlockName1'))
         end
      end
      
      %% MODEL CHARACTERISTICS
      function nb = nblocks_(~)
         nb = 1;
      end
      
      %% CONVERSIONS
      % Default implementations for static blocks
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
      
      function sys = sparss_(blk)
         % Converts to @ss
         sys = sparss.make(sparss(ltipack_ssdata(blk)));
      end
      
      function sys = mechss_(blk)
         % Converts to @ss
         sys = mechss.make(mechss(ltipack_ssdata(blk)));
      end
      
      function sys = tf_(blk,varargin)
         % Converts to @tf
         sys = tf.make(tf(ltipack_ssdata(blk),varargin{:}));
      end
      
      function sys = zpk_(blk,varargin)
         % Converts to @zpk
         sys = zpk.make(zpk(ltipack_ssdata(blk),varargin{:}));
      end
      
      function sys = frd_(blk,varargin)
         % Converts to @frd
         sys = frd.make(ltipack_frddata(blk,varargin{:}));
      end
      
      function sys = pid_(blk,varargin)
          % Converts to @pid
          sys = pid.make(pid(ltipack_ssdata(blk),varargin{:}));
      end
      
      function sys = pidstd_(blk,varargin)
          % Converts to @pidstd
          sys = pidstd.make(pidstd(ltipack_ssdata(blk),varargin{:}));
      end
      
      function sys = pid2_(blk,varargin)
          % Converts to @pid2
          sys = pid2.make(pid2(ltipack_ssdata(blk),varargin{:}));
      end
      
      function sys = pidstd2_(blk,varargin)
          % Converts to @pidstd2
          sys = pidstd2.make(pidstd2(ltipack_ssdata(blk),varargin{:}));
      end
      
      function M = genmat_(blk)
         % Converts to @genmat (only defined for static blocks)
         if isa(blk,'StaticModel')
            [ny,nu] = iosize(blk);
            IC = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
            M = genmat.make(ltipack.lftdataM(IC,ltipack.LFTBlockWrapper(blk)));
         else
            error(message('Control:lftmodel:genmat1'))
         end
      end
      
      function M = umat_(blk)
         % Converts to @umat (only defined for uncertain static blocks)
         if isa(blk,'StaticModel')
            if isUncertain(blk)
               [ny,nu] = iosize(blk);
               IC = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
               D = ltipack.lftdataM(IC,ltipack.LFTBlockWrapper(blk));
               M = umat.make(normalizeBlocks(D));
            else
               % Replace block by its value
               M = umat.make(ltipack.lftdataM(numeric_array(blk),...
                  ltipack.LFTBlockWrapper.emptyBlockList()));
            end
         else
            error(message('Robust:umodel:umat1'))
         end
      end
      
      function sys = genss_(blk)
         % Converts to @genss
         [ny,nu] = iosize(blk);
         M = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
         IC = ltipack.ssdata([],zeros(0,ny+nu),zeros(ny+nu,0),M,[],getTs_(blk));
         sys = genss.make(ltipack.lftdataSS(IC,ltipack.LFTBlockWrapper(blk)));
      end
      
      function sys = uss_(blk)
         % Converts to @uss
         if isUncertain(blk)
            [ny,nu] = iosize(blk);
            M = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
            IC = ltipack.ssdata([],zeros(0,ny+nu),zeros(ny+nu,0),M,[],getTs_(blk));
            D = ltipack.lftdataSS(IC,ltipack.LFTBlockWrapper(blk));
            sys = uss.make(normalizeBlocks(D));
         else
            % Replace block by its value
            sys = uss.make(ltipack.lftdataSS(ltipack_ssdata(blk),...
                  ltipack.LFTBlockWrapper.emptyBlockList()));
         end
      end
      
      function sys = genfrd_(blk,freq)
         % Converts to @genfrd
         [ny,nu] = iosize(blk);
         M = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
         IC = ltipack.frddata(repmat(M,[1 1 numel(freq)]),freq,getTs_(blk));
         sys = genfrd.make(ltipack.lftdataFRD(IC,ltipack.LFTBlockWrapper(blk)));
      end
      
      function sys = ufrd_(blk,freq)
         % Converts to @ufrd
         if isUncertain(blk)
            [ny,nu] = iosize(blk);
            M = [zeros(ny,nu) , eye(ny) ; eye(nu) zeros(nu,ny)];
            IC = ltipack.frddata(repmat(M,[1 1 numel(freq)]),freq,getTs_(blk));
            D = ltipack.lftdataFRD(IC,ltipack.LFTBlockWrapper(blk));
            sys = ufrd.make(normalizeBlocks(D));
         else
            % Replace block by its value
            sys = ufrd.make(ltipack.lftdataFRD(ltipack_frddata(blk,freq),...
                  ltipack.LFTBlockWrapper.emptyBlockList()));
         end
      end

      function sysOut = ltvss_(blk)
         % Converts to linear time-varying
         Data = ltipack_ssdata(blk);
         a = Data.a;  b = Data.b;  c = Data.c;  d = Data.d;  e = Data.e;
         Delays = Data.Delay;
         if ~(any(Delays.Input) || any(Delays.Output) || any(Delays.Internal))
            Delays = [];
         end
         if isempty(a) && isempty(Delays)
            F = @(t) ltvpack.staticDF(d);
         else
            F = @(t) ltvpack.constantDF(a,b,c,d,e,Delays);
         end
         sysOut = ltvss(F,Data.Ts);
         sysOut.StateName = Data.StateName;
         sysOut.StatePath = Data.StatePath;
         sysOut.StateUnit = Data.StateUnit;
      end

      function sysOut = lpvss_(blk)
         % Converts to linear parameter-varying
         Data = ltipack_ssdata(blk);
         a = Data.a;  b = Data.b;  c = Data.c;  d = Data.d;  e = Data.e;
         Delays = Data.Delay;
         if ~(any(Delays.Input) || any(Delays.Output) || any(Delays.Internal))
            Delays = [];
         end
         if isempty(a) && isempty(Delays)
            F = @(t,p) ltvpack.staticDF(d);
         else
            F = @(t,p) ltvpack.constantDF(a,b,c,d,e,Delays);
         end
         sysOut = lpvss(strings(0,1),F,Data.Ts);
         sysOut.StateName = Data.StateName;
         sysOut.StatePath = Data.StatePath;
         sysOut.StateUnit = Data.StateUnit;
      end

      %% TRANSFORMATIONS
      function blk = transpose_(blk)
         if ~(isequal(blk.IOSize_,[1 1]) && isstatic(blk))
            error(message('Control:transformation:Transpose1'))
         end
      end
      
      function blk = ctranspose_(blk)
         if ~(isequal(blk.IOSize_,[1 1]) && isstatic(blk))
            error(message('Control:transformation:Transpose1'))
         elseif ~isreal(blk)
            error(message('Control:transformation:Transpose2'))
         end
      end
      
      function blk = reshape_(blk,varargin)
         % No-op (blocks are always single models)
         try
            reshape(1,varargin{:});
         catch ME
            if strcmp(ME.identifier,'MATLAB:getReshapeDims:notSameNumel')
               error(message('Control:lftmodel:reshape1'))
            else
               throw(ME)
            end
         end
      end
      
      function blk = replaceB2B_(blk,BlockNames,BlockValues)
         % Block-to-block substitution (used by HINFSTRUCT).
         ix = find(strcmp(blk.Name,BlockNames));
         if ~isempty(ix)
            blk = BlockValues{ix};
         end
      end
      
      function blk = setBlockValue_(blk,S)
         % Sets block value.
         BlockName = blk.Name;
         if isfield(S,BlockName)
            blk = setValue(blk,S.(BlockName));
         end
      end

      function blk = inheritBlockValue_(blk,S)
         % Same as setBlockValue_ for Control Design blocks
         BlockName = blk.Name;
         if isfield(S,BlockName)
            % Note: Don't do blk=S.(BlockName) (may lose I/O names,...)
            blk = setValue(blk,S.(BlockName));
         end
      end

   end
         
   methods (Hidden)

      % Offset (default static value)
      Offset = getOffset(blk)

      % Block description in LFT model
      str = getDescription(blk,ncopies)

      function S = getBlocks(blk)
         S = struct(blk.Name,blk);
      end

      function BlockList = getTunableBlocks(~)
         % Gets list of tunable blocks
         BlockList = cell(0,1);
      end

      function [R,S,T] = getNormalizeTransform(blk)
         % Get normalization transformation (see LFTBlockWrapper/normalize).
         % Computes R,S,T such that
         %    * blk_n = LFT(R,blk-S) is normalized
         %    * blk = LFT(T,blk_n)
         % Returns R=[] when blk-S is already normalized (then T = [S I;I 0]).
         %
         % For uncertain blocks, normalized means centered + unit uncertainty
         % level. For other blocks, it just means centered (zero feedthrough).

         % Default implementation: R=[] and S=offset.
         R = [];
         S = getOffset(blk);
         [ny,nu] = size(S);
         T = [S eye(ny);eye(nu) zeros(nu,ny)];
      end

      function showValue(blk)
         % Displays block value (used by showBlockValue)
         Value = getValue(blk);
         if isnumeric(Value)
            if isscalar(Value)
               fprintf('%s = %.3g\n',blk.Name,Value)
            else
               s = evalc('disp(Value)');
               fprintf('%s =\n%s\n',blk.Name,deblank(s))
            end
         else
            s = evalc('display(Value)');
            s = regexprep(s,'\nValue =\n',sprintf('%s =\n',blk.Name));
            i = strfind(s,'<a href=');
            if ~isempty(i)
               s = s(1:i-1);
            end
            fprintf('%s\n',deblank(s))
         end
      end
      
   end

   %% UTILITIES
   methods (Access=protected)

      function showModelProperties(blk)
         % Hotlink to show model properties in display
         if matlab.internal.display.isHot
            try %#ok<TRYNC>
               txt = getString(message('Control:general:BlockProperties'));
               fprintf('<a href="matlab:disp(char(%s))">%s</a>\n',getPropertyDisplay(blk),txt);
            end
         end
      end

   end

   %% STATIC METHODS
   methods (Hidden, Static = true)
      % NSOPT support
      [Acl,Bcl,Ccl,Dcl,lftData] = evalLFT(A,B,C,D,pInfo,x)
      g = gradLFT(lftData,pInfo,x,u,v)
   end
   
end


