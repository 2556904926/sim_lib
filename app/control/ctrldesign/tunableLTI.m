classdef tunableLTI < DynamicBlock & tunableBlock
   % Tunable LTI blocks.
   
%   Author(s): P. Gahinet
%   Copyright 1986-2015 The MathWorks, Inc.

   % State-space conversion support:
   %            ssdata_
   %      blk   ------->   A,B,C,D
   %       |                 |
   %       +----->  p  ------+
   %        getp        p2ss
   

   %% PROTECTED INTERFACES
   methods (Access = protected)
      
      function sys = setTs_(sys,Ts)
         % Implementation of @SingleRateSystem:setTs_
         if Ts==-1
            error(message('Control:tuning:TuningReq19'))
         end
         sys = setTs_@DynamicBlock(sys,Ts);
      end
      
      % Indexing operations (see RedefinesParen)
      function M = parenReference(blk, indexingOperation)
         % Indexing forces conversion to GENSS
         M = parenReference(genss(blk), indexingOperation);
      end
      
   end
   
   %% DATA ABSTRACTION INTERFACE
   % Note: Default implementation geared to blocks with state-space representation
   methods (Access = protected)
            
      %% INDEXING
      function M = createLHS(~)
         % Creates LHS in assignment. Returns 0x0 GENSS 
         M = genss();
      end
      
      %% TRANSFORMATIONS      
      function sys = getValue_(blk)
         % Returns current value
         sys = ss(blk);
      end
      
      function blk = conj_(blk)
      end
      
      function sys = uminus_(blk)
         sys = uminus_(genss(blk));
      end
      
      function sys = repmat_(blk,s)
         sys = repmat_(genss(blk),s);
      end
      
      %% STATE-SPACE MODELS
      function W = gram_(blk,type)
         W = gram_(ss(blk),type);
      end
      
   end
   
   methods (Hidden)
      
      function CS = randSample_(blk,N)
         % Randomly samples tunable block. Returns N-by-1 cell array of 
         % ltipack.ssdata objects.
         P = randp_(blk,N);
         isf = isfree_(blk);
         if ~all(isf)
            % Overwrite fixed entries
            p0 = getp_(blk);
            P(~isf,:) = p0(~isf,ones(N,1));
         end
         Ts = blk.Ts_;
         CS = cell(N,1);
         for ct=1:N
            [a,b,c,d] = p2ss(blk,P(:,ct));
            CS{ct} = ltipack.ssdata(a,b,c,d,[],Ts); 
         end
      end
                  
   end
   
   
end
