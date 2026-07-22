function SetUp = sisoinit(Config,varargin)
%SISOINIT  Help configure the Control System Designer at startup. 
%
%   T = SISOINIT(CONFIG) returns a template T for initializing
%   the Control System Designer with a particular control system 
%   configuration CONFIG.  Available configurations include:
%      CONFIG=1:  C in forward path, F in series
%      CONFIG=2:  C in feedback path, F in series
%      CONFIG=3:  C in forward path, feedforward F
%      CONFIG=4:  nested loop configuration
%      CONFIG=5;  Internal Model Control Structure (IMC)
%      CONFIG=6;  Cascade loop configuration
%   Refer to the "Edit Architecture" dialog in the
%   Control System Designer for more details.
%
%   For each configuration, you can specify the plant models G,H,
%   initialize the compensator C and prefilter F, and configure
%   the open- and closed-loop views by filling the corresponding 
%   fields of the structure T.  Then use CONTROLSYSTEMDESIGNER(T) to start
%   the Control System Designer in the specified configuration.
%
%   Example:
%      T = sisoinit(2);          % single-loop configuration with
%                                % C in the feedback path
%      T.G.Value = rss(3);       % model for plant G
%      T.C.Value = tf(1,[1 2]);  % initial compensator value
%      T.OL1.View = {'rlocus','nichols'};  % views for tuning Open Loop OL1
%
%      % Now launch Control System Designer using configuration T
%      controlSystemDesigner(T)
% 
%   See also CONTROLSYSTEMDESIGNER.

%   Copyright 1986-2016 The MathWorks, Inc.

switch Config
    case 0
        if nargin<3
            ctrlMsgUtils.error('Control:compDesignTask:sisoinit1')
        end
        Cnames = varargin{1};
        Lnames = varargin{2};
        SetUp = sisodata.design({'P'},Cnames,Lnames,Config);

    case 1
        SetUp = sisodata.design({'G','H'},{'C','F'},{'OL1','CL1'},Config);
        SetUp.FeedbackSign = -1;
        SetUp.Input = {'r';'dy';'du';'n'};
        SetUp.Output = {'y';'u'}; % performance outputs

        OL1 = SetUp.OL1;
        OL1.Name = getString(message('Control:compDesignTask:strOpenLoopNum',1));
        OL1.Description = getString(message('Control:compDesignTask:strOpenLoopL','L'));
        OL1 = OL1.setProperty('Feedback', true); % feedback
        OL1 = OL1.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C','PortNumber', []), ...
            'LoopOpenings', []));
        OL1.View  =  {'rlocus','bode'};
        SetUp.OL1 = OL1;
        
        CL1 = SetUp.CL1;
        CL1.Name = getString(message('Control:compDesignTask:strClosedLoopNum',1));
        CL1.Description = getString(message('Control:compDesignTask:strClosedLoopFromToLong','r', 'y'));
        CL1 = CL1.setProperty('Feedback', false); % Closed Loop
        CL1 = CL1.setProperty('LoopConfig', []);
        CL1 = CL1.setProperty('ClosedLoopIOs', [1,1]);
        CL1 = CL1.setProperty('TunedFactors', {'F'});
        CL1.View  =  {'bode'};
        SetUp.CL1 = CL1;
        
        
    case {2 3}
        SetUp = sisodata.design({'G','H'},{'C','F'},{'OL1','CL1'},Config);
        SetUp.FeedbackSign = -1;
        SetUp.Input = {'r';'dy';'du';'n'};
        SetUp.Output = {'y';'u'}; % performance outputs
        SetUp.C.Description = getString(message('Control:compDesignTask:strCompensator'));
        if Config==3
            SetUp.F.Description = getString(message('Control:compDesignTask:strFeedforward'));
        else
            SetUp.F.Description = getString(message('Control:compDesignTask:strPrefilter'));
        end
        
        OL1 = SetUp.OL1;
        OL1.Name = getString(message('Control:compDesignTask:strOpenLoopNum',1));
        OL1.Description = getString(message('Control:compDesignTask:strOpenLoopL','L'));
        OL1 = OL1.setProperty('Feedback', true); % feedback
        OL1 = OL1.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C','PortNumber', []), ...
            'LoopOpenings', []));
        OL1.View  =  {'rlocus','bode'};
        SetUp.OL1 = OL1;

        CL1 = SetUp.CL1;
        CL1.Name = getString(message('Control:compDesignTask:strClosedLoopNum',1));
        CL1.Description = getString(message('Control:compDesignTask:strClosedLoopFromToLong','r', 'y'));
        CL1 = CL1.setProperty('Feedback', false); % Closed Loop
        CL1 = CL1.setProperty('LoopConfig',[]);
        CL1 = CL1.setProperty('ClosedLoopIOs', [1,1]);
        CL1 = CL1.setProperty('TunedFactors', {'F'});
        CL1.View  =  {'bode'};
        SetUp.CL1 = CL1;

    case 4
        SetUp = sisodata.design({'G','H'},{'C1','C2'},{'OL1','OL2'},Config);
        SetUp.FeedbackSign = [-1;-1];
        SetUp.Input = {'r';'dy';'du';'n'};
        SetUp.Output = {'y';'u'}; % performance outputs

        SetUp.C1.Description = getString(message('Control:compDesignTask:strPrimaryCompensator'));
        SetUp.C2.Description = getString(message('Control:compDesignTask:strSecondaryCompensator'));

        OL1 = SetUp.OL1;
        OL1.Name = getString(message('Control:compDesignTask:strOpenLoopNum',1));
        OL1.Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf', 'C1'));
        OL1 = OL1.setProperty('Feedback',true); % feedback
        OL1 = OL1.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C1','PortNumber', []), ...
            'LoopOpenings', struct('BlockName','C2','PortNumber',[], ...
            'Status', false)));
        OL1.View  =  {'rlocus','bode'};
        SetUp.OL1 = OL1;
        
        OL2 = SetUp.OL2;
        OL2.Name = getString(message('Control:compDesignTask:strOpenLoopNum',2));
        OL2.Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf', 'C2'));
        OL2 = OL2.setProperty('Feedback', true); % feedback
        OL2 = OL2.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C2','PortNumber', []), ...
            'LoopOpenings', struct('BlockName','C1','PortNumber',[], ...
            'Status', false)));
        OL2.View  =  {'rlocus','bode'};
        SetUp.OL2 = OL2;
        
    case 5
        SetUp = sisodata.design({'G1','G2','Gd'},{'C','F'},{'OL1','CL1'},Config);
        SetUp.FeedbackSign = -1;
        SetUp.Input = {'r';'du';'dy'};
        SetUp.Output = {'y';'u';'dt'}; % performance outputs

        OL1 = SetUp.OL1;
        OL1.Name = getString(message('Control:compDesignTask:strOpenLoopNum',1));
        OL1.Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf', 'C'));
        OL1 = OL1.setProperty('Feedback', true); % feedback
        OL1 = OL1.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C','PortNumber', []), ...
            'LoopOpenings', []));
        OL1.View  =  {'rlocus','bode'};
        SetUp.OL1 = OL1;

        CL1 = SetUp.CL1;
        CL1.Name = getString(message('Control:compDesignTask:strClosedLoopNum',1));
        CL1.Description = getString(message('Control:compDesignTask:strClosedLoopFromToLong','r', 'y'));
        CL1 = CL1.setProperty('Feedback', false); % Closed Loop
        CL1 = CL1.setProperty('LoopConfig', []);
        CL1 = CL1.setProperty('ClosedLoopIOs', [1,1]);
        CL1 = CL1.setProperty('TunedFactors', {'F'});
        CL1.View  =  {'bode'};
        SetUp.CL1 = CL1;
    case 6
        SetUp = sisodata.design({'G1','G2','H1','H2'},{'C1','C2','F'},{'OL1','OL2'},Config);
        SetUp.FeedbackSign = [-1;-1];
        SetUp.Input = {'r1';'du1';'du2';'dy';'n1';'n2'};
        SetUp.Output = {'u1';'y2';'u2';'y1'}; % performance outputs

        OL1 = SetUp.OL1;
        OL1.Name = getString(message('Control:compDesignTask:strOpenLoopNum',1));
        OL1.Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf', 'C1'));
        OL1 = OL1.setProperty('Feedback',true); % feedback
        OL1 = OL1.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C1','PortNumber', []), ...
            'LoopOpenings', []));
        OL1.View  =  {'rlocus','bode'};
        SetUp.OL1 = OL1;

        OL2 = SetUp.OL2;
        OL2.Name = getString(message('Control:compDesignTask:strOpenLoopNum',2));
        OL2.Description =getString(message('Control:compDesignTask:strOpenLoopOutputOf', 'C2'));
        OL2 = OL2.setProperty('Feedback', true); % feedback
        OL2 = OL2.setProperty('LoopConfig', struct( ...
            'OpenLoop', struct('BlockName','C2','PortNumber', []), ...
            'LoopOpenings', struct('BlockName','C1','PortNumber',[], ...
            'Status', false)));
        OL2.View  =  {'rlocus','bode'};
        SetUp.OL2 = OL2;

        
        
end

%Loop views
if Config>0
   SetUp = SetUp.setLoopView(loopviews(SetUp,Config));
end
