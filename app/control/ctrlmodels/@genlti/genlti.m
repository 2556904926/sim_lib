classdef (SupportExtensionMethods=true) genlti < lti & ltipack.DynamicLFT 
   % Generalized LTI Model objects.
   %
   %   Generalized LTI models arise when connecting ordinary LTI models (see NUMLTI) 
   %   with special blocks such as tunable elements, uncertain elements, and 
   %   analysis points (see ControlDesignBlock). GENLTI models keep track of how 
   %   these special blocks blocks interact with the fixed LTI dynamics. 
   %
   %   There are two types of generalized LTI models:
   %     * Generalized state-space models (GENSS), which arise when there are no
   %       FRD models among the ordinary LTI models
   %     * Generalized FRD models (GENFRD), which arise when there is at least one
   %       FRD model in the mix.
   %   All generalized LTI models derive from the @genlti superclass. This class is   
   %   not user-facing and cannot be instantiated.
   %
   %   For analysis purposes, generalized LTI models are treated as ordinary LTI
   %   models by replacing all Control Design blocks by their current/nominal value.
   %
   %   Example: Consider the feedback loop
   %
   %             r --->O--->[ C ]--->[ G ]---+---> y
   %                 - |                     |
   %                   +---------------------+
   %
   %   where the plant is modeled as G(s) = exp(-0.5*s)/(s+2) and C is a PI controller 
   %   to be tuned. Construct a tunable model of the closed-loop transfer T from 
   %   r to y:
   %
   %       s = tf('s');  G = exp(-0.5*s)/(s+2);
   %       C = tunablePID('C','pi');
   %       T = feedback(G*C,1);
   %
   %   The result is a GENSS model T with a single tunable block (see T.Blocks).
   %   You can use commands like SYSTUNE to automatically tune the PI gains for 
   %   specific performance requirements.
   %
   %   See also GENSS, GENFRD, NUMLTI, LTI, CONTROLDESIGNBLOCK, SYSTUNE.
   
   %   Author(s): P. Gahinet
   %   Copyright 2009-2010 The MathWorks, Inc.
   
   %   ZPK, PID, FRD) with Control Design blocks such as tunable compensators or
   %   uncertain elements (see CONTROLDESIGNBLOCK for details). GENLTI models keep track
   %   of how the Control Design blocks interact with the LTI dynamics.
   %
   %   There are two main types of generalized LTI models:
   %     * Generalized state-space models (@genss or @uss), which arise when all
   %       LTI models are of class @tf, @zpk, @ss, @pid, or @pidstd
   %     * Generalized FRD models (@genfrd or @ufrd), which arise when at least
   %       one LTI model is of class @frd
   
   % Add static method to be included for compiler
   %#function genlti.loadobj
   
   methods
      function AP = getSwitches(sys)
         %GETSWITCHES  Get analysis point locations.
         %
         %   getSwitches is an alias for getPoints.
         %
         %   See also getPoints, loopswitch.
         AP = getPoints(sys);
      end
            
   end

   %% ABSTRACT SUPERCLASS INTERFACES
   methods (Access = protected)
      
      function Ts = getTs_(sys)
         % Get sample time
         if isempty(sys.Data_)
            Ts = 0;
         else
            Ts = sys.Data_(1).IC.Ts;
         end
      end
      
      function sys = setTs_(sys,Ts)
         % Set sample time
         Data = sys.Data_;
         F1 = @(blk) isa(blk,'DynamicSystem');
         F2 = @(blk) setTs_(blk,Ts);
         for ct=1:numel(Data)
            Data(ct).IC.Ts = Ts;
            isSR = logicalfun(F1,Data(ct).Blocks);
            Data(ct).Blocks(isSR) =  blockfun(F2,Data(ct).Blocks(isSR));
            if sys.CrossValidation_
               % Check for fractional delays with Ts~=0
               Data(ct).IC = checkDelay(Data(ct).IC);
            end
         end
         sys.Data_ = Data;
      end
      
   end

   %% DATA ABSTRACTION INTERFACE
   methods (Access = protected)
      %% TRANSFORMATIONS
      function sys = chgTimeUnit_(sys,newUnits)
         % Changes time units without altering system behavior
         sf = tunitconv(sys.TimeUnit,newUnits);
         % Rescale system data according to tnew = sf * told
         Data = sys.Data_;
         F1 = @(blk) isa(blk,'DynamicSystem');
         F2 = @(blk) chgTimeUnit_(blk,newUnits);
         for ct=1:numel(Data)
            Data(ct).IC = scaleTime(Data(ct).IC,sf);
            isDynamic = logicalfun(F1,Data(ct).Blocks);
            Data(ct).Blocks(isDynamic,:) = blockfun(F2,Data(ct).Blocks(isDynamic,:));
         end
         sys.Data_ = Data;
         % Store new time units
         if strcmp(newUnits,'seconds')
            sys.TimeUnit_ = [];
         else
            sys.TimeUnit_ = newUnits;
         end
      end         
         
      function varargout = balred_(sys,varargin)
         error(message('Control:general:NotSupportedModelsofClass','balred',class(sys)))
      end
      
      function varargout = c2d_(sys,varargin) %#ok<*STOUT>
         error(message('Control:general:NotSupportedModelsofClass','c2d',class(sys)))
      end
      
      function varargout = d2c_(sys,varargin)
         error(message('Control:general:NotSupportedModelsofClass','d2c',class(sys)))
      end
      
      function varargout = d2d_(sys,varargin)
         error(message('Control:general:NotSupportedModelsofClass','d2d',class(sys)))
      end
      
      function sys = upsample_(sys,~)
         error(message('Control:general:NotSupportedModelsofClass','upsample',class(sys)))
      end
   end

   %% PROTECTED METHODS
   methods (Access = protected)
      
      function checkBlockCompatibility(sys,B)
         % Default implementation: just ensure correct sample time and time units
         checkTimeInfo(B,sys.Ts,sys.TimeUnit)
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
         sys.Data_ = Data;
         % Update property value
         sys = setTimeUnit_@DynamicSystem(sys,TU);
      end

   end
   
   methods (Hidden, Static)
      
      function Msg = resolveSignalError(ErrID,MisMatch,SignalList)
         % Manages errors related to unresolved or ambiguous identifiers in
         % get*Transfer methods
         if isempty(MisMatch)
            Msg = '';
         else
            iMatch = MisMatch.iMatch;
            if isempty(iMatch)
               % No match
               Msg = message([ErrID '1'],MisMatch.ID);
            else
               % Multiple matches. List the first two
               Matches = strrep(SignalList(iMatch(1:2)),'[]','');
               Msg = message([ErrID '2'],MisMatch.ID,Matches{:});
            end
         end
      end

      
   end
   
end
