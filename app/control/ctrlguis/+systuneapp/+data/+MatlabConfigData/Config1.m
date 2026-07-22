classdef (Hidden) Config1 < systuneapp.data.MatlabConfigData.AbstractConfig
    %   M = SYSTUNEAPP.DATA.MATLABCONFIGDATA.CONFIG1(G,C,H,F) computes a genss
    %   closed-loop model for the feedback loop:
    %
    %                                   du            dy
    %                 rf    e        uc | u        yg |
    %      r -->[ F ]---->O--->[ C ]----O--->[ G ]----O---> y
    %                     |                             |
    %                (-1) +-----O<----[ H ]<------------+
    %                       ym  |  yh
    %                           n
    %
    %   Negative feedback is assumed.
    
    % Copyright 2013 The MathWorks, Inc.
    
    properties(Access = public, SetObservable)
        C
        F
        G
        H
    end
    
    methods (Access = public)
        
        %% Constructor
        function this = Config1(varargin)
            if nargin==0 % construct with no input system
                F = tunableGain('F',1);
                F.Name = 'F';
                C = tunableGain('C',1);
                C.Name = 'C';
                G = ss(1);
                H = ss(1);
            elseif nargin == 1
                G = varargin{1};
                [mG,nG] = iosize(G);
                H = ss(eye(nG,mG));
                F = tunableGain('F',eye(nG));
                F.Name = 'F';
                C = tunableGain('C',eye(nG));
                C.Name = 'C';
            elseif nargin == 2
                G = varargin{1};
                [mG,nG] = iosize(G);
                C = varargin{2};
                C.Name = 'C';
                [~,nC] = iosize(C);
                H = ss(eye(nC,mG));
                F = tunableGain('F',eye(nC));
                F.Name = 'F';
            elseif nargin == 3
                G = varargin{1};
                [~,nG] = iosize(G);
                C = varargin{2};
                C.Name = 'C';
                [~,nC] = iosize(C);
                H = varargin{3};
                F = tunableGain('F',eye(nC));
                F.Name = 'F';
                
            elseif nargin == 4 % construct with input systems
                G = varargin{1};
                C = varargin{2};
                H = varargin{3};
                F = varargin{4};
            else
                error(message('Control:systunegui:MLConfigDataErrorInputNumber','0','4'));
            end
            setConfigData(this,C,F,G,H);
        end
        
        function obj = copy(this)
            aG = this.G;
            aH = this.H;
            aC = getParameterization(this.C);
            aF = getParameterization(this.F);
            obj = systuneapp.data.MatlabConfigData.Config1(aG,aC,aH,aF);
            setTuningInfo(obj,getTuningInfo(this));
        end
        
        function Name = getName(this)
            Name = 'Config 1';
        end
        
        function CL = computeCL(this)
            constructClosedLoop(this,getParameterization(this.C),getParameterization(this.F),this.G,this.H);
            CL = this.ClosedLoop;            
        end
        
        function Signals = getAvailableSignals(this,Type) 
           if nargin == 1
                Type = 'All';
            end
            
            T = getCL(this);
                        
            switch Type
                case 'Inputs'
                    Signals = T.InputName;
                case 'Outputs'
                    Signals = T.OutputName;
                case 'Locations' % Switch Names (e,u,ym)
                    Signals = cell(0,1);
                    if size(T.Blocks.e,1)==1                        
                        Signals = [Signals; 'e'];                           
                    else
                        Signals = [Signals; ...
                            arrayfun(@(x) ['e(' num2str(x) ')'],(1:size(T.Blocks.e,1))','UniformOutput',false)];
                    end
                    if size(T.Blocks.u,1)==1                        
                        Signals = [Signals; 'u'];                           
                    else
                        Signals = [Signals; ...
                            arrayfun(@(x) ['u(' num2str(x) ')'],(1:size(T.Blocks.u,1))','UniformOutput',false)];
                    end
                    if size(T.Blocks.ym,1)==1                        
                        Signals = [Signals; 'ym'];                           
                    else
                        Signals = [Signals; ...
                            arrayfun(@(x) ['ym(' num2str(x) ')'],(1:size(T.Blocks.ym,1))','UniformOutput',false)];
                    end                    
                case 'All'
                    Signals = [T.InputName; T.OutputName];    
            end
        end
        
               
        function TB = getTunableBlocks(this)
            TB = [this.C;this.F];            
        end
        
        function event = setConfigData_(this,C,F,G,H)
            this.Dirty = true;
            if isempty(this.C) || isempty(this.F) ||...
                isempty(this.G) || isempty(this.H)
                event = 'ConfigChanged';
            elseif isequal(size(this.G),size(G)) && ...
                    isequal(size(this.H),size(H)) && ...
                    isequal(iosize(this.C),iosize(C)) && ...
                    isequal(iosize(this.F),iosize(F))
                event = 'DataChanged';
            else
                event = 'ConfigChanged';
            end
                
            this.G = G;
            this.H = H;
            C.Name = 'C';
            F.Name = 'F';
            this.C = systuneapp.data.MatlabConfigData.TunableBlock(C);
            this.F = systuneapp.data.MatlabConfigData.TunableBlock(F);
        end
        function MLConfigTC = getMLConfigTC(this)
            MLConfigTC = systuneapp.dialogs.MLConfig.Config1TC(this);
        end        
        function flag = isDataFresh(this)
            Fblock = tunableGain('F',1);
            Cblock = tunableGain('C',1);
            flag = isequal(this.F.getParameterization,Fblock) & ...
                   isequal(this.C.getParameterization,Cblock) & ...
                   isequal(this.G,ss(1)) & ...
                   isequal(this.H,ss(1));
        end        
        
        function Text = generateMATLABCode(this, SysName)
            Text = cell(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%%%% %s', getString(message('Control:systunegui:CodegenConfig1CreateSystem'))));
            %% F
            F = this.F.getParameterization;
            if isa(F, 'realp')
                FText = localGenerateMATLABCodeRealp(this, F);
            else
                FText = F.UserData;
                if isempty(FText)
                    
                    % default case, F has not been edited
                    VarName = matlab.lang.makeValidName(F.Name);
                    if isempty(VarName)
                        VarName = 'mylti';
                    end
                    [ny, nu] = iosize(F);
                    FText = sprintf('%s = tunableGain(''%s'',ones([%s,%s]));', VarName, VarName, num2str(ny), num2str(nu));
                end
            end                     
                FInputNames = sprintf('%s.%s = ''%s''', 'F', 'InputName', 'rSwitchOutputName');
                FOutputNames = sprintf('%s.%s = ''%s''', 'F', 'OutputName', 'rf');
                FNames = sprintf('%s.%s = ''%s''', 'F', 'Name', 'F');
                FIOText = sprintf('%s;     %s;      %s;', FInputNames, FOutputNames, FNames);
                
                Text = controllib.internal.codegen.appendMATLABCode(Text,...
                    sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1DefineF'))));
                Text = [Text; FText]; %#ok<*PROP>
                Text = controllib.internal.codegen.appendMATLABCode(Text, FIOText);
            %% C
            C = this.C.getParameterization;
            
            if isa(C, 'realp')
                CText = localGenerateMATLABCodeRealp(this, C);
            else
                CText = C.UserData;
                if isempty(CText)
                    
                    % default case, C has not been edited
                    if isempty(C.Name)
                        VarName = 'mylti';
                    else
                        VarName = matlab.lang.makeValidName(C.Name);
                    end
                    [ny, nu] = iosize(C);
                    CText = sprintf('%s = tunableGain(''%s'',ones([%s,%s]));', VarName, VarName, num2str(ny), num2str(nu));
                end
            end
            CInputNames = sprintf('%s.%s = ''%s''', 'C', 'InputName', 'e');
            COutputNames = sprintf('%s.%s = ''%s''', 'C', 'OutputName', 'uc');
            CNames = sprintf('%s.%s = ''%s''', 'C', 'Name', 'C');
            CIOText = sprintf('%s;     %s;      %s;', CInputNames, COutputNames, CNames);
            
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1DefineC'))));
            Text = [Text; CText];
            Text = controllib.internal.codegen.appendMATLABCode(Text, CIOText);
            
            %% G
            G = this.G.UserData;         
            if isempty(G)
                % Default G
                G = sprintf('ss(ones([%d,%d]))', iosize(this.G));
            end
            GText = sprintf('%s = %s;', 'G', G);
            
            GInputNames = sprintf('%s.%s = ''%s''', 'G', 'InputName', 'u');            
            GOutputNames = sprintf('%s.%s = ''%s''', 'G', 'OutputName', 'yg');
            GNames = sprintf('%s.%s = ''%s''', 'G', 'Name', 'G');
            GIOText = sprintf('%s;     %s;      %s;', GInputNames, GOutputNames, GNames);
            
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1DefineG'))));
            Text = controllib.internal.codegen.appendMATLABCode(Text, GText);
            Text = controllib.internal.codegen.appendMATLABCode(Text, GIOText);
                            
            %% H
            H = this.H.UserData;
            if isempty(H)
                % Default H
                H = sprintf('ss(ones([%d,%d]))', iosize(this.H));
            end
            HText = sprintf('%s = %s;', 'H', H);
            
            HInputNames = sprintf('%s.%s = ''%s''', 'H', 'InputName', 'y');
            HOutputNames = sprintf('%s.%s = ''%s''', 'H', 'OutputName', 'yh');
            HNames = sprintf('%s.%s = ''%s''', 'H', 'Name', 'H');
            HIOText = sprintf('%s;     %s;      %s;', HInputNames, HOutputNames, HNames);
  
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1DefineH'))));
            Text = controllib.internal.codegen.appendMATLABCode(Text, HText);
            Text = controllib.internal.codegen.appendMATLABCode(Text, HIOText);
            
            %% IO sizes
            Text = vertcat(Text,{''});
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1GetIOSizes'))));
            
            FiosizeText = sprintf('[%s, %s] = iosize(%s);', 'nOutputF', 'nInputF', 'F');
            CiosizeText = sprintf('[%s, ~] = iosize(%s);', 'nOutputC', 'C');
            GiosizeText = sprintf('[%s, ~] = iosize(%s);', 'nOutputG', 'G');
            HiosizeText = sprintf('[%s, ~] = iosize(%s);', 'nOutputH', 'H');
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, FiosizeText);
            Text = controllib.internal.codegen.appendMATLABCode(Text, CiosizeText);
            Text = controllib.internal.codegen.appendMATLABCode(Text, GiosizeText);
            Text = controllib.internal.codegen.appendMATLABCode(Text, HiosizeText);
            
            Text = vertcat(Text,{''});
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1CreateSummingJunction'))));
            
            %% sum blocks
            eSumText = sprintf('%s = sumblk(''%s = %s + %s'',%s);', 'eSum', 'eSwitchInputName', '-ym', 'rf', 'nOutputF');
            uSumText = sprintf('%s = sumblk(''%s = %s + %s'',%s);', 'uSum', 'uSwitchInputName', 'uc', 'du', 'nOutputC');
            ySumText = sprintf('%s = sumblk(''%s = %s + %s'',%s);', 'ySum', 'ySwitchInputName', 'yg', 'dy', 'nOutputG');
            ymSumText = sprintf('%s = sumblk(''%s = %s + %s'',%s);', 'ymSum', 'ymSwitchInputName', 'yh', 'n', 'nOutputH');
            
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, eSumText, '', getString(message('Control:systunegui:CodegenConfig1SumAt', 'e')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, uSumText, '', getString(message('Control:systunegui:CodegenConfig1SumAt', 'u')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, ySumText, '', getString(message('Control:systunegui:CodegenConfig1SumAt', 'y')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, ymSumText,'', getString(message('Control:systunegui:CodegenConfig1SumAt', 'ym')));
            
            Text = vertcat(Text,{''});
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                 sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1CreateAP'))));
            
            %% Switches
            rSwitchText = sprintf('%s = AnalysisPoint(''%s'',%s);', 'rSwitch', 'r','nInputF');
            rSwitchInputNames = sprintf('%s.%s = ''%s''', 'rSwitch', 'InputName', 'r');
            rSwitchOutputNames = sprintf('%s.%s = ''%s''', 'rSwitch', 'OutputName', 'rSwitchOutputName');
                        
            rSwitchIOText = sprintf('%s;     %s;', rSwitchInputNames, rSwitchOutputNames);
            
            eSwitchText = sprintf('%s = AnalysisPoint(''%s'',%s);', 'eSwitch', 'e','nOutputF');
            eSwitchInputNames = sprintf('%s.%s = ''%s''', 'eSwitch', 'InputName', 'eSwitchInputName');
            eSwitchOutputNames = sprintf('%s.%s = ''%s''', 'eSwitch', 'OutputName', 'e');
                       
            eSwitchIOText = sprintf('%s;     %s;', eSwitchInputNames, eSwitchOutputNames);
            
            uSwitchText = sprintf('%s = AnalysisPoint(''%s'',%s);', 'uSwitch', 'u','nOutputC');
            uSwitchInputNames = sprintf('%s.%s = ''%s''', 'uSwitch', 'InputName', 'uSwitchInputName');
            uSwitchOutputNames = sprintf('%s.%s = ''%s''', 'uSwitch', 'OutputName', 'u');
                       
            uSwitchIOText = sprintf('%s;     %s;', uSwitchInputNames, uSwitchOutputNames);
            
            ySwitchText = sprintf('%s = AnalysisPoint(''%s'',%s);', 'ySwitch', 'y','nOutputF');
            ySwitchInputNames = sprintf('%s.%s = ''%s''', 'ySwitch', 'InputName', 'ySwitchInputName');
            ySwitchOutputNames = sprintf('%s.%s = ''%s''', 'ySwitch', 'OutputName', 'y');
                       
            ySwitchIOText = sprintf('%s;     %s;', ySwitchInputNames, ySwitchOutputNames);
                        
            ymSwitchText = sprintf('%s = AnalysisPoint(''%s'',%s);', 'ymSwitch', 'ym','nOutputH');
            ymSwitchInputNames = sprintf('%s.%s = ''%s''', 'ymSwitch', 'InputName', 'ymSwitchInputName');
            ymSwitchOutputNames = sprintf('%s.%s = ''%s''', 'ymSwitch', 'OutputName', 'ym');
                       
            ymSwitchIOText = sprintf('%s;     %s;', ymSwitchInputNames, ymSwitchOutputNames);

            Text = controllib.internal.codegen.appendMATLABCode(Text, rSwitchText, '', getString(message('Control:systunegui:CodegenConfig1APAt', 'r')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, rSwitchIOText);            
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, eSwitchText, '', getString(message('Control:systunegui:CodegenConfig1APAt', 'e')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, eSwitchIOText);
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, uSwitchText, '', getString(message('Control:systunegui:CodegenConfig1APAt', 'u')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, uSwitchIOText);
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, ySwitchText, '', getString(message('Control:systunegui:CodegenConfig1APAt', 'y')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, ySwitchIOText);               
            
            Text = controllib.internal.codegen.appendMATLABCode(Text, ymSwitchText, '', getString(message('Control:systunegui:CodegenConfig1APAt', 'ym')));
            Text = controllib.internal.codegen.appendMATLABCode(Text, ymSwitchIOText);
            
            %% Closed loop
            % Inputs
            Text = vertcat(Text,{''});
            Text = controllib.internal.codegen.appendMATLABCode(Text,...
                sprintf('%% %s', getString(message('Control:systunegui:CodegenConfig1CreateCL'))));
            InputList = '{''r'';''du'';''dy'';''n''}';
            Inputs = ['Inputs = ', InputList, ';'];
            Text = [Text; Inputs];
            % Outputs 
            OutputList = '{''y'';''e'';''u'';''ym''}';  
            Outputs = ['Outputs = ', OutputList, ';']; 
            Text = [Text; Outputs];
            
            % Closed loop
            ClosedLoopText = sprintf('%s = connect(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s);', ...
                                    SysName, 'C', 'F', 'G', 'H', ...
                                    'eSum', 'uSum', 'ySum', 'ymSum', ...
                                    'rSwitch' ,'eSwitch', 'uSwitch', 'ySwitch', 'ymSwitch', ...
                                    'Inputs', 'Outputs');
                                
          Text = controllib.internal.codegen.appendMATLABCode(Text, ClosedLoopText);
        end
        
    end
    methods %(Access = private)
        function validateConfigurationData_(this,C,F,G,H) %#ok<INUSL>
            % verify systems
            if ~(isa(C,'DynamicSystem') || isParametric(C))
                error(message('Control:systunegui:MLConfigDataErrorDynamicSystem','C'));
            end
            if ~(isa(F,'DynamicSystem') || isParametric(F))
                error(message('Control:systunegui:MLConfigDataErrorDynamicSystem','F'));
            end
            if ~isa(G,'DynamicSystem')
                error(message('Control:systunegui:MLConfigDataErrorDynamicSystem','G'));
            end
            if ~isa(H,'DynamicSystem')
                error(message('Control:systunegui:MLConfigDataErrorDynamicSystem','H'));
            end
            
            % verify at least one system is parametric block
            if ~(isa(C,'tunableBlock') || isa(C,'genss'))
                error(message('Control:systunegui:MLConfigDataErrorTunableBlock', 'C'));
            elseif ~(isa(F,'tunableBlock')|| isa(F,'genss'))
                error(message('Control:systunegui:MLConfigDataErrorTunableBlock', 'F'));
            end
            
            % error checking for dimensions
            [nOutputF,~] = iosize(F);
            [nOutputC,nInputC] = iosize(C);
            [nOutputG,nInputG] = iosize(G);
            [nOutputH,nInputH] = iosize(H);
            
            if nOutputF~=nInputC
                error(message('Control:systunegui:MLConfigDataErrorDimensionMismatch','C','F'));
            end
            if nOutputH~=nInputC
                error(message('Control:systunegui:MLConfigDataErrorDimensionMismatch','C','H'));
            end
            if nOutputC~=nInputG
                error(message('Control:systunegui:MLConfigDataErrorDimensionMismatch','C','G'));
            end
            if nOutputG~=nInputH
                error(message('Control:systunegui:MLConfigDataErrorDimensionMismatch','G','H'));
            end
            
            % check invalid Ts
            if ~(G.Ts>=0)
                error(message('Control:systunegui:MLConfigDataFeedbackErrorInvalidSampleTime','G'));
            end
            if ~(C.Ts>=0)
                error(message('Control:systunegui:MLConfigDataFeedbackErrorInvalidSampleTime','C'));
            end
            if ~(F.Ts>=0)
                error(message('Control:systunegui:MLConfigDataFeedbackErrorInvalidSampleTime','F'));
            end
            if ~(H.Ts>=0)
                error(message('Control:systunegui:MLConfigDataFeedbackErrorInvalidSampleTime','H'));
            end                        
        end
        function constructClosedLoop(this,C,F,G,H)
            % given C,F,G,H construct closed-loop genss
            [nOutputF,nInputF] = iosize(F);
            [nOutputC,~] = iosize(C);
            [nOutputG,~] = iosize(G);
            [nOutputH,~] = iosize(H);

            % systems
            F.InputName = 'rSwitchOutputName';  F.OutputName = 'rf';    F.Name = 'F';          
            C.InputName = 'e';  C.OutputName = 'uc';    C.Name = 'C';         
            G.InputName = 'u';  G.OutputName = 'yg';    G.Name = 'G';            
            H.InputName = 'y';  H.OutputName = 'yh';    H.Name = 'H';   
            
            % sum blocks
            eSum = sumblk('eSwitchInputName = -ym + rf',nOutputF);
            uSum = sumblk('uSwitchInputName = uc + du',nOutputC);
            ySum = sumblk('ySwitchInputName = yg + dy',nOutputG);
            ymSum = sumblk('ymSwitchInputName = yh + n',nOutputH); 
            
            % switches
            rSwitch = AnalysisPoint('r',nInputF); 
            rSwitch.InputName = 'r'; rSwitch.OutputName = 'rSwitchOutputName';
            eSwitch = AnalysisPoint('e',nOutputF); 
            eSwitch.InputName = 'eSwitchInputName'; eSwitch.OutputName = 'e';
            uSwitch = AnalysisPoint('u',nOutputC);
            uSwitch.InputName = 'uSwitchInputName'; uSwitch.OutputName = 'u';
            ySwitch = AnalysisPoint('y',nOutputF); 
            ySwitch.InputName = 'ySwitchInputName'; ySwitch.OutputName = 'y';
            ymSwitch = AnalysisPoint('ym',nOutputH);
            ymSwitch.InputName = 'ymSwitchInputName'; ymSwitch.OutputName = 'ym';            

            Inputs = {'r';'du';'dy';'n'};
            Outputs = {'y';'e';'u';'ym'};  
            
            this.ClosedLoop = connect(C,F,G,H, ...
                                 eSum,uSum,ySum,ymSum, ...
                                 rSwitch,eSwitch,uSwitch,ySwitch,ymSwitch, ...
                                 Inputs,Outputs);                                                           
        end
    end
    
    methods(Hidden = true)
        function Text = localGenerateMATLABCodeRealp(~, ARealp)
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

end
