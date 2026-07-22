classdef Config4Architecture < ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture
    % Config 1 for Control System Designer
    %                                    du             dy
    %                       e        uc1 | u         yg |
    %               r---->O--->[ C1 ]----O--->[ G ]-----O---> y
    %                (-1) |          (-1)|uc2           |
    %                     |           [ C2 ]            |
    %                     |              |              |
    %                     +--------------+---O<--[ H ]--+
    %                                    ym  |  yh
    %                                        n
    %
    %   Negative feedback is assumed.

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (Access = protected)
        % Fixed Blocks
        G
        H
        % Tunable Blocks
        C1
        C2
    end
    
    %% Implementation of Abstract Methods
    methods (Access = public)
        function Config = getConfiguration(this)
            % Returns Configuration number
            Config = 4;
        end
        
        function CopiedArch = copyArch(this)
            G = getValue(this.G);
            H = getValue(this.H);
            CopiedArch = ctrlguis.csdesignerapp.data.architectures.internal.Config4Architecture(ss(1),ss(1),G,H);
            loadSession(CopiedArch,saveSession(this));
        end
    end
    
    methods (Access = protected)
        function computeClosedLoop(this)
            % given C,F,G,H construct closed-loop genss
            C1 = ltiblock.gain('C1',1);
            C2 = ltiblock.gain('C2',1);
            G = getValue(this.G);
            H = getValue(this.H);
            
            % systems
            C1.InputName = 'e';   C1.OutputName = 'uc1';    C1.Name = 'C1';
            C2.InputName = 'ym';  C2.OutputName = 'uc2';    C2.Name = 'C2';
            G.InputName = 'u';    G.OutputName = 'yg';      G.Name = 'G';
            H.InputName = 'y';    H.OutputName = 'yh';      H.Name = 'H';
            
            se = AnalysisPoint('e');
            su = AnalysisPoint('u');
            su1 = AnalysisPoint('uC1');
            su2 = AnalysisPoint('uC2');
            sy = AnalysisPoint('ym');
            
            s = 1;
            
            L = this.LoopSign;
            if isempty(this.LoopSign)
                L = [-1;-1];
            end
            
            IC = ...
                ...%'Co1; Co2; r; du; dy;  n; yg; yh;  e; uc1; uc2; u; ym
                [0	0	0	0	0	0	0	0   s   0    0     0   0;      %Cin1 = e
                0	0	0	0	0   0	0   0   0   0    0     0   s;      %Cin2 = ym
                0	0	0	0	s	0	s	0   0   0    0     0   0;      %y = dy+yg
                0	0	0	0	0	0	0	0   0   0    0     s   0;      %Gin=u
                0	0	0	0	s	0	s	0   0   0    0     0   0;      %Hin=dy+yg
                0	0	s	0	0   0	0   0   0   0    0     0 L(1)*s;   %e=r-ym
                s	0	0	0	0   0	0   0   0   0    0     0   0;      %uc1=Co1
                0	s	0	0	0   0	0   0   0   0    0     0   0;      %uc2=Co2
                0	0	0	s	0   0	0   0   0   s  L(2)*s  0   0;      %u=du+uc1+uc2
                0	0	0	0	0   s	0   s   0   0    0     0   0];     %ym=n+yh
            
            IC = IC*ss(1);
            IC.InputName = {'Co1';'Co2';'r';'du';'dy';'n';'yg';'yh';'e';'uc1';'uc2';'u';'ym'};
            IC.OutputName = {'Cin1';'Cin2';'y';'Gin';'Hin';'e';'uc1';'uc2';'u';'ym'};
            
            
            Plant = blkdiag(G,H,se,su1,su2,su,sy);
            
            this.LFT.IC = lft(IC,Plant);
            
            this.LFT.Blocks = blkdiag(C1,C2);
            
            this.System = lft(this.LFT.Blocks,this.LFT.IC);
            
            % Compute Adjacency matrix to see which compensators are in series
            % The adjacency matrix is different from the inter-connections
            % in the following ways:
            %   1. The AM has to be numeric
            %   2. The AM is not affected by external inputs or outputs
            %   3. The AM requires additional nodes for sum blocks.
            %   4. The AM matrix is defined from output to input, and hence
            %   is the transpose of the IC matrix.
            AM = ...
                ...% C1    C2    r     S1    Su    du    G     Sy    dy    y     H     Sn    n
                [0     0     0     1     0     0     0     0     0     0     0     0     0      % C1
                0     0     0     0     0     0     0     0     0     0     0     1     0      % C2
                0     0     0     0     0     0     0     0     0     0     0     0     0      % r
                0     0     1     0     0     0     0     0     0     0     0     1     0      % S1
                1     1     0     0     0     1     0     0     0     0     0     0     0      % Su
                0     0     0     0     0     0     0     0     0     0     0     0     0      % du
                0     0     0     0     1     0     0     0     0     0     0     0     0      % G
                0     0     0     0     0     0     1     0     1     0     0     0     0      % Sy
                0     0     0     0     0     0     0     0     0     0     0     0     0      % dy
                0     0     0     0     0     0     0     1     0     0     0     0     0      % Y
                0     0     0     0     0     0     0     0     0     1     0     0     0      % H
                0     0     0     0     0     0     0     0     0     0     1     0     1      % Sn
                0     0     0     0     0     0     0     0     0     0     0     0     0];    % n
            
            
            
            this.ConfigurationGraph = struct('AdjacencyMatrix',AM,...
                'TunableBlocks', [1,2], ...
                'ExternalInputs',3:6,...
                'ExternalOutputs',3,...
                'Locations', ...
                struct('r',3,...
                'du',6,...
                'dy',9,...
                'n',13,...
                'y',10,...
                'e',4,...
                'u',5,...
                'uC1',1,...
                'uC2',2,...
                'ym',12));
        end
        
        function drawDiagram_(this,NewDiagram,DiagramName)
                        %---Open CSTBLOCKS, if not already open
            % @todo update the usage of edit-time filter filterOutInactiveVariantSubsystemChoices()
            % instead use the post-compile filter activeVariants() - g2603738
            BlockOpenFlag = find_system('MatchFilter',@Simulink.match.internal.filterOutInactiveVariantSubsystemChoices,  'Name','cstblocks' ); % look only inside active choice of VSS
            if isempty(BlockOpenFlag)
                load_system('cstblocks');
            end
            
            % Add Blocks - for Configuration 4
            CompBlock = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
            set_param(CompBlock,'MaskValueString',[this.C1.Name,'|[]|0']);
            InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
            OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
            SumBlock = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum']);
            PlantBlock = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
            set_param(PlantBlock,'MaskValueString',[this.G.Name,'|[]|0']);
            SensorBlock = add_block('cstblocks/LTI System',[DiagramName,'/Sensor Dynamics']);
            set_param(SensorBlock,'MaskValueString',[this.H.Name,'|[]|0']);
            CompBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Feed Forward']);
            set_param(CompBlock2,'MaskValueString',[this.C2.Name,'|[]|0']);
            
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
            set_param(NewDiagram,'Location',[70, 200, 560, 420])
            set_param(SensorBlock,'Orientation','left');
            
            open_system(NewDiagram)
            
            set_param(SumBlock,'Position',[80 37 110 68])
            set_param(OutBlock,'Position',[450 50 475 80])
            set_param(InBlock,'Position',[15 30 45 60])
            set_param(PlantBlock,'Position',[315 47 380 83])
            set_param(SensorBlock,'Position',[310 147 375 183])
            set_param(CompBlock,'Position',[135 37 200 73])
            set_param(CompBlock2,'Position',[187 105 253 145],'Orientation','up')
            if loopSign(2)>0,
                SumStr2='++';
            else
                SumStr2='+-';
            end
            SumBlock2 = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum2'],...
                'Position',[245 47 275 78],'Inputs',SumStr2);
            LinePos={[220 100;220 70;240 70];...
                [385 65;385 65;420 65;420 165;380 165];...
                [420 65;445 65];...
                [205 55;240 55];...
                [50 45;75 45];...
                [305 165;305 165;220 165;65 165;65 60;75 60];...
                [220 165;220 150];...
                [115 55;130 55];...
                [280 65;310 65]};
            
            % Connect blocks
            for ctLine = 1:length(LinePos)
                add_line(NewDiagram,LinePos{ctLine});
            end
            
            % Set Signal Names at  Outports
            % InBlock - 'r', SensorBlock - 'ym', CompBlock - 'uC1', CompBlock2 - 'uC2'
            % SumBlock2 - 'u', PlantBlock - 'y'
            set(get(getfield(get(InBlock,'PortHandles'),'Outport'),'Line'),'Name','r');
            set(get(getfield(get(SensorBlock,'PortHandles'),'Outport'),'Line'),'Name','ym');
            set(get(getfield(get(SumBlock2,'PortHandles'),'Outport'),'Line'),'Name','u');
            set(get(getfield(get(PlantBlock,'PortHandles'),'Outport'),'Line'),'Name','y');
            set(get(getfield(get(CompBlock,'PortHandles'),'Outport'),'Line'),'Name','uC1');
            set(get(getfield(get(CompBlock2,'PortHandles'),'Outport'),'Line'),'Name','uC2');
            % Open Simulink model
            open_system(NewDiagram);
        end
    end
    
    
    %% Public Methods
    methods (Access = public)
        
        function this = Config4Architecture(C1,C2,G,H)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture;
            this.C1 =  createTunableBlock(this,'C1',C1);
            this.C2 =  createTunableBlock(this,'C2',C2);
            
            this.G = createFixedBlock(this, 'G', G);
            this.H = createFixedBlock(this, 'H', H);
            
            setData(this,C1,C2,G,H)
            this.TunedBlocks = [this.C1; this.C2];
            this.FixedBlocks = [this.G; this.H];
            this.Name = 'Feedback Configuration 4';
            
            % {ID SignalName}
            %             this.SignalsWithID = repmat(getAvailableSignals(this),1,2);
            
            this.LoopSign = [-1;-1];
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
            end
        end
        
        function Blocks = getBlocks(this)
            Blocks = {this.C1; this.C2; this.G; this.H};
        end
        
        function setData(this,C1,C2,G,H)
            setValue(this.C1,C1);
            setValue(this.C2,C2);
            setValue(this.G, G);
            setValue(this.H, H);
            this.isDirty = true;
        end
        
        function Icon = getArchitectureIcon(this)
            Icon = ctrlguis.csdesignerapp.Icon.CONFIGURATION_4;
        end
        
        function ID = getLoopID(this)
            msgID = 'Control:designerapp:strLoopSignIdentifierAtLocation';
            ID = {getString(message(msgID,'ym'));...
                  getString(message(msgID,'uC2'))};
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