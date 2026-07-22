classdef tunableBlock < ControlDesignBlock
   % Tunable Control Design Blocks.
   %
   %   Tunable Control Design blocks provide parameterizations of basic 
   %   control system components such as gains, transfer functions, PIDs, 
   %   and state-space models. You can also create your own tunable components 
   %   using the "realp" block (real parameter). Use these blocks to model 
   %   the tunable portion of your control system. You can then automatically 
   %   tune the block parameters with commands like SYSTUNE.
   %
   %   All tunable Control Design blocks derive from the @tunableBlock 
   %   superclass. This class is not user-facing and cannot be instantiated. 
   %   User-facing subclasses include:
   %     * Predefined components such as tunableGain, tunablePID, tunableTF,
   %       and tunableSS. For example,
   %           PI = tunablePID('C','pi')
   %       creates a tunable PI controller named "C"
   %     * The REALP building block (real parameter). This lets you create 
   %       elementary parameters and combine them into MATLAB expressions to 
   %       create custom tunable components. For example,
   %           a = realp('a',1);
   %           F = tf(a,[1 a])
   %       creates a low-pass filter with a tunable cutoff frequency "a".
   %
   %   You can combine tunable Control Design blocks with ordinary LTI 
   %   models to construct tunable models of your control system (see GENLTI) 
   %   and automatically tune the control system parameters with SYSTUNE,
   %   LOOPTUNE, or HINFSTRUCT.
   %
   %   See also tunableGain, tunablePID, tunablePID2, tunableTF, tunableSS,
   %   realp, ControlDesignBlock, genlti, systune, looptune, hinfstruct.
   
%   Copyright 2010-2012 The MathWorks, Inc.
   
   %% TUNABLEBLOCK INTERFACE
   methods (Access = protected)
      % Serializes param.Continuous objects
      np = nparams_(blk,varargin)
      p = getp_(blk,varargin)
      [pMin,pMax] = getpMinMax_(blk)
      blk = setp_(blk,p,varargin)
      blk = zeroThru_(blk,mustZero)
      isf = isfree_(blk)
      p = randp_(blk,varargin)
   end
   
   %% PUBLIC METHODS
   methods
      
      function np = nparams(blk,varargin)
         %NPARAMS  Number of block parameters.
         %
         %   NP = NPARAMS(BLK) returns the total number NP of parameters used 
         %   in the parametric block BLK. This number includes both free and 
         %   fixed parameters.
         %
         %   NPF = NPARAMS(BLK,'free') returns the number of free parameters.
         %
         %   See also GETP, SETP, RANDP, ISFREE, TUNABLEBLOCK.
         np = nparams_(blk,varargin{:});
      end
      
      function isf = isfree(blk)
         %ISFREE  True for free block parameters.
         %
         %   ISF = ISFREE(BLK) returns a logical vector ISF with as many
         %   entries as parameters in the parametric block BLK. The j-th
         %   entry of ISF is true if the j-th parameter is free and 
         %   is false if the j-th parameter is fixed.
         %
         %   See also GETP, SETP, TUNABLEBLOCK.
         isf = isfree_(blk);
      end
      
      function p = getp(blk,varargin)
         %GETP  Gets block parameter values.
         %
         %   P = GETP(BLK) returns the vector of current parameter values for the
         %   parametric block BLK. Both fixed and free parameters are included.
         %
         %   X = GETP(BLK,'free') returns the values of free parameters only.
         %   The vector X is the same as P(ISFREE(BLK)).
         %
         %   See also SETP, NPARAMS, ISFREE, TUNABLEBLOCK.
         p = getp_(blk,varargin{:});
      end
      
      function [pMin,pMax] = getpMinMax(blk)
         %GETPMINMAX  Gets min/max bounds for block parameter values.
         %
         %   [PMIN,PMAX] = GETPMINMAX(BLK) returns the vectors of minimum and
         %   maximum values for the block parameters.
         %
         %   See also GETP, NPARAMS, ISFREE, TUNABLEBLOCK.
         [pMin,pMax] = getpMinMax_(blk);
      end
      
      function blk = setp(blk,p,varargin)
         %SETP  Sets block parameter values.
         %
         %   BLK = SETP(BLK,P) sets the parameters of the parametric block BLK to
         %   the values specified in the vector P. The length of P must match the
         %   total number of parameters NPARAMS(BLK). 
         %
         %   BLK = SETP(BLK,X,'free') only sets the free parameters. The remaining
         %   parameters are held at their current value. The length of X must match 
         %   the number of free parameters.
         %
         %   See also GETP, NPARAMS, ISFREE, TUNABLEBLOCK.
         try
            blk = setp_(blk,p,varargin{:});
         catch ME
            throw(ME)
         end
      end 
      
      function P = randp(blk,varargin)
         %RANDP  Generates random samples of block parameters.
         %
         %   P = RANDP(BLK,N) generates N random samples of the parametric
         %   Control Design block BLK. The output P is a matrix where P(:,j) 
         %   is the j-th sample value of the parameter vector. Both fixed 
         %   and free parameters are sampled.
         %
         %   X = RANDP(BLK,N,'free') samples only the free parameters in BLK.
         %   The resulting matrix X has N columns and as many rows as free
         %   parameters.
         %
         %   Use SETP to set the current value of BLK to any of these random
         %   parameter samples.
         %
         %   See also GETP, SETP, NPARAMS, TUNABLEBLOCK.
         try
            P = randp_(blk,varargin{:});
         catch ME
            throw(ME)
         end
      end
      
      % Feedthrough elimination in H2 requirements (SYSTUNE)
      function blk = zeroThru(blk,mustZero)
         %ZEROTHRU  Zero out a portion of the block feedthrough.
         %
         %   BLK = ZEROTHRU(BLK,MUSTZERO) eliminates the specified portion
         %   of the block feedthrough by fixing the correspoonding block
         %   parameters to zero. No action is taken if these parameters are
         %   already fixed to a zero or nonzero value. MUSTZERO is a
         %   logical array commensurate with the block size.
         %
         %   See also TUNABLEBLOCK.
         try
            blk = zeroThru_(blk,mustZero);
         catch ME
            throw(ME)
         end
      end
      
   end 
   
   methods (Hidden)
      
      function BlockList = getTunableBlocks(blk)
         % Gets list of tunable blocks
         BlockList = {blk};
      end
      
   end
   
   %% DATA ABSTRACTION INTERFACE
   methods (Access = protected)
      
      function boo = isParametric_(~)
         boo = true;
      end
            
      function boo = isfinite_(blk,~)
         boo = allfinite(getp_(blk));
      end
      
   end
      
   
end
