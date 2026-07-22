classdef Config5Architecture < ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture
    % Config 5 for Control System Designer
    %
    %                                   du            dy-->[ Gd ]
    %                 rf    e        uc | u          yg1    |
    %      r -->[ F ]---->O--->[ C ]--->O--->[ G1 ]-------->O---> y
    %                 (-1)|ym        |                       |
    %                     |          |   u2        yg2       |
    %                     |          |------>[ G2 ]--->O<----|
    %                     |                        (-1)|
    %                     |----------------------------|
    %
    %   Negative feedback is assumed.

    % Copyright 2014-2021 The MathWorks, Inc.
    
    properties (Access = protected)
        % Fixed Blocks
        G1
        G2
        Gd
        % Tunable Blocks
        C
        F
    end
    
    %% Implementation of Abstract Methods
    methods (Access = public)
        function Config = getConfiguration(this)
            % Returns Configuration number
            Config = 5;
        end
        
        function CopiedArch = copyArch(this)
            G1 = getValue(this.G1);
            G2 = getValue(this.G2);
            Gd = getValue(this.Gd);
            CopiedArch = ctrlguis.csdesignerapp.data.architectures.internal.Config5Architecture(ss(1),ss(1),G1,G2,Gd);
            loadSession(CopiedArch,saveSession(this));
        end
        
        function CL = getDefaultClosedLoops(this)
            CL(1).Input = 'r';
            CL(1).Output = 'y';
            CL(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','r','y')); % r to y
            
            CL(2).Input = 'r';
            CL(2).Output = 'u';
            CL(2).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo','r','u')); % r to u
        end
    end
    
    methods (Access = protected)
        function computeClosedLoop(this)
            % given C,F,G,H construct closed-loop genss
            C = ltiblock.gain('C',1);
            F = ltiblock.gain('F',1);
            G1 = getValue(this.G1);
            G2 = getValue(this.G2);
            Gd = getValue(this.Gd);
            
            % systems
            F.InputName = 'r';  F.OutputName = 'rf';    F.Name = 'F';
            C.InputName = 'e';  C.OutputName = 'uc';    C.Name = 'C';
            G1.InputName = 'u'; G1.OutputName = 'yg1';  G1.Name = 'G1';
            G2.InputName = 'uc';G2.OutputName = 'yg2';  G2.Name = 'G2';
            Gd.InputName = 'dy';Gd.OutputName = 'ygd';  Gd.Name = 'Gd';
            
            se = AnalysisPoint('e');
            su = AnalysisPoint('u');
            suC = AnalysisPoint('uC');
            sy = AnalysisPoint('ym');
            
            s = 1;
            
            L = this.LoopSign;
            if isempty(L)
                L = -1;
            end
            
            IC = ...
                ...%'rf; Co; r; du; dy; yg1;yg2; ygd;  e; uc; u; ym
                [0	0	s	0	0	0	0    0    0   0  0   0;  %Fin    % Fin = r
                0	0	0	0	0   0   0    0    s   0  0   0;  %Cin    % Cin = e
                0	0	0	0	0	s	0    s    0   0  0   0;  %y      % y = ygd+yg1
                0	0	0	0	0	0	0    0    0   0  s   0;  %Gin1    % Gin1 = u
                0	0	0	0	0	0	0    0    0   s  0   0;  %Gin2    % Gin2 = uc
                0	0	0	0	s   0   0    0    0   0  0   0;  %Gind    % Gind = dy
                s	0	0	0	0   0   0    0    0   0  0  L*s;  %e      % e = rf-ym
                0	s	0	0	0   0   0    0    0   0  0   0;  %uc     % uc = Co
                0	0	0	s	0   0   0    0    0   s  0   0;  %u      % u = du+uc
                0	0	0	0	0   s  -s    s    0   0  0   0]; %ym     % ym = ygd+yg1-yg2
            
            IC = IC*ss(1);
            IC.InputName = {'rf';'Co';'r';'du';'dy';'yg1';'yg2';'ygd';'e';'uc';'u';'ym'};
            IC.OutputName = {'Fin';'Cin';'y';'Gin1';'Gin2';'Gind';'e';'uc';'u';'ym'};
            
            
            Plant = blkdiag(G1,G2,Gd,se,suC,su,sy);
            
            this.LFT.IC = lft(IC,Plant);
            
            this.LFT.Blocks = blkdiag(F,C);
            
            this.System = lft(this.LFT.Blocks,this.LFT.IC);
            
            % Compute Adjacency matrix to see which compensators are in series
            % The adjacency matrix is different from the inter-connections
            % in the following ways:
            %   1. The AM has to be numeric
            %   2. The AM is not affected by external inputs or outputs
            %   3. The AM requires additional nodes for sum blocks.
            %   4. The AM matrix is defined from output to input, and hence
            %   is the transpose of the IC matrix.
            
            AM = zeros(13,13);
            AM(1,3) = 1;            % 1. F = r
            AM(2,4) = 1;            % 2. C = Se
            AM(3,:) = 0;            % 3. r = 0
            AM(4,[1 13]) = 1;       % 4. Se = F+Sum2
            AM(5,[2 6]) = 1;        % 5. Su = du+C
            AM(6,:) = 0;            % 6. du = 0
            AM(7,5) = 1;            % 7. G1 = Su
            AM(8,[7 10]) = 1;       % 8. Sum1 = G1+Gd
            AM(9,:) = 0;            % 9. dy = 0
            AM(10,9) = 1;           % 10.Gd = dy
            AM(11,8) = 1;           % 11.y = Sum1
            AM(12,2) = 1;           % 12.G2 = C
            AM(13,[11 12]) = 1;     % 13.Sum2 = y+G2
            
            this.ConfigurationGraph = struct('AdjacencyMatrix',AM,...
                'TunableBlocks', [1,2], ...
                'ExternalInputs',3:5,...
                'ExternalOutputs',3,...
                'Locations',...
                struct('r',3,...
                'du',6,...
                'dy',9,...
                'y',11,...
                'e',4,...
                'u',5,...
                'uC',2,...
                'ym',13,...
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
            
            % Add Blocks - for Configuration 5
            %             assignin('base',LoopData.Plant.G(3).Name,LoopData.Plant.G(3).Model(:,:,NominalModelIdx));
            CompBlock = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
            set_param(CompBlock,'MaskValueString',[this.C.Name,'|[]|0']);
            FilterBlock = add_block('cstblocks/LTI System',[DiagramName,'/Feed Forward']);
            set_param(FilterBlock,'MaskValueString',[this.F.Name,'|[]|0']);
            InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
            InBlock2 = add_block('built-in/SignalGenerator',[DiagramName,'/Input2']);
            OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
            SumBlock = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum']);
            PlantBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
            set_param(PlantBlock1,'MaskValueString',[this.G1.Name,'|[]|0']);
            PlantBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Plant2']);
            set_param(PlantBlock2,'MaskValueString',[this.G2.Name,'|[]|0']);
            DisturbanceBlock = add_block('cstblocks/LTI System',[DiagramName,'/Disturbance Dynamics']);
            set_param(DisturbanceBlock,'MaskValueString',[this.Gd.Name,'|[]|0']);
            
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
            open_system(NewDiagram)
            
            set_param(InBlock,'Position',[80 200 110 230]);
            set_param(FilterBlock,'Position',[145 197 205 233 ]);
            set_param(SumBlock,'Position',[245 207 295 243]);
            set_param(CompBlock,'Position',[340 207 400 243]);
            set_param(PlantBlock1,'Position',[490 207 550 243 ]);
            set_param(PlantBlock2,'Position',[490 287 550 323]);
            set_param(DisturbanceBlock,'Position',[475 142 535 178]);
            set_param(OutBlock,'Position',[840 179 870 211]);
            set_param(InBlock2,'Position',[375 145 405 175]);
            SumBlock2 = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum2'],'Position',[600 129  665 256],'Inputs','++');
            SumBlock3 = add_block('simulink/Math Operations/Add',[DiagramName,'/Sum3'],'Position',[660 345 680 365],'IconShape','Round','orientation','down','Inputs','|-+');
            LinePos = {[115 215;140 215];[210 215;240 215];[670 370;230 370;230 235;240 235];...
                [300 225;335 225];[408 225;485 225];[420 225;420 305;485 305];...
                [540 160;595 160];[555 225;595 225];...
                [410 160;470 160];...
                [750 195;835 195];...
                [555 305;670 305;670 340];...
                [750 195;750 355;685 355];...
                [670 195;750 195]};
            
            % Connect blocks
            for ctLine = 1:length(LinePos)
                add_line(NewDiagram,LinePos{ctLine});
            end
            
            % Set Signal Names at  Outports
            % InBlock - 'r', CompBlock - 'u', SumBlock2 - 'y', SumBlock3 - 'ym' 
            set(get(getfield(get(InBlock,'PortHandles'),'Outport'),'Line'),'Name','r');
            set(get(getfield(get(CompBlock,'PortHandles'),'Outport'),'Line'),'Name','u');
            set(get(getfield(get(SumBlock2,'PortHandles'),'Outport'),'Line'),'Name','y');
            set(get(getfield(get(SumBlock3,'PortHandles'),'Outport'),'Line'),'Name','ym');
            
            % Open Simulink model
            open_system(NewDiagram);
        end
    end
    
    
    %% Public Methods
    methods (Access = public)
        
        function this = Config5Architecture(C,F,G1,G2,Gd)
            this = this@ctrlguis.csdesignerapp.data.architectures.internal.MatlabArchitecture;
            
            this.C =  createTunableBlock(this,'C',C);
            this.F =  createTunableBlock(this,'F',F);
            
            this.G1 = createFixedBlock(this, 'G1', G1);
            this.G2 = createFixedBlock(this, 'G2', G2);
            this.Gd = createFixedBlock(this, 'Gd', Gd);
            
            setData(this,C,F,G1,G2,Gd)
            this.TunedBlocks = [this.F;this.C];
            this.FixedBlocks = [this.G1; this.G2; this.Gd];
            this.Name = 'Feedback Configuration 5';
            
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
            Blocks = {this.C; this.F; this.G1; this.G2; this.Gd;};
        end
        
        function setData(this,C,F,G1,G2,Gd)
            setValue(this.C,C);
            setValue(this.F,F);
            setValue(this.G1, G1);
            setValue(this.G2, G2);
            setValue(this.Gd, Gd);
            this.isDirty = true;
        end
        
        function Icon = getArchitectureIcon(this)
            Icon = ctrlguis.csdesignerapp.Icon.CONFIGURATION_5;
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
                % REVISIT: Does not apply to simulink and genss
                this.isDirty = true;
            catch ME
                error(ME.message);
            end
        end
    end
end
