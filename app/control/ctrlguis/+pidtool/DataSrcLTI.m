classdef DataSrcLTI < handle
    % DATASRCLTI subclass
    %
    
    % Author(s): R. Chen
    %   Copyright 2009-2012 The MathWorks, Inc.
    
    properties
        
        % Plant and disturbance model: G
        G;
        NUP;            % number of unstable poles used in @frd
        
        % PIDTuningData
        PIDTuningData;
        
        % PID Configuration
        SampleTime                  % same as G.Ts
        TimeUnit                    % same as G.TimeUnit
        Type_;                      % valid types: p, i, pi, pd, pid, pdf, pidf
        TypeStr_;
        Form;                       % valid forms: parallel, standard
        DesignFocus = 'balanced';   % valid options: balanced, reference-tracking, disturbance-rejection
        IFormula;                   % valid methods: forward euler, backward euler, trapezoidal
        DFormula;                   % valid methods: forward euler, backward euler, trapezoidal
        
        % Loop Information from tuned PID
        DOF;            % DOF of tuned controller
        fixBC = false;  % (b,c) values fixed or free in 2-DOF controller
        fixedBC = [1 1];% fixed values of (b,c) in 2-DOF controller 
        C;              % designed PID object
        OLsys;          % G*C
        r2y;            % feedback(G*C,1)
        r2u;            % feedback(C,G)
        id2y;           % feedback(G,C)
        od2y;           % feedback(1,G*C)
        IsStable;       % r2y stability
        NeedsIntegrator % |L(0)|<1
        
        % Loop Information from baseline PID
        DOF_base;
        C_Base;
        OLsys_Base;
        r2y_Base;
        r2u_Base;
        id2y_Base;
        od2y_Base;
        IsStable_Base;
        
    end
    
    properties (Dependent = true)
        Type
        TypeStr
    end
    methods(Access = 'public')
        
        % constructor
        function this = DataSrcLTI(G,Type,Baseline)
            this.setG(G,0);
            this.setConfiguration(Type,Baseline);
            this.setPIDTuningData;
            this.setBaseline(Baseline);
        end
        
        function setG(this,G,NUP)
            this.G = G;
            this.SampleTime = G.Ts;
            this.TimeUnit = G.TimeUnit;
            this.NUP = NUP;
        end
        
        function setConfiguration(this,Type,Baseline)
            if isa(Baseline,'pid') || isa(Baseline,'pidstd') % also includes pid2, pidstd2
                % baseline is PID controller, obtain controller configuration
                this.TypeStr = lower(getType(Baseline));
                this.setConfigurationFromC(Baseline);
            else
                % otherwise, obtain default PI configuration
                this.TypeStr = lower(Type);
                PID = ltipack.getPIDfromType(this.Type,'parallel',this.SampleTime,this.TimeUnit);
                this.setConfigurationFromC(PID);
            end
        end
        
        function setPIDTuningData(this)
            PID = ltipack.getPIDfromType(this.Type,this.Form,this.SampleTime,this.TimeUnit);
            PID.IFormula = this.IFormula;
            PID.DFormula = this.DFormula;
            if this.DOF == 2 && this.fixBC
               PID.b = this.fixedBC(1);
               PID.c = this.fixedBC(2);
            end
            Options = pidtuneOptions('NumUnstablePoles',this.NUP,'DesignFocus',this.DesignFocus);
            this.PIDTuningData = getPIDTuningData(this.G,PID,Options);
        end
        
        function setConfigurationFromC(this,C)
            if isa(C,'pid') % also pid2
                this.Form = 'parallel';
            else
                this.Form = 'standard';
            end
            this.IFormula = C.IFormula;
            this.DFormula = C.DFormula;
        end
        
        function setBaseline(this, C)
            if ischar(C)
                % there is no baseline controller to compare with
                this.C_Base = [];
            else
                % baseline controller is C
                if ~isempty(C)
                    if issiso(C)
                        try %#ok<*TRYNC>
                            if strcmp(this.Form,'parallel')
                                C = pid(C);
                            else
                                C = pidstd(C);
                            end
                        end
                        this.DOF_base = 1;
                    else
                        try %#ok<*TRYNC>
                            if strcmp(this.Form,'parallel')
                                C = pid2(C);
                            else
                                C = pidstd2(C);
                            end
                        end
                        this.DOF_base = 2;
                        
                    end
                    this.C_Base = C;
                    [this.OLsys_Base, this.r2y_Base, this.r2u_Base, this.id2y_Base, this.od2y_Base] = ...
                        pidtool.utPIDgetLoopfromC(C,this.G);
                    this.IsStable_Base = this.getBaseStability;
                end
            end
        end
        
        % compute PID based on PM
        function WC = oneclick(this, PM)
            % one click design based on PM
            [PIDdata, info] = tune(this.PIDTuningData,pidtuneOptions('PhaseMargin',PM),true,this.fixBC);
            if this.DOF == 1
                if strcmp(this.Form,'parallel')
                    PID = pid.make(PIDdata);
                else
                    PID = pidstd.make(PIDdata);
                end
            else
                if strcmp(this.Form,'parallel')
                    PID = pid2.make(PIDdata);
                else
                    PID = pidstd2.make(PIDdata);
                end
            end
            PID.TimeUnit = this.TimeUnit;
            this.C = PID;
            this.IsStable = info.Stable;
            this.NeedsIntegrator = info.NeedsIntegrator;
            WC = info.wc;
            [this.OLsys, this.r2y, this.r2u, this.id2y, this.od2y] = ...
                pidtool.utPIDgetLoopfromC(PID,this.G,WC);
        end
        
        % compute PID based on WC and PM
        function fastdesign(this, WC, PM)
            % interactive design based on WC and PM
            [PIDdata, info] = tune(this.PIDTuningData, pidtuneOptions('PhaseMargin',PM,'CrossoverFrequency',WC),true,this.fixBC);
            if this.DOF == 1
                if strcmp(this.Form,'parallel')
                    PID = pid.make(PIDdata);
                else
                    PID = pidstd.make(PIDdata);
                end
            else
                if strcmp(this.Form,'parallel')
                    PID = pid2.make(PIDdata);
                else
                    PID = pidstd2.make(PIDdata);
                end
            end
            PID.TimeUnit = this.TimeUnit;
            this.C = PID;
            this.IsStable = info.Stable;
            this.NeedsIntegrator = info.NeedsIntegrator;
            [this.OLsys, this.r2y, this.r2u, this.id2y, this.od2y] = ...
                pidtool.utPIDgetLoopfromC(PID,this.G,WC);
        end
        
        % convert meta information into a structure for GUI display
        function s = generateTunedStructure(this)
            switch class(this.C)
                case 'pid'
                    [P, I, D, N] = piddata(this.C);
                    b = [];
                    c = [];
                case 'pid2'
                    [P, I, D, N, b, c] = piddata2(this.C);
                case 'pidstd'
                    [P, I, D, N] = pidstddata(this.C);
                    b = [];
                    c = [];
                case 'pidstd2'
                    [P, I, D, N, b, c] = pidstddata2(this.C);
                    
            end
            
            s = struct( 'Type', this.Type, ...
                'DOF', this.DOF, ...
                'Form', this.Form, ...
                'P',P,...
                'I',I,...
                'D',D,...
                'N',N,...
                'b',b,...
                'c',c,...
                'OLsys',this.OLsys,...
                'r2y',this.r2y,...
                'r2u',this.r2u,...
                'id2y',this.id2y,...
                'od2y',this.od2y,...
                'Plant',this.G,...
                'IsStable',this.IsStable);
        end
        
        function s = generateBaseStructure(this)
            if strcmp(class(this.C_Base),'pid') && strcmp(this.Form,'parallel') %#ok<*STISA>
                [P, I, D, N] = piddata(this.C_Base);
                b = []; c = [];
                type = lower(getType(this.C_Base));
            elseif strcmp(class(this.C_Base),'pidstd') && strcmp(this.Form,'standard')
                [P, I, D, N] = pidstddata(this.C_Base);
                b = []; c = [];
                type = lower(getType(this.C_Base));
            elseif strcmp(class(this.C_Base),'pid2') && strcmp(this.Form,'parallel')
                [P, I, D, N, b, c] = piddata2(this.C_Base);
                type = lower(getType(this.C_Base));
            elseif strcmp(class(this.C_Base),'pidstd2') && strcmp(this.Form,'standard')
                [P, I, D, N, b, c] = pidstddata2(this.C_Base);
                type = lower(getType(this.C_Base));
            else
                P = []; I = []; D = []; N = []; b = []; c = [];
                type = this.Type;
            end
            s = struct( 'Type', type, ...
                'DOF', this.DOF_base, ...
                'Form', this.Form, ...
                'P',P,...
                'I',I,...
                'D',D,...
                'N',N,...
                'b',b,...
                'c',c,...
                'OLsys',this.OLsys_Base,...
                'r2y',this.r2y_Base,...
                'r2u',this.r2u_Base,...
                'id2y',this.id2y_Base,...
                'od2y',this.od2y_Base,...
                'Plant',this.G,...
                'IsStable',this.IsStable_Base);
        end
        
        % helper function used by plot panel
        function Data = initialParameterTableData(this)
            Data = cell(4,3);
            Data(:)={blanks(4)};
            if strcmp(this.Form,'parallel');
                Data(1,1) = {'Kp'};
                Data(2,1) = {'Ki'};
                Data(3,1) = {'Kd'};
                Data(4,1) = {'Tf'};
            else
                Data(1,1) = {'Kp'};
                Data(2,1) = {'Ti'};
                Data(3,1) = {'Td'};
                Data(4,1) = {'N'};
            end
            if this.DOF == 2
                Data(5,1) = {'b'};
                Data(6,1) = {'c'};
            end
        end
        
        function isStable = getBaseStability(this)
            BCtf = tf(this.C_Base);
            if this.DOF_base == 1
                C1 = BCtf;
            else
                C1 = -BCtf(2); % 2-dof controller  = [C2 -C1]
            end
            isStable = checkNyquistStability(this.G*C1,-1,this.NUP);
        end
        
    end
    methods
        function set.Type(this,val)
            this.Type_ = val;
            if strcmp(val(end),'2')
                this.DOF = 2;
            else
                this.DOF = 1;
            end
            
        end
        
        function val = get.Type(this)
            val = this.Type_;
        end
        
        function set.TypeStr(this,val)
            
            this.TypeStr_ = val;
            bc = [1 1];
            fixbc = false;
            if any(strcmpi(val,{'i-pd','id-p','pi-d','i-pdf','idf-p','pi-df'}))
                switch val
                    case 'i-pd'
                        ctype = 'pid2';
                        bc = [0 0];
                    case 'id-p'
                        ctype = 'pid2';
                        bc = [0 1];
                    case 'pi-d'
                        ctype = 'pid2';
                        bc = [1 0];
                    case 'i-pdf'
                        ctype = 'pidf2';
                        bc = [0 0];
                    case 'idf-p'
                        ctype = 'pidf2';
                        bc = [0 1];
                    case 'pi-df'
                        ctype = 'pidf2';
                        bc = [1 0];
                end
                fixbc = true;
            else
                ctype = val;
            end
            
            this.Type = ctype; 
            this.fixedBC = bc;
            this.fixBC = fixbc;
        end
        
        function val = get.TypeStr(this)
            val = this.TypeStr_;
        end
    end
    
end

