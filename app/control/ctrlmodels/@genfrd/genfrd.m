classdef (CaseInsensitiveProperties, TruncatedProperties,...
      InferiorClasses = {? matlab.graphics.axis.Axes,...
? matlab.ui.control.UIAxes,...
? matlab.ui.Figure,...
? matlab.ui.container.Panel,...
? matlab.ui.container.Tab,...
? matlab.ui.container.GridLayout,...
? matlab.graphics.layout.TiledChartLayout}) ...
      genfrd < genlti & FRDModel
   %GENFRD  Generalized FRD models.
   %
   %  Construction:
   %    Generalized FRD models (GENFRD) arise when combining ordinary FRD models
   %    (see FRD) with tunable compensator blocks or parameterized components
   %    (see TUNABLEBLOCK). GENFRD models keep track of how the tunable blocks
   %    interact with the fixed dynamics.
   %
   %  Conversion:
   %    M = GENFRD(M,FREQS,FREQUNITS) converts the input/output model M to a
   %    generalized FRD model of class @genfrd.  For non-FRD models, GENFRD computes
   %    the frequency response at each frequency point in the vector FREQS. The
   %    frequencies FREQS are expressed in the units specified by FREQUNITS (see
   %    "help genfrd.FrequencyUnit" for a list of valid frequency units). The
   %    default is 'rad/TimeUnit' when FREQUNITS is omitted.
   %
   %    M = GENFRD(M,FREQS,FREQUNITS,TIMEUNITS) further specifies the time units
   %    when converting a static model M to GENFRD.
   %
   %  See also FRD, GETVALUE, CHGFREQUNIT, GENLTI, CONTROLDESIGNBLOCK.

   %   Author(s): P. Gahinet
   %   Copyright 2009-2012 The MathWorks, Inc.


   % Add static method to be included for compiler
   %#function genfrd.loadobj
   %#function genfrd.make
   %#function genfrd.convert

   % TYPE MANAGEMENT IN BINARY OPERATIONS
   methods (Static, Hidden)

      function T = toClosed(~)
         T = 'genfrd';
      end

      function T = superiorTypes()
         T = {'genfrd'};
      end

      function A = getAttributes(A)
         % Override default attributes
         A.Varying = false;
         A.Sparse = false;
      end

      function T = toVarying()
         error(message('Control:combination:FRD'))
      end

   end

   methods

      function sys = genfrd(varargin)
         ni = nargin;
         if ni==0
            % GENFRD()
            sys.Data_ = ltipack.lftdataFRD(ltipack.frddata.default(),...
               ltipack.LFTBlockWrapper.emptyBlockList());
            sys.IOSize_ = [0 0];
         elseif strcmp(class(varargin{1}),'genfrd') %#ok<STISA>
            % GENFRD(SYS,FREQ,UNIT) where SYS is @genfrd
            if ni==1
               % no-op
               sys = varargin{1};
            else
               try
                  [sys,freq,funit] = FRDModel.parseFRDInputs('genfrd',varargin);
                  freq = funitconv(funit,'rad/TimeUnit',sys.TimeUnit)*freq;
                  % Note: May error if FREQ differs from frequency grid for some models
                  sys = copyMetaData(sys,genfrd_(sys,freq));  % frequnit=rad/TimeUnit
                  % Restore frequency units
                  sys = chgFreqUnit(sys,funit);
               catch ME
                  throw(ME)
               end
            end
         else
            error(message('Control:general:InvalidSyntaxForCommand','genfrd','genfrd'))
         end
      end

   end


   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access = protected)

      % INPUTOUTPUTMODEL
      function displaySize(sys,sizes)
         % Displays SIZE information in SIZE(SYS)
         ny = sizes(1);
         nu = sizes(2);
         nf = nfreqs(sys);
         nb = nblocks(sys);
         if length(sizes)==2
            disp(getString(message('Control:lftmodel:SizeGENFRD1',ny,nu,nf,nb)))
         else
            ArrayDims = sprintf('%dx',sizes(3:end));
            disp(getString(message('Control:lftmodel:SizeGENFRD2',ArrayDims(1:end-1))))
            if isempty(nb)
               nb = 0;
            else
               nb = nb(:);
            end
            if all(nb==nb(1))
               disp(getString(message('Control:lftmodel:SizeGENFRD3',ny,nu,nf,nb(1))))
            else
               disp(getString(message('Control:lftmodel:SizeGENFRD4',ny,nu,nf,min(nb),max(nb))))
            end
         end
      end

      % SINGLERATESYSTEM
      function sys = setTs_(sys,Ts)
         if Ts==-1
            warning(message('Control:ltiobject:frdAmbiguousRate1'))
         end
         sys = setTs_@genlti(sys,abs(Ts));
      end

      % FRDMODEL
      function nf = nfreqs_(sys)
         % Returns number of frequency point in each model
         D = sys.Data_;
         if isempty(D)
            nf = 0;
         else
            nf = numel(D(1).IC.Frequency);
         end
      end

      function f = getFrequency_(sys)
         % Retrieves frequency vector expressed in current frequency units
         D = sys.Data_;
         f = D(1).IC.Frequency;  % in rad/TimeUnit
         for ct=2:numel(D)
            if ~FRDModel.isSameFrequencyGrid(f,D(ct).IC.Frequency)
               error(message('Control:ltiobject:get7'))
            end
         end
         % Return values in FrequencyUnit
         f = funitconv('rad/TimeUnit',sys.FrequencyUnit,sys.TimeUnit) * f;
      end

      function sys = setFrequency_(sys,f)
         % Sets frequency vector
         f = funitconv(sys.FrequencyUnit,'rad/TimeUnit',sys.TimeUnit) * f;
         Data = sys.Data_;
         for ct=1:numel(Data)
            IC = Data(ct).IC;
            IC.Frequency = f;
            if sys.CrossValidation_
               IC = checkData(IC);
            end
            Data(ct).IC = IC;
         end
         sys.Data_ = Data;
      end

      function sys = scaleFrequency_(sys,sf)
         % Scales frequency vector (typically in reaction to a unit change)
         Data = sys.Data_;
         for ct=1:numel(Data)
            Data(ct).IC.Frequency = sf * Data(ct).IC.Frequency;
         end
         sys.Data_ = Data;
      end

      function sys = fcat_(sys,sys2)
         % FCAT(SYS,SYS2) for two GENFRD systems.
         [sys,sys2] = matchArraySize(sys,sys2);   % must come first
         [sys,sys2] = matchSamplingTime(sys,sys2);
         % Combine data
         sys.Data_.IC = fcat(sys.Data_.IC,sys2.Data_.IC);
      end

      function sys = fselect_(sys,varargin)
         % Select portion of frequency vector in FRD model
         ni = nargin;
         Data = sys.Data_;
         for ct=1:numel(Data)
            IC = Data(ct).IC;
            f = IC.Frequency;
            if ni<3
               index = varargin{1};
               if any(index>length(f))
                  error(message('Control:transformation:fselect1'))
               end
            else
               % FMIN and FMAX are in rad/TimeUnit
               index = find(f>=varargin{1} & f<=varargin{2});
            end
            IC.Response = IC.Response(:,:,index);
            IC.Frequency = f(index,:);
            Data(ct).IC = IC;
         end
         sys.Data_ = Data;
      end

      function sys = fdel_(sys,freq2remove)
         % Delete portion of frequency vector in FRD model
         Data = sys.Data_;
         for ct=1:numel(Data)
            Data(ct).IC = fdel(Data(ct).IC,freq2remove);
         end
         sys.Data_ = Data;
      end

   end


   %% DATA ABSTRACTION INTERFACE
   methods (Access = protected)

      %% MODEL CHARACTERISTICS
      function [boo,sys] = isproper_(sys,varargin)
         % Override @SystemArray implementation
         boo = true;
      end

      function boo = isempty_(sys)
         % Note: Returns true if there are no frequencies
         boo = any(size(sys)==0);
         if ~boo
            boo = true;
            D = sys.Data_;
            for ct=1:numel(D)
               if ~isempty(D(ct).IC.Frequency)
                  boo = false;  return
               end
            end
         end
      end

      function sys = checkDataConsistency(sys)
         % Cross validation of system data.
         % Validate frequency vector (needed in set(sys,'Frequency',...))
         D = sys.Data_;
         for ct=1:numel(D)
            D(ct).IC = checkDelay(checkData(D(ct).IC));
         end
         sys.Data_ = D;
         % Sampling time restriction
         if sys.Ts==-1
            % Ts=-1 is ambiguous for FRD models and may lead to
            % inconsistencies, e.g., if sys1.Ts=-1 and sys2.Ts=.1,
            % frd(sys1,w)+frd(sys2,w) and frd(sys1+sys2,w) differ
            % because the response in frd(sys1,w) is effectively
            % evaluated for Ts=1. Similar problems arise when
            % absorbing delays with Ts=-1. Force Ts=1 and warn.
            warning(message('Control:ltiobject:frdAmbiguousRate1'))
            sys.Ts = 1;
         end
      end

      function varargout = lftdata_(sys,varargin)
         % LFTDATA support for generalized LFT models
         [varargout{1:nargout}] = lftdata_(ufrd(sys),varargin{:});
      end

      %% BINARY OPERATIONS
      function [sys1,sys2] = matchAttributes(sys1,sys2)
         % Enforces matching attributes in binary operations (e.g.,
         % sample time, variable,...).
         [sys1,sys2] = matchAttributes@lti(sys1,sys2);
         % Check that frequency vectors match
         D1 = sys1.Data_;   D2 = sys2.Data_;
         if ~(isempty(D1) || isempty(D2) || ...
               FRDModel.isSameFrequencyGrid(D1(1).IC.Frequency,D2(1).IC.Frequency))
            error(message('Control:ltiobject:mrgfreq1'))
         end
      end

      %% INDEXING
      function sys = indexasgn_(sys,indices,rhs,ioSize,ArrayMask)
         % Data management in SYS(indices) = RHS.
         % ioSize is the new I/O size and ArrayMask tracks which
         % entries in the resulting system array have been reassigned.
         Data = sys.Data_;
         % Construct template initial value for new entries in system array
         if isempty(Data)
            Dfrd = ltipack.frddata(zeros([ioSize 0]),zeros(0,1),0);
         else
            freqs = Data(1).IC.Frequency;
            Dfrd = ltipack.frddata(zeros([ioSize length(freqs)]),freqs,Data(1).IC.Ts);
            Dfrd.FreqUnits = Data(1).IC.FreqUnits;
         end
         D0 = ltipack.lftdataFRD(Dfrd,ltipack.LFTBlockWrapper.emptyBlockList());
         % Update data
         try
            sys.Data_ = ltipack.reassignData(Data,indices,rhs.Data_,ioSize,ArrayMask,D0);
         catch ME
            if strcmp(ME.identifier,'Control:ltiobject:mrgfreq1')
               % Recast error message to assignment context
               error(message('Control:ltiobject:subsasgn4'))
            else
               throw(ME)
            end
         end
         % Update sampling grid
         if numel(indices)>2 && ~(isempty(sys.SamplingGrid_) && isempty(rhs.SamplingGrid_))
            sys.SamplingGrid_ = reassign(sys.SamplingGrid_,indices(3:end),rhs.SamplingGrid_,size(sys.Data_));
         end
      end

      %% Transformations
      function sys = getValue_(sys)
         % Returns current value
         sys = frd(sys);
      end

      function sys = getNominal_(sys)
         % Returns nominal value
         [sys,NoBlocks] = foldUncertainty_(sys);
         if NoBlocks
            sys = frd(sys);
         end
      end

   end

   %% PROTECTED METHODS
   methods (Access=protected)

      function s = getPropStruct(sys)
         % Move "Blocks" and "Frequency*" properties to the top
         s = getPropStruct@InputOutputModel(sys);
         n = numel(fieldnames(s));
         s = orderfields(s,[n-2:n 1:n-3]);
      end

      function sys = setTimeUnit_(sys,TU)
         % Change TimeUnit value.
         % Apply new value to dynamic blocks
         Data = sys.Data_;
         F1 = @(blk) isa(blk,'DynamicSystem');
         F2 = @(blk) setTimeUnit_(blk,TU);
         for ct=1:numel(Data)
            isDynamic = logicalfun(F1,Data(ct).Blocks);
            Data(ct).Blocks(isDynamic,:) = blockfun(F2,Data(ct).Blocks(isDynamic,:));
         end
         % When FrequencyUnit is not relative to TimeUnit, update stored
         % frequency vector value to preserve user-facing value.
         if isempty(strfind(sys.FrequencyUnit,'TimeUnit'))
            cf = tunitconv(TU,sys.TimeUnit);
            for ct=1:numel(Data)
               Data(ct).IC.Frequency = cf * Data(ct).IC.Frequency;
            end
         end
         sys.Data_ = Data;
         % Update property value
         sys = setTimeUnit_@DynamicSystem(sys,TU);
      end


   end

   %% STATIC METHODS
   methods(Static, Hidden)

      function sys = make(D,IOSize)
         % Constructs GENFRD model from nonempty ltipack.lftdataFRD array
         sys = genfrd;
         sys.Data_ = D;
         if nargin>1
            sys.IOSize_ = IOSize;  % support for empty model arrays
         else
            sys.IOSize_ = iosize(D(1));
         end
      end

      function sys = convert(X,refsys)
         % Safe conversion to GENFRD.
         %   X = GENFRD.CONVERT(X,REFSYS) casts the variable X to GENFRD using
         %   frequency vector and frequency units of REFSYS. This method is
         %   used in assignments, conversions to GENFRD, and binary operations
         %   to correctly handle numeric arrays, static models, and undefined
         %   sampling times.
         f = refsys.Frequency;
         Ts = refsys.Ts;
         if isnumeric(X)
            % Casting numeric array to GENFRD
            s = size(X);
            X = repmat(reshape(double(X),[s(1:2) 1 s(3:end)]),[1 1 length(f)]);
            sys = genfrd(frd(X,f,Ts));
            sys.TimeUnit = refsys.TimeUnit;
            sys.FrequencyUnit = refsys.FrequencyUnit;
         elseif isa(X,'StaticModel')
            % Casting static model to GENFRD. Make sure to propagate time units
            sys = genfrd(X,f,refsys.FrequencyUnit,refsys.TimeUnit);
         elseif isa(X,'DynamicSystem')
            % Casting dynamic model to GENFRD
            if X.Ts==-1 && (Ts>0 || isstatic(X))
               % Override Ts=-1 before computing frequency response
               X.Ts = Ts;
            end
            sys = genfrd(X,f,refsys.FrequencyUnit);
         end
      end

      function blk = loadobj(s)
         % Load filter for GENFRD objects
         if isa(s,'genfrd')
            blk = DynamicSystem.updateMetaData(s);
            blk.Version_ = ltipack.ver();
         end
      end

   end

end
