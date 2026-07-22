classdef Config1Architecture < ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture
    % Config 1 for Control System Designer
    %                                   du            dy
    %                 rf    e        uc | u        yg |
    %      r -->[ F ]---->O--->[ C ]----O--->[ G ]----O---> y
    %                     |                             |
    %                (-1) +-----O<----[ H ]<------------+
    %                       ym  |  yh
    %                           n
    %
    %   Negative feedback is assumed.

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (Access = protected)
        % Fixed Blocks
        G
        H
        % Tunable Blocks
        C
        F
    end
    
    %% Implementation of Abstract Methods
    methods (Access = public)
        function Config = getConfiguration(this)
            % Returns Configuration number
            Config = 1;
        end
        
        function CopiedArch = copyArch(this)
            %             CopiedArch = copy(this);
            G = getValue(this.G);
            H = getValue(this.H);
            CopiedArch = ctrlguis.csdesignerapp.data.architectures.internal.Config1Architecture(ss(1),ss(1),G,H);
            loadSession(CopiedArch,saveSession(this));
        end
     end
    
    methods (Access = protected)
        function computeClosedLoop(this)
            % given C,F,G,H construct closed-loop genss
            C = ltiblock.gain('C',1);
            F = ltiblock.gain('F',1);
            G = getValue(this.G);
            H = getValue(this.H);
            
            % systems
            F.InputName = 'r';  F.OutputName = 'rf';    F.Name = 'F';
            C.InputName = 'e';  C.OutputName = 'uc';    C.Name = 'C';
            G.InputName = 'u';  G.OutputName = 'yg';    G.Name = 'G';
            H.InputName = 'y';  H.OutputName = 'yh';    H.Name = 'H';
            
            se = AnalysisPoint('e');
            suC = AnalysisPoint('uC');
            su = AnalysisPoint('u');
            sy = AnalysisPoint('ym');
            
            s = 1;
            L = this.LoopSign;
            if isempty(L)
                L = -1;
            end
            IC = ...
                ...%'rf; rC; r; du; dy;  n;  yg; yh; eout ucout uout ymout
                [0	0	s	0	0	0	0	0   0    0    0    0     %Fin    % Fin = r
                0	0	0	0	0   0	0   0   s    0    0    0     %Cin    % Cin = eout
                0	0	0	0	s	0	s	0   0    0    0    0     %y      % y = dy+yg
                0	0	0	0	0	0	0	0   0    0    s    0     %Gin    % Gin = uout
                0	0	0	0	s	0	s	0   0    0    0    0     %Hin    % Hin = dy+yg
                s	0	0	0	0   0	0   0   0    0    0  L*s     %ein    % ein = rf-ymout
                0	s	0	0	0   0	0   0   0    0    0    0     %ucin   % ucin = uc
                0	0	0	s	0   0	0   0   0    s    0    0     %uin    % uin = du+ucout
                0	0	0	0	0   s	0   s   0    0    0    0];   %ymin   % ymin = n+yh
            
            IC = IC*ss(1);
            
            IC.InputName = {'rf';'rC';'r';'du';'dy';'n';'yg';'yh';'e';'uc';'u';'ym'};
            IC.OutputName = {'Fin';'Cin';'y';'Gin';'Hin';'e';'uc';'u';'ym'};
            
            
            Plant = blkdiag(G,H,se,suC,su,sy);
            
            this.LFT.IC = lft(IC,Plant);
            
            this.LFT.Blocks = blkdiag(F,C);
            
            this.System = lft(this.LFT.Blocks,this.LFT.IC);
            
            % Compute Adjacency matrix to see which compensators are in series
            % The adjacency matrix is different from the inter-connections
            % in the following ways:
            %   1. The AM has to be numeric - D matrix
            %   2. The AM is not affected by external inputs or outputs
            %   3. The AM requires additional nodes for sum blocks.
            %   4. The AM matrix is defined from output to input, and hence
            %   is the transpose of the IC matrix.
            
            AM = ...
                ...  %F     C     r     Se    Su   du     G    SyG    y     dy    H    SyM     n
                [ 0     0     1     0     0     0     0     0     0     0     0     0     0   % F
                0     0     0     1     0     0     0     0     0     0     0     0     0   % C
                0     0     0     0     0     0     0     0     0     0     0     0     0   % r
                1     0     0     0     0     0     0     0     0     0     0     1     0   % Se
                0     1     0     0     0     1     0     0     0     0     0     0     0   % SuC
                0     0     0     0     0     0     0     0     0     0     0     0     0   % du
                0     0     0     0     1     0     0     0     0     0     0     0     0   % G
                0     0     0     0     0     0     1     0     0     1     0     0     0   % SyG
                0     0     0     0     0     0     0     1     0     0     0     0     0   % y
                0     0     0     0     0     0     0     0     0     0     0     0     0   % dy
                0     0     0     0     0     0     0     0     1     0     0     0     0   % H
                0     0     0     0     0     0     0     0     0     0     1     0     1   % sYm
                0     0     0     0     0     0     0     0     0     0     0     0     0]; % n
            
            
            this.ConfigurationGraph = struct('AdjacencyMatrix',AM,...
                'TunableBlocks', [1,2], ...
                'ExternalInputs', [3:6],...
                'ExternalOutputs', 3,...
                'Locations',  ...
                struct('r',3,...
                'du',6,...
                'dy',10,...
                'n',13,...
                'y',9,...
                'e',4,...
                'uC',2,...
                'u',5,...
                'ym',12,...
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
            
            % Add Blocks - for Configuration 1
            CompBlock = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
            set_param(CompBlock,'MaskValueString',[this.C.Name,'|[]|0']);
            InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
            OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
            SumBlock = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum']);
            PlantBlock = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
            set_param(PlantBlock,'MaskValueString',[this.G.Name,'|[]|0']);
            SensorBlock = add_block('cstblocks/LTI System',[DiagramName,'/Sensor Dynamics']);
            set_param(SensorBlock,'MaskValueString',[this.H.Name,'|[]|0']);
            FilterBlock = add_block('cstblocks/LTI System',[DiagramName,'/Feed Forward']);
            set_param(FilterBlock,'MaskValueString',[this.F.Name,'|[]|0']);
            
            %---Close CSTBLOCKS, if it wasn't open before
            if isempty(BlockOpenFlag),
                close_system('cstblocks')
            end
            
            % Assign loop sign
            if (this.getLoopSign>0)
                SumStr='++';
            else
                SumStr='+-';
            end
            set_param(SumBlock,'Inputs',SumStr)
            
            % Model Layout and block positions
            set_param(NewDiagram,'Location',[70, 200, 560, 420])
            set_param(SensorBlock,'Orientation','left');
            
            open_system(NewDiagram)
            
            set_param(SumBlock,'Position',[165, 42, 195, 73])
            set_param(OutBlock,'Position',[440, 45, 465, 75])
            set_param(InBlock,'Position',[15, 35, 45, 65])
            set_param(PlantBlock,'Position',[315, 42, 380, 78])
            set_param(SensorBlock,'Position',[285, 112, 350, 148])
            set_param(CompBlock,'Position',[220, 42, 285, 78])
            set_param(FilterBlock,'Position',[65, 32, 130, 68])
            LinePos=[{[50 50; 60 50]};
                {[135 50; 160 50]};
                {[280 130; 150 130; 150 65; 160 65]};
                {[200 60;215 60]};
                {[290 60;310 60]};
                {[385 60;435 60]};
                {[400 60; 400 130;355 130]}];
            
            % Connect blocks
            for ctLine = 1:length(LinePos)
                add_line(NewDiagram,LinePos{ctLine});
            end
            
            % Set Signal Names at  Outports
            % InBlock - 'r', CompBlock - 'uc', PlantBlock - 'y' 
            set(get(getfield(get(InBlock,'PortHandles'),'Outport'),'Line'),'Name','r');
            set(get(getfield(get(CompBlock,'PortHandles'),'Outport'),'Line'),'Name','u');
            set(get(getfield(get(PlantBlock,'PortHandles'),'Outport'),'Line'),'Name','y');
                        
            % Open Simulink model
            open_system(NewDiagram);
        end
    end
    
    
    %% Public Methods
    methods (Access = public)
        
        function this = Config1Architecture(C,F,G,H)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture;
            this.C =  createTunableBlock(this,'C',C);
            this.F =  createTunableBlock(this,'F',F);
            
            this.G = createFixedBlock(this, 'G', G);
            this.H = createFixedBlock(this, 'H', H);
            
            setData(this,C,F,G,H)
            this.TunedBlocks = [this.F; this.C];
            this.FixedBlocks = [this.G; this.H];
            this.Name = 'Feedback Configuration 1';
            
            % {ID SignalName}
            %             this.SignalsWithID = repmat(getAvailableSignals(this),1,2);
            
            this.LoopSign = -1;
            validateFixedBlocks(this);
            validateSampleTime(this);
            computeClosedLoop(this);
        end
        
        function loc = getLocationForBlock(~, Blk)
            BlkName = Blk;
            switch BlkName
                case 'C'
                    loc = 'uC';
                case 'F'
                    loc = 'Fout';
            end
        end
        
        function Blocks = getBlocks(this)
            Blocks = {this.C; this.F; this.G; this.H};
        end
        
        function setData(this,C,F,G,H)
            setValue(this.C,C);
            setValue(this.F,F);
            setValue(this.G, G);
            setValue(this.H, H);
            this.isDirty = true;
        end
        
        function Icon = getArchitectureIcon(this)
            Icon = ctrlguis.csdesignerapp.Icon.CONFIGURATION_1;
        end
        
        function ID = getLoopID(this)
            ID = {getString(message('Control:designerapp:strLoopSignIdentifierAtLocation','ym'))};
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
                this.isDirty = true;
            catch ME
                error(ME.message);
            end
        end
    end
    
    
end