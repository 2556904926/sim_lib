classdef Config6Architecture < ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture
    % Config 6 for Control System Designer
    %                                        du1            du2        dy
    %  r1     rf   e1      uc1   e2       uc2 | u1        y2|u2         |
    % -->[ F ]-->O---[ C1 ]--->O--->[ C2 ]--->O--->[ G1 ]-->O--[ G2 ]-->O--->y1
    %      (-1)  |         (-1)|                         |                |
    %            |             +-----O<----[ H1 ]<-------+                |
    %            |               ym1 | yh1                                |
    %            |                  n1                                    |
    %            +----------------------------------O<----[ H2 ]<---------+
    %                                           ym2 | yh2
    %                                               n2
    %   Negative feedback is assumed.

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (Access = private)
        % Fixed Blocks
        G1
        G2
        H1
        H2
        % Tunable Blocks
        C1
        C2
        F
    end
    
    %% Implementation of Abstract Methods
    methods (Access = public)
        function Config = getConfiguration(this)
            % Returns Configuration number
            Config = 6;
        end
        
        function CopiedArch = copyArch(this)
            G1 = getValue(this.G1);
            G2 = getValue(this.G2);
            H1 = getValue(this.H1);
            H2 = getValue(this.H2);
            CopiedArch = ctrlguis.csdesignerapp.data.architectures.internal.Config6Architecture(ss(1),ss(1),ss(1),G1,G2,H1,H2);
            loadSession(CopiedArch,saveSession(this));
        end
        
        function CL = getDefaultClosedLoops(this)
            CL(1).Input = 'r1';
            CL(1).Output = 'y1';
            CL(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','r','y')); % r to y
        end
    end
    
    methods (Access = protected)
        function computeClosedLoop(this)
            % given C,F,G,H construct closed-loop genss
            
            C1 = ltiblock.gain('C1',1);
            C2 = ltiblock.gain('C2',1);
            F =  ltiblock.gain('F',1);
            G1 = getValue(this.G1);
            G2 = getValue(this.G2);
            H1 = getValue(this.H1);
            H2 = getValue(this.H2);
            
            % systems
            F.InputName = 'r1';     F.OutputName = 'rf';      F.Name = 'F';
            C1.InputName = 'e1';   C1.OutputName = 'uc1';    C1.Name = 'C1';
            C2.InputName = 'e2';   C2.OutputName = 'uc2';    C2.Name = 'C2';
            G1.InputName = 'u1';   G1.OutputName = 'y2';     G1.Name = 'G1';
            G2.InputName = 'u2';   G2.OutputName = 'yg2';    G2.Name = 'G2';
            H1.InputName = 'yg1';  H1.OutputName = 'yh1';    H1.Name = 'H1';
            H2.InputName = 'y1';   H2.OutputName = 'yh2';    H2.Name = 'H2';
            
            se1 = AnalysisPoint('e1');
            se2 = AnalysisPoint('e2');
            su1 = AnalysisPoint('uC1');
            su2 = AnalysisPoint('uC2');
            sy1 = AnalysisPoint('ym1');
            sy2 = AnalysisPoint('ym2');
            sy = AnalysisPoint('y2');
            s = 1;
            
            L = this.LoopSign;
            if isempty(L)
                L = [-1;-1];
            end
            IC = ...
                ...% rf;    uc1;  uc2;  r1;   du1;  du2;  dy;   n1;  n2;   yg1; yh1;  yg2;  yh2;  se1;  se2;  su1;  su2;  sy1;  sy2   sy
                [ 0     0     0     s     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0   0   % Fin = r
                0     0     0     0     0     0     0     0     0     0     0     0     0     s     0     0     0     0     0   0   % C1in = e1
                0     0     0     0     0     0     0     0     0     0     0     0     0     0     s     0     0     0     0   0   % C2in = r2
                0     0     0     0     0     0     s     0     0     0     0     s     0     0     0     0     0     0     0   0   % y = yg2+dy
                0     0     0     0     s     0     0     0     0     0     0     0     0     0     0     0     s     0     0   0   % G1in = su2+du1
                0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0   s   % H1in = sy
                0     0     0     0     0     s     0     0     0     0     0     0     0     0     0     0     0     0     0   s   % G2in = sy+du2
                0     0     0     0     0     0     s     0     0     0     0     s     0     0     0     0     0     0     0   0   % H2in = yg2+dy
                s     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0 L(1)*s  0   % e1in = rf+ym2
                0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     s     0    L(2)*s 0   0   % e2in = su1+ym1
                0     s     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0   0   % su1in = uc1
                0     0     s     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0     0   0   % su2in = uc2
                0     0     0     0     0     0     0     s     0     0     s     0     0     0     0     0     0     0     0   0   % sy1 = n1+yh1
                0     0     0     0     0     0     0     0     s     0     0     0     s     0     0     0     0     0     0   0   % sy2 = n2+yh2
                0     0     0     0     0     0     0     0     0     s     0     0     0     0     0     0     0     0     0   0]; % sy = yg1                                                                                                               % sy = G1Out
            
            IC = IC*ss(1);
            IC.InputName = {'rf';'uc1';'uc2';'r1';'du1';'du2';'dy';'n1';'n2';'y2';'yh1';'yg2';'yh2';'se1';'se2';'su1';'su2';'sy1';'sy2';'sy'};
            IC.OutputName = {'Fin';'C1in';'C2in';'y1';'G1in';'H1in';'G2in';'H2in';'e1';'e2';'uC1';'uC2';'ym1';'ym2';'sy'};
            
            
            Plant = blkdiag(G1,H1,G2,H2,se1,se2,su1,su2,sy1,sy2,sy);
            
            this.LFT.IC = lft(IC,Plant);
            
            this.LFT.Blocks = blkdiag(F,C1,C2);
            
            this.System = lft(this.LFT.Blocks,this.LFT.IC);
            
            % Compute Adjacency matrix to see which compensators are in series
            % The adjacency matrix is different from the inter-connections
            % in the following ways:
            %   1. The AM has to be numeric
            %   2. The AM is not affected by external inputs or outputs
            %   3. The AM requires additional nodes for sum blocks.
            %   4. The AM matrix is defined from output to input, and hence
            %   is the transpose of the IC matrix.
            
            AM = zeros(21,21);
            AM(1,4) = 1;            % 1. F - r
            AM(2,5) = 1;            % 2. C1 - S1
            AM(3,6) = 1;            % 3. C2 - S2
            AM(4,:) = 0;            % 4. r is fed by nothing
            AM(5,[1 20]) = 1;       % 5. S1 - F + Sn2
            AM(6,[2 11]) = 1;       % 6. S2 - C1 + Sn1
            AM(7,[3 8]) = 1;        % 7. Su1- C2 + du1
            AM(8,:) = 0;            % 8. du1- 0
            AM(9,7) = 1;            % 9. G1 - Su1
            AM(10,9) = 1;           % 10.H1 - G1
            AM(11,[10 12]) = 1;     % 11.Sn1-H1+n1
            AM(12,:) = 0;           % 12.n1-0
            AM(13,[9 14]) = 1;      % 13.Su2-G1+du2
            AM(14,:) = 0;           % 14.du2-0
            AM(15,13) = 1;          % 15.G2-su2
            AM(16,[15 17]) = 1;     % 16.Sy-G2+dy
            AM(17,:) = 0;           % 17.dy-0
            AM(18,16) = 1;          % 18.y-sy
            AM(19,18) = 1;          % 19.H2-y
            AM(20,[19 21]) = 1;     % 20.Sn2-H2+n2
            AM(21,:) = 0;           % 21.n2-0
            
            this.ConfigurationGraph = struct('AdjacencyMatrix',AM,...
                'TunableBlocks', [1,2,3], ...
                'ExternalInputs',4:9,...
                'ExternalOutputs',4,...
                'Locations',  ...
                struct('r1',4,...
                'du1',8,...
                'du2',14,...
                'dy',17,...
                'n1',12,...
                'n2',21,...
                'y1',18,...
                'e1',5,...
                'e2',6,...
                'uC1',2,...
                'uC2',3,...
                'ym1',11,...
                'ym2',20,...
                'y2',10,...
                'Fout',1));
        end
        
        function drawDiagram_(this,NewDiagram,DiagramName)
                        %---Open CSTBLOCKS, if not already open
	    % @todo update the usage of edit-time filter filterOutInactiveVariantSubsystemChoices()
	    % instead use the post-compile filter activeVariants() - g2603738
            BlockOpenFlag = find_system('MatchFilter',@Simulink.match.internal.filterOutInactiveVariantSubsystemChoices,  'Name','cstblocks' ); % look only inside active choice of VSS
            if isempty(BlockOpenFlag)
                load_system('cstblocks');
            end
            
            % Add Blocks - for Configuration 6
            CompBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
            set_param(CompBlock1,'MaskValueString',[this.C1.Name,'|[]|0']);
            CompBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Compensator2']);
            set_param(CompBlock2,'MaskValueString',[this.C2.Name,'|[]|0']);
            FilterBlock= add_block('cstblocks/LTI System',[DiagramName,'/Prefilter']);
            set_param(FilterBlock,'MaskValueString',[this.F.Name,'|[]|0']);
            InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
            OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
            SumBlock = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum']);
            PlantBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
            set_param(PlantBlock1,'MaskValueString',[this.G1.Name,'|[]|0']);
            PlantBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Plant2']);
            set_param(PlantBlock2,'MaskValueString',[this.G2.Name,'|[]|0']);
            SensorBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Sensor1']);
            set_param(SensorBlock1,'MaskValueString',[this.H1.Name,'|[]|0']);
            SensorBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Sensor2']);
            set_param(SensorBlock2,'MaskValueString',[this.H2.Name,'|[]|0']);
            %---Close CSTBLOCKS, if it wasn't open before
            if isempty(BlockOpenFlag),
                close_system('cstblocks')
            end
            
            % Assign loop sign
            loopSign = this.getLoopSign;
            if (loopSign(1)>0)
                SumStr='++';
            else
                SumStr='+-';
            end
            set_param(SumBlock,'Inputs',SumStr)
            
            % Model Layout and block positions
            open_system(NewDiagram)
            
            set_param(InBlock,'Position',[80 200 110 230]);
            set_param(FilterBlock,'Position',[140 197 200 233]);
            set_param(SumBlock,'Position',[245 207 295 243]);
            set_param(CompBlock1,'Position',[340 207 400 243]);
            set_param(CompBlock2,'Position',[520 217 580 253]);
            set_param(PlantBlock1,'Position',[620 217 680 253]);
            set_param(PlantBlock2,'Position',[750 217 810 253]);
            set_param(SensorBlock1,'Position',[565 307 625 343],'Orientation','left');
            set_param(SensorBlock2,'Position',[755 397 815 433],'Orientation','left');
            set_param(OutBlock,'Position',[920 219 950 251]);
            if loopSign(2)>0,
                SumStr2='++';
            else
                SumStr2='+-';
            end
            SumBlock2 = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum2'],'Position',[430 217 480 253],'Inputs',SumStr2);
            LinePos = {[115 215;135 215];[205 215;240 215];[750 415;205 415;205 235;240 235];[685 235;710 235];[815 235;855 235];...
                [300 225;335 225];[405 225;425 225];[560 325;405 325;405 245;425 245];...
                [485 235;515 235];[585 235;615 235];[710 235;745 235];[855 235;915 235];...
                [710 235;710 325;630 325];[855 235;855 415;820 415]};
            
            % Connect blocks
            for ctLine = 1:length(LinePos)
                add_line(NewDiagram,LinePos{ctLine});
            end
            
            % Set Signal Names at  Outports
            % InBlock - 'r1', CompBlock1 - 'uC1', CompBlock2 - 'uC2'
            % PlantBlock1 - 'y2', PlantBlock2 - 'y1'
            % SensorBlock1 - 'ym1', SensorBlock2 - 'ym2'
            set(get(getfield(get(InBlock,'PortHandles'),'Outport'),'Line'),'Name','r1');
            set(get(getfield(get(CompBlock1,'PortHandles'),'Outport'),'Line'),'Name','uC1');
            set(get(getfield(get(CompBlock2,'PortHandles'),'Outport'),'Line'),'Name','uC2');
            set(get(getfield(get(PlantBlock1,'PortHandles'),'Outport'),'Line'),'Name','y2');
            set(get(getfield(get(PlantBlock2,'PortHandles'),'Outport'),'Line'),'Name','y1');
            set(get(getfield(get(SensorBlock1,'PortHandles'),'Outport'),'Line'),'Name','ym1');
            set(get(getfield(get(SensorBlock2,'PortHandles'),'Outport'),'Line'),'Name','ym2');
            
            % Open Simulink model
            open_system(NewDiagram);
        end
    end
    
    
    %% Public Methods
    methods (Access = public)
        
        function this = Config6Architecture(C1,C2,F,G1,G2,H1,H2)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture;
            import ctrlguis.csdesignerapp.data.architectures.internal.TunableBlock;
            
            this.C1 =  createTunableBlock(this,'C1',C1);
            this.C2 =  createTunableBlock(this,'C2',C2);
            this.F =  createTunableBlock(this,'F',F);
            
            this.G1 = createFixedBlock(this, 'G1', G1);
            this.G2 = createFixedBlock(this, 'G2', G2);
            this.H1 = createFixedBlock(this, 'H1', H1);
            this.H2 = createFixedBlock(this, 'H2', H2);
            this.LoopSign = [-1; -1];
            setData(this,C1,C2,F,G1,G2,H1,H2)
            this.TunedBlocks = [ this.F; this.C1; this.C2];
            this.FixedBlocks = [this.G1; this.H1; this.G2; this.H2];
            this.Name = 'Feedback Configuration 6';
            
            % {ID SignalName}
            %             this.SignalsWithID = repmat(getAvailableSignals(this),1,2);
            validateFixedBlocks(this);
            validateSampleTime(this);
            computeClosedLoop(this);
        end
        
        function loc = getLocationForBlock(~, Blk)
            BlkName = Blk;
            switch BlkName
                case 'C1'
                    loc = 'uC1';
                case 'C2'
                    loc = 'uC2';
                case 'F'
                    loc = 'Fout';
            end
        end
        
        function Blocks = getBlocks(this)
            Blocks = {this.C1; this.C2; this.F; this.G1; this.G2; this.H1; this.H2};
        end
        
        function setData(this,C1,C2,F,G1,G2,H1,H2)
            setValue(this.C1,C1);
            setValue(this.C2,C2);
            setValue(this.F,F);
            setValue(this.G1, G1);
            setValue(this.G2, G2);
            setValue(this.H1, H1);
            setValue(this.H2, H2);
            cthis.isDirty = true;
        end
        
        function Icon = getArchitectureIcon(this)
            Icon = ctrlguis.csdesignerapp.Icon.CONFIGURATION_6;
        end
        
        function ID = getLoopID(this)
            msgID = 'Control:designerapp:strLoopSignIdentifierAtLocation';
            ID = {getString(message(msgID,'ym1'));...
                  getString(message(msgID,'ym2'))};
        end
        
        function setBlockName(this, BlockID, BlockName)
            try
                this.(BlockID).Name = BlockName;
            catch
                error(message('Controllib:general:UnexpectedError', ...
                    'Invalid Block Name or Identifier'));
            end
        end
        
        function setBlockValue(this, BlockName, BlockValue)
            try
                setValue(this.(BlockName), BlockValue);
                % REVISIT: Does not apply to simulink and genss
                this.isDirty = true;
            catch ME
                error(ME.message);
            end
        end
    end
end
