classdef (Hidden) ConfigGenSS < systuneapp.data.MatlabConfigData.AbstractConfig
   %   M = SYSTUNE.DATA.MATLABCONFIGDATA.CONFIGGENSS(GENSS) manages the
   %   genss design
   
   % Copyright 2013 The MathWorks, Inc.
   
   properties(Access = public, SetObservable)
      TunableBlocks
      System
   end
   
   properties (Transient)
      TunableBlocksChangedListener
   end
   
   methods (Access = public)
      %% Constructor
      function this = ConfigGenSS(AGenSS, VarName)
         
         if nargin == 0
            AGenSS = feedback(tf(1,[1 2*0.7 1])*tunableGain('C',1),1);
            AGenSS.UserData = 'feedback(tf(1,[1 2*0.7 1])*tunableGain(''C'',1),1)';
            setConfigData(this,AGenSS);
         elseif (nargin == 1 || nargin == 2) && isa(AGenSS,'genss')
            if nargin == 2 && ischar(VarName)
               AGenSS.UserData = VarName;
            end
            setConfigData(this,AGenSS);
         else
            error(message('Control:systunegui:MLConfigDataErrorInputNumber','0','1'));
         end
         
      end
      
      function obj = copy(this)
         aGenss = this.System;
         obj = systuneapp.data.MatlabConfigData.ConfigGenSS(aGenss);
         setTuningInfo(obj,getTuningInfo(this));
      end
      
      function Name = getName(this)
         Name = 'Config GenSS';
      end
      
      function Ts = getTs(this)
         Ts = this.System.Ts;
      end
      
      function CL = computeCL(this,Design)
         Blocks = this.System.Blocks;
         for ct = 1:length(this.TunableBlocks)
            TB = this.TunableBlocks(ct);
            Blocks.(TB.BlockPath) = getParameterization(TB);
         end
         this.System.Blocks = Blocks;
         CL = this.System;
      end
      
      function TB = getTunableBlocks(this)
         TB = this.TunableBlocks;
      end
      
      function validateConfigurationData_(this,AGenSS)
          if ~(AGenSS.Ts>=0)
              error(message('Control:systunegui:MLConfigDataGenssErrorInvalidSampleTime'));
          end
      end
      
      function event = setConfigData_(this,AGenSS)
         this.Dirty = true;
         Blocks = AGenSS.Blocks;
         
         % Fill in block I/O names
         idxout = find(cellfun(@isempty,AGenSS.OutputName));
         if ~isempty(idxout)
            if isequal(length(idxout),1)
               AGenSS.OutputName = 'out';
            else
               idxct = 1;
               for ct = 1:length(idxout)
                  AGenSS.OutputName{idxout(ct)} = sprintf('out(%d)',idxct);
                  idxct = idxct+1;
               end
            end
         end
         idxin = find(cellfun(@isempty,AGenSS.InputName));
         if ~isempty(idxin)
            if isequal(length(idxin),1)
               AGenSS.InputName = 'in';
            else
               idxct = 1;
               for ct = 1:length(idxin)
                  AGenSS.InputName{idxin(ct)} = sprintf('in(%d)',idxct);
                  idxct = idxct+1;
               end
            end
         end
         
         BV = struct2cell(Blocks);
         BV = BV(cellfun(@isParametric,BV));
         TB = cell(1,0);
         TBL = cell(1,0);
         for idx = 1:numel(BV)
            TB{:,idx} = systuneapp.data.MatlabConfigData.TunableBlock(BV{idx});
            TB{:,idx}.SupportGenss = false;
            weakThis = matlab.lang.WeakReference(this);
            TBL{:,idx} = addlistener(TB{:,idx}, 'ParameterizationChanged', @(es, ed)updateParameterization(weakThis.Handle, es));
         end
         
         if isempty(TB)
            error(message('Control:systunegui:MLConfigDataErrorTunableBlock', ''));
         else
            this.TunableBlocks = [TB{:}];
            this.TunableBlocksChangedListener = [TBL{:}];
         end
         
         event = 'ConfigChanged';
         this.System = AGenSS;
      end
      
      function MLConfigTC = getMLConfigTC(this)
         MLConfigTC = systuneapp.dialogs.MLConfig.GenssConfigTC(this);
      end
      
      function updateParameterization(this, es)
         this.System.Blocks.(es.BlockPath) = getParameterization(es);
      end
      
      function flag = isDataFresh(this)
         sys = this.System;
         sys.InputName = [];
         sys.OutputName = [];
         sysinit = feedback(tf(1,[1 2*0.7 1])*tunableGain('C',1),1);
         sysinit.UserData = 'feedback(tf(1,[1 2*0.7 1])*tunableGain(''C'',1),1)';
         flag = isequal(sys,sysinit);
      end
      

   end
   methods(Hidden = true)
      function Text = generateMATLABCode(this, VarName)
         %% Name
         if nargin < 2
            VarName = matlab.lang.makeValidName(this.System.Name);
         end
         %% Title
         Text = cell(0,1);
         Text = controllib.internal.codegen.appendMATLABCode(Text,...
            sprintf('%%%% %s', getString(message('Control:systunegui:CodegenConfigGenssCreateSystem'))));
         %% Construct genss
         if isempty(this.System.UserData)
            % If the user typed in a genss expression when constructing
            % the CST
            
            MetaData = sprintf('%s; %% %s', getString(message('Control:systunegui:CodegenConfigGenssSystemToBeTuned')), getString(message('Control:systunegui:CodegenConfigGenssSetSystem')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, [VarName, ' = ', MetaData]);
            if ~isempty(this.System.InputName)
               IText = sprintf('%% %s: %s', getString(message('Control:systunegui:CodegenConfigGenssInputs')), controllib.internal.codegen.cellToString(this.System.InputName));
               Text = controllib.internal.codegen.appendMATLABCode(Text, IText);
            end
            if ~isempty(this.System.OutputName)
               OText = sprintf('%% %s: %s', getString(message('Control:systunegui:CodegenConfigGenssOutputs')), controllib.internal.codegen.cellToString(this.System.OutputName));
               Text = controllib.internal.codegen.appendMATLABCode(Text, OText);
            end
            if ~isempty(this.TunableBlocks)
               BText = sprintf('%% %s: %s', getString(message('Control:systunegui:CodegenConfigGenssBlocks')), controllib.internal.codegen.cellToString(fieldnames(this.System.Blocks)));
               Text = controllib.internal.codegen.appendMATLABCode(Text, BText);
            end
            
         else
            % If the user supplied a variable for the closed loop
            % system at the command-line or an expression/ variable
            % using the dialog
            
            MetaData = sprintf('%s;', this.System.UserData);
            Text = controllib.internal.codegen.appendMATLABCode(Text, [VarName, ' = ', MetaData]);
            
            InputNames = sprintf('%s.%s = %s', VarName, 'InputName', controllib.internal.codegen.cellToString(this.System.InputName));
            OutputNames = sprintf('%s.%s = %s', VarName, 'OutputName', controllib.internal.codegen.cellToString(this.System.OutputName));
            IOText = sprintf('%s;     %s;', InputNames, OutputNames);
            Text = controllib.internal.codegen.appendMATLABCode(Text, IOText);
         end
         
         %% Set block parameterization
         if ~isempty(this.TunableBlocks)
            for ct = numel(this.TunableBlocks):-1:1
               if isa(this.TunableBlocks(ct).getParameterization, 'realp')
                  Text = [Text; localGenerateMATLABCodeRealp(this, this.TunableBlocks(ct).getParameterization)];
                  BlockText = [VarName, '.Blocks.', this.TunableBlocks(ct).Name ' = ' this.TunableBlocks(ct).Name ';'];
                  Text = [Text; BlockText];
               else
                  if ~isempty(this.TunableBlocks(ct).getParameterization.UserData)
                     Text = [Text; this.TunableBlocks(ct).getParameterization.UserData];
                     BlockText = [VarName, '.Blocks.', this.TunableBlocks(ct).Name ' = ' this.TunableBlocks(ct).Name ';'];
                     Text = [Text; BlockText];
                  end
               end
               
            end
         end
         
      end
   end
   
   methods(Access = public, Hidden = true)
      function this = loadobj_(this)
         TB = this.getTunableBlocks;
         weakThis = matlab.lang.WeakReference(this);
         for ct = 1:length(TB)
            L(ct) = addlistener(TB(ct),'ParameterizationChanged',@(es,ed) updateParameterization(weakThis.Handle, es));
         end
         if ~isempty(TB)
            this.TunableBlocksChangedListener = L;
         end
      end
      
      function Text = localGenerateMATLABCodeRealp(this, ARealp)
         %% Title
         Text = cell(0,1);
         Text = controllib.internal.codegen.appendMATLABCode(Text,...
            sprintf('%% %s', getString(message('Controllib:gui:CodegenSetParam'))));
         %% Name
         VarName = ARealp.Name;
         LTIBlockName = systuneapp.util.createVariableName(VarName);
         
         %% Realp
         default = realp(LTIBlockName, ones([1, 1]));
         actual = ARealp;
         [num_in, num_out] = iosize(actual);
         Text = controllib.internal.codegen.appendMATLABCode(Text, sprintf('%s = realp(''%s'',ones([%s,%s]));', VarName, LTIBlockName, num2str(num_out), num2str(num_in)));
         
         
         
         ValueCode = [sprintf('%s.Value', VarName) ' = ', mat2str(actual.Value), ';'];
         Text = controllib.internal.codegen.appendMATLABCode(Text, ValueCode);
         if any(default.Minimum ~= actual.Minimum)
            MinCode = [sprintf('%s.Minimum', VarName) ' = ', mat2str(actual.Minimum), ';'];
            Text = controllib.internal.codegen.appendMATLABCode(Text, MinCode);
         end
         if any(default.Maximum ~= actual.Maximum)
            MaxCode = [sprintf('%s.Maximum',VarName) ' = ', mat2str(actual.Maximum), ';'];
            Text = controllib.internal.codegen.appendMATLABCode(Text, MaxCode);
         end
         if any(default.Free ~= actual.Free)
            FreeCode = [sprintf('%s.Free',VarName) ' = ', mat2str(actual.Free), ';'];
            Text = controllib.internal.codegen.appendMATLABCode(Text, FreeCode);
         end
         
      end
   end
   
   methods (Access = private)
      
   end
end
