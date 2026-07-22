function [T,fSoft,gHard,Info,LOG] = systune(T,SoftReqs,HardReqs,Options)
%SYSTUNE  Control system tuning.
%
%   SYSTUNE tunes fixed-structure control systems subject to both soft and
%   hard design goals. SYSTUNE can tune multiple fixed-order, fixed-
%   structure control elements distributed over one or more feedback loops.
%   To use SYSTUNE:
%     1) Parameterize your tunable control elements. You can either use
%        predefined structures such as PID, gain, and fixed-order transfer
%        function, or create your own structure from elementary tunable
%        parameters, see TUNABLEBLOCK for details
%     2) Use SERIES, PARALLEL, FEEDBACK, and CONNECT to build a closed-loop
%        model of the overall control system as an interconnection of fixed
%        and tunable components. Use AnalysisPoint blocks to mark locations
%        where to open feedback loops and measure responses
%     3) Use tuning goal objects to specify your design requirements, see
%        TUNINGGOAL for the list of available goals
%     4) Use the SYSTUNE function to tune the controller parameters subject
%        to your tuning goals.
%   See slTuner and slTuner/systune for tuning control systems modeled in
%   Simulink.
%
%   [CL,fSoft,gHard] = SYSTUNE(CL0,SoftReqs,HardReqs) tunes the free
%   parameters of the closed-loop model CL0 subject to the soft goals
%   SOFTREQS (objectives) and hard goals HARDREQS (contraints). CL0 is a
%   generalized state-space model (see GENSS) that keeps track of how the
%   tunable elements interact with the plant dynamics. SOFTREQS and
%   HARDREQS are vectors of tuning goals, see TUNINGGOAL for details.
%   SYSTUNE returns the tuned closed-loop model CL and the best achieved
%   values FSOFT and GHARD for the soft and hard goals. A goal is met if
%   its final value is less than 1, and the relative deviation from 1
%   measures by how much it is met or violated. Use GETBLOCKVALUE or
%   SHOWTUNABLE to access the values of the tuned elements from CL.
%
%   [CL,fSoft,gHard,INFO] = SYSTUNE(...) also returns detailed information
%   about each optimization run, see SYSTUNEINFO for details.
%
%   [...] = SYSTUNE(CL0,SoftReqs,HardReqs,Options) further specifies options
%   for the optimizer, see SYSTUNEOPTIONS for details.
%
%   You can robustly tune the control system against a set of plant models
%   by using an array of models for CL0. You can also make the controller
%   robust to parameter variations by using a model with uncertain real
%   parameters (see UREAL and USS). SYSTUNE then automatically finds the
%   worst parameter combinations and tunes the controller to maximize
%   performance over the range of parameter variations.
%
%   If x is the vector of tunable parameters and f(x),g(x) are the vectors
%   of soft and hard goal values, SYSTUNE solves the program:
%      Minimize max f(x) subject to max g(x) < 1, xMin < x < xMax.
%   Type "demo toolbox control" and look under "Control System Tuning" for
%   examples. In particular, see the "Tuning Control Systems with SYSTUNE"
%   example for a quick primer.
%
%   References:
%    [1] P. Apkarian and D. Noll, "Nonsmooth H-infinity Synthesis,"
%        IEEE Transactions on Automatic Control, 51, pp. 71-86, 2006.
%    [2] P. Apkarian and D. Noll, "Nonsmooth Optimization for Multiband
%        Frequency-Domain Control Design," Automatica, 43, pp. 724-731, 2007.
%    [3] P. Apkarian, P. Gahinet, and C. Buhr, "Multi-model, multi-objective
%        tuning of fixed-structure controllers," Proceedings ECC, pp.
%        856-861, 2014.
%    [4] P. Apkarian, M.-N. Dao, and D. Noll, "Parametric Robust Structured
%        Control Design," IEEE Transactions on Automatic Control, 2015.
%
%   See also systuneOptions, systuneInfo, TuningGoal, TuningGoal/evalGoal,
%   TuningGoal/viewGoal, tunableBlock, AnalysisPoint, genss, connect,
%   showTunable, getBlockValue, slTuner/systune, looptune.

%   Author(s): P. Apkarian, P. Gahinet
%   Copyright 2010-2020 The MathWorks, Inc.

% Parse input list
ni = nargin;
if ni<4
    if ni==3 && isa(HardReqs,'rctoptions.systune')
        Options = HardReqs;
        HardReqs = [];
    else
        Options = systuneOptions();
    end
end
if ni<3
    HardReqs = [];
end

% Validate closed-loop model
if ~isParametric(T)
    error(message('Control:tuning:systune7'))
end
T = genss(T);
if ~isreal(T)
    error(message('Control:tuning:systune9'))
elseif hasdelay(T)
    if isct(T)
        error(message('Control:tuning:systune8'))
    else
        T = absorbDelay(T);
    end
end

% Validate requirements and options
if ~(isempty(SoftReqs) || isa(SoftReqs,'TuningGoal.Generic')) || ...
        ~(isempty(HardReqs) || isa(HardReqs,'TuningGoal.Generic'))
    error(message('Control:tuning:systune10'))
end
if ~isa(Options,'rctoptions.systune')
    error(message('Control:tuning:systune11'))
end
nSoft = numel(SoftReqs);  nHard = numel(HardReqs);
StabilizeOnly = (nSoft==0 && nHard==0);
if StabilizeOnly
    SoftReqs = TuningGoal.Poles();
else
    for ct=1:nSoft
        SoftReqs(ct) = checkGoal(SoftReqs(ct),Options);
    end
    for ct=1:nHard
        HardReqs(ct) = checkGoal(HardReqs(ct),Options);
    end
end

% Key parameters and options
MINDECAY = Options.MinDecay;
nStart = 1+Options.RandomStart;
DispFcn = Options.Hidden.Trace.DisplayFcn;
WarnFcn = Options.Hidden.Trace.WarnFcn;
StopFcn = Options.Hidden.StopFcn;
TunedModels = setdiff(find(isfinite(T,'elem')),Options.SkipModels');
if isempty(TunedModels)
    error(message('Control:tuning:systune46'))
end

% Finalize Options
UseParallel = Options.UseParallel && nStart>1;
UseParallel = ltipack.util.checkParallel(UseParallel,WarnFcn);
if UseParallel && ~strcmp(Options.Display,'off')
    % Disable iteration display in parallel mode
    Options.Display = 'final';
end
Options.UseParallel = UseParallel;
% Display level (0=silent,1=final,2=sub,3=iter)
Verbosity = NSOptLog.Options.getVerbosity(Options.Display);
Options.Hidden.Trace.Verbosity = Verbosity;
Options.Hidden.StabilizeOnly = StabilizeOnly;

% Compile
% 1) TINFO: Overall set of tunable blocks, loop openings, and tunable parameters
% 2) SYSDATA: State-space data, blocks, and loop openings for each model/loop
%    configuration (struct array)
% 3) SPECDATA: Definition and runtime management of atomic design specs (struct array)
% Each tunable model is organized as follows:
%
%                                   +-------+
%      w (nw) --------------------->|       |---------------> z (nz)
%                                   |       |
%     wL (nL) ----->O-------------->|       |--------------+----> zL (nL)
%                   |               |   P   |              |
%                   |    +--------->|       |---------+    |
%                   |    |          |       |         |    |
%                   |    |    +---->|       |----+    |    |
%                   |    |    |     +-------+    |    |    |
%                   | wU | wB |                  | zB | zU |
%                   |    |    |     +-------+    |    |    |
%                   |    |    +-----|  TB   |<---+    |    |
%                   |    |          +-------+         |    |
%                   |    |                            |    |
%                   |    |          +-------+         |    |
%                   |    +----------|  UB   |<--------+    |
%                   |               +-------+              |
%                   |                                      |
%                   |               +-------+              |
%                   +---------------|  AP   |<-------------+
%                                   +-------+
% where
%   * AP = analysis points (a subset of SwitchBlocks list in tInfo)
%   * UB = uncertain blocks (a subset of UncertainBlocks list in tInfo)
%   * TB = tunable blocks (a subset of TunedBlocks list in tInfo)
% Each SYSDATA contains the A,B,C,D matrices for P and the lists of AP, UB,
% TB blocks (defined relative to tInfo).
try
    [SYSDATA,SPECDATA,tInfo] = getTuningData(T,SoftReqs,HardReqs,TunedModels,WarnFcn);
    % Enforce zero feedthrough for H2-type requirements
    if tInfo.Ts==0 && any([SPECDATA.Type]==2)
        [TZF,Refresh] = zeroFeedthrough(T,SoftReqs,HardReqs,SYSDATA,SPECDATA,tInfo);
        if Refresh
            [SYSDATA,SPECDATA,tInfo] = getTuningData(TZF,SoftReqs,HardReqs,TunedModels,WarnFcn);
        end
    end
catch ME
    throw(ME)
end

% Use initial block values as starting point for first run and generate
% random starting values if requested
x0 = localGetInitialX(tInfo);
if nStart>1
    x0 = repmat(x0,[1 nStart]);
    ip = 0;
    % Generate random samples
    % REVISIT: Randomize scalings too?
    for j=1:length(tInfo.TunedBlocks)
        blk = tInfo.TunedBlocks(j).Data;
        npfj = tInfo.TunedBlocks(j).npf;
        x0(ip+1:ip+npfj,2:nStart) = randp(blk,nStart-1,'free');
        ip = ip + npfj;
    end
end

% Initialize logs
for ct=nStart:-1:1
    RUNLOG(ct,1) = NSOptLog.Run(nSoft,nHard);
end

% Perform tuning
hw = ctrlMsgUtils.SuspendWarnings; %#ok<*NASGU>
nUB = numel(tInfo.UncertainBlocks);
RobustFlag = (nUB>0);
if UseParallel
    localCheckParallelPool();
    % Distribute randomized starts across MATLAB workers
    HiddenOpts = Options.Hidden;  % fails when using Options.Hidden as argument
    if RobustFlag
        % Robust tuning
        [SYSDATA_S,SPECDATA_S,tInfo_S] = ...
            growModelSet([],[],[],SYSDATA,SPECDATA,tInfo,zeros(nUB,1));  % DELTA=0
        for iStart=nStart:-1:1
            PF(iStart) = parfeval(@localRobTuneP,1,RUNLOG(iStart),...
                SYSDATA,SPECDATA,tInfo,SYSDATA_S,SPECDATA_S,tInfo_S,...
                x0(:,iStart),Options,HiddenOpts);
        end
    else
        % Basic tuning
        for iStart=nStart:-1:1
            PF(iStart) = parfeval(@localTuneP,1,RUNLOG(iStart),...
                SYSDATA,SPECDATA,tInfo,x0(:,iStart),Options,HiddenOpts);
        end
    end
    % Fetch results
    for iStart=1:nStart
        [cIdx,R] = fetchNext(PF);
        RUNLOG(cIdx) = R;
        % Echo worker's execution trace in command window or GUI (if any)
        HiddenOpts.Trace.DisplayFcn(PF(cIdx).Diary(1:end-1))
    end
else
    % Sequential processing
    if RobustFlag
        [SYSDATA_S,SPECDATA_S,tInfo_S] = ...
            growModelSet([],[],[],SYSDATA,SPECDATA,tInfo,zeros(nUB,1));  % DELTA=0
    else
        SYSDATA_S = SYSDATA;  SPECDATA_S = SPECDATA;  tInfo_S = tInfo;
    end

    % Nominal tuning (DELTA=0)
    if RobustFlag && nStart>1 && Verbosity>0
        DispFcn(sprintf('%s',getString(message('Control:tuning:systune33'))))
    end
    for iStart=1:nStart
        if nStart>1 && Verbosity>1
            DispFcn(sprintf('\n%s',...
                getString(message('Control:tuning:systune16',iStart,nStart))))
        end
        R = basicTuningFcn(RUNLOG(iStart),SYSDATA_S,SPECDATA_S,tInfo_S,...
            x0(:,iStart),Options);
        RUNLOG(iStart) = R;

        % Display
        if ~RobustFlag
            showFinal(R,Options,tInfo.Ts)
        elseif nStart>1
            showNominal(R,Options,tInfo.Ts,iStart)
        end

        % Early termination checks
        if StopFcn()  % abort signal
            break
        elseif ~RobustFlag
            if (StabilizeOnly && R.Fstab<0)
                % Abort signal, or stabilizing solution found
                break
            elseif ~StabilizeOnly && R.G<=1 && R.F<=Options.SoftTarget
                % Terminate when hard goals are satisfied and target value for
                % soft goals is achieved
                showTarget(R,Options,R.F);
                break
            end
        end
    end
    RUNLOG = RUNLOG(1:iStart,:);

    % Robustification
    if RobustFlag && ~StopFcn()
        % Sort runs by order of (nominal) merit
        [~,isR] = sort(RUNLOG,false);
        % Robustify nominal designs starting with the most promising
        BestSoFar = Inf(1,3);
        for iStart=1:nStart
            iRun = isR(iStart);
            if nStart>1 && Verbosity>0
                DispFcn(sprintf('\n%s',...
                    getString(message('Control:tuning:systune31',iRun))))
            end
            [RUNLOG(iRun),BestSoFar] = robustTuningFcn(RUNLOG(iRun),BestSoFar,...
                SYSDATA,SPECDATA,tInfo,SYSDATA_S,SPECDATA_S,tInfo_S,Options);
            if StopFcn()  % abort signal
                break
            end
        end
    end
end
hw = [];

% Identify best run
iBest = findBest(RUNLOG,StabilizeOnly,(nUB>0));
BESTRUN = RUNLOG(iBest);
xBest = BESTRUN.X;
fSoft = BESTRUN.fSoft;
gHard = BESTRUN.gHard;

% Construct best closed-loop
InitialBlocks = T.Blocks;
T.Blocks = localUpdateTunedBlocks(InitialBlocks,tInfo,xBest);

% Construct INFO structure for each run, and cache INFO for best run
if nargout>3
    for ct=numel(RUNLOG):-1:1
        Info(ct,1) = localMakeInfo(RUNLOG,tInfo,InitialBlocks,ct);
    end
    InfoBest = Info(iBest);
else
    InfoBest = localMakeInfo(RUNLOG,tInfo,InitialBlocks,iBest);
end
T = setTuningInfo(T,InfoBest);

% Construct overall log
if nargout>4
    LOG = NSOptLog.Main();
    LOG.Runs = RUNLOG;
    LOG.iBestRun = iBest;
end

% Flag failure to stabilize
Stabilized = (BESTRUN.Fstab<0);
if ~Stabilized && Verbosity>0
    % Failure to stabilize closed loop or controller
    if BESTRUN.MinDecay(1)<MINDECAY
        DispFcn(getString(message('Control:tuning:systune12')))
    else
        DispFcn(getString(message('Control:tuning:systune23')))
    end
end

% Warn about numerical issues encountered while tuning
if Stabilized
    Goals = [SoftReqs(:) ; HardReqs(:)];
    Flags = unique(cat(1,RUNLOG.Diagnostics),'rows');
    for ct=1:size(Flags,1)
        TG = Goals(Flags(ct,1));
        switch Flags(ct,2)  % flag ID
            case 1
                % Fixed integrators or fixed poles that cannot be stabilized to
                % MINDECAY spec
                if MINDECAY<1e-6
                    WarnFcn(message('Control:tuning:TuningWarning1',getID(TG)))
                else
                    WarnFcn(message('Control:tuning:TuningWarning2',...
                        getID(TG),sprintf('%.3g',MINDECAY)))
                end
            case 2
                % Ill-conditioned sector bound
                if isa(TG,'TuningGoal.ConicSector')
                    WarnFcn(message('Control:tuning:TuningWarning3',getID(TG)))
                end
        end
    end
end

% if nUB>0
%    BESTRUN.xDELTA(:,BESTRUN.iWC)
% end
end

%------------- Local Functions ------------------------------

function localCheckParallelPool()
% make sure a pool is available/startable. Note, the call to gcp here
% will start the pool if settings permit
if isempty(gcp)
    error(message("Control:tuning:systune48"));
end
% make sure the pool is not a ThreadPool (not currently supported)
if isa(gcp,"parallel.ThreadPool")
    error(message("Control:tuning:systune49"));
end
end

function LOG = localTuneP(LOG,SYSDATA,SPECDATA,tInfo,x0,Options,HiddenOpts)
% Single min-max tuning for parallel processing of multi-starts.
% Note: Must pass hidden options separately because data is passed to
%       workers via load/save and "Hidden" is a transient property
%       of rctoptions.systune.
hw = ctrlMsgUtils.SuspendWarnings;
HiddenOpts.Trace.DisplayFcn = @disp;  % display trace in worker's CW
Options.Hidden = HiddenOpts;
LOG = basicTuningFcn(LOG,SYSDATA,SPECDATA,tInfo,x0,Options);
showFinal(LOG,Options,tInfo.Ts);
end

%------------
function LOG = localRobTuneP(LOG,SYSDATA,SPECDATA,tInfo,...
    SYSDATA_S,SPECDATA_S,tInfo_S,x0,Options,HiddenOpts)
% Single robust tuning for parallel processing of multi-starts.
hw = ctrlMsgUtils.SuspendWarnings;
HiddenOpts.Trace.DisplayFcn = @disp;  % display trace in worker's CW
Options.Hidden = HiddenOpts;
% Nominal tuning
LOG = basicTuningFcn(LOG,SYSDATA_S,SPECDATA_S,tInfo_S,x0,Options);
% Robustification
LOG = robustTuningFcn(LOG,Inf(1,3),SYSDATA,SPECDATA,tInfo,...
    SYSDATA_S,SPECDATA_S,tInfo_S,Options);
if HiddenOpts.Trace.Verbosity>0
    disp(' ')  % separator line
end
end

%------------
function Blocks = localUpdateTunedBlocks(Blocks,tInfo,x)
% Updates blocks given vector X of free parameters.
% NOTE: Beware that solver may have fixed additional variables, e.g.,
%       to enforce zero feedthrough in H2 constraints. Work with P
%       rather than X and update original blocks.
TB = tInfo.TunedBlocks;
nblk = numel(TB);
p = tInfo.p0;
p(tInfo.iFree) = x;
ip = 0;
for ct=1:nblk
    np = TB(ct).np;
    blkName = TB(ct).Data.Name;
    Blocks.(blkName) = setp(Blocks.(blkName),p(ip+1:ip+np));
    ip = ip+np;
end
end

%------------
function Scalings = localGetScalings(tInfo,DS)
% Construct scaling for each loop switch block. The struct
% DS contains a realization of the right (input) scaling.
A = DS.a; B = DS.b; C = DS.c; D = DS.d;
iL = tInfo.nw+1:size(D,2);
sNames = cat(1,tInfo.SwitchBlocks.chID);
Scalings = ss(A,B(:,iL),C(iL,:),D(iL,iL),tInfo.Ts,...
    'InputName',sNames,'OutputName',sNames,'TimeUnit',tInfo.TU);
end

%------------
function x0 = localGetInitialX(tInfo)
% Get initial value X0 feasible for the box constraints
iFree = tInfo.iFree;
x0 = tInfo.p0(iFree);
if ~allfinite(x0)
   error(message('Control:tuning:systune47'))
end
xMin = tInfo.pMin(iFree);
xMax = tInfo.pMax(iFree);
d = xMax-xMin;
d(isinf(d)) = 10;
ix = find(x0<xMin);
if ~isempty(ix)
    x0(ix) = xMin(ix) + 0.1*d(ix);
end
ix = find(x0>xMax);
if ~isempty(ix)
    x0(ix) = xMax(ix) - 0.1*d(ix);
end
end

%------------
function Info = localMakeInfo(RUNLOG,tInfo,InitialBlocks,iRun)
% Populates Info structure
LOG = RUNLOG(iRun);
Info = struct(...
    'Run',iRun,...
    'Iterations',LOG.Iter,...
    'f',LOG.F,...
    'g',LOG.G,...
    'x',LOG.X,...
    'MinDecay',LOG.MinDecay,...
    'fSoft',LOG.fSoft,...
    'gHard',LOG.gHard,...
    'Blocks',localUpdateTunedBlocks(InitialBlocks,tInfo,LOG.X),...
    'LoopScaling',[],...
    'wcPert',[],'wcf',[],'wcg',[],'wcDecay',[]);
if ~isempty(LOG.DS)
    Info.LoopScaling = localGetScalings(tInfo,LOG.DS);
end
UB = tInfo.UncertainBlocks;
nUB = numel(UB);
if nUB>0
    % Robust tuning data
    xDELTA = LOG.xDELTA(:,LOG.iWC);
    UBN = cell(nUB,1);
    for ct=1:nUB
        blk = UB(ct).Data;
        UBN{ct} = blk.Name;
        xDELTA(ct,:) = norm2act(blk,xDELTA(ct,:));
    end
    % NOTE: wcF,wcG,... are based only on uncertain goals
    Info.wcPert = cell2struct(num2cell(xDELTA),UBN,1);
    Info.wcDecay = LOG.wcDecay;
    Info.wcf = LOG.wcF;
    Info.wcg = LOG.wcG;
end
end

