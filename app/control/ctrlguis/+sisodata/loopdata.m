classdef loopdata < matlab.mixin.SetGet & matlab.mixin.Copyable
%sisodata.loopdata class
%    sisodata.loopdata properties:
%       Name - Property is of type 'ustring'  
%       Identifier - Property is of type 'string'  
%       History - Property is of type 'MATLAB array'  
%       Input - Property is of type 'MATLAB array'  
%       Output - Property is of type 'MATLAB array'  
%       LoopView - Property is of type 'MATLAB array'  
%       Plant - Property is of type 'handle'  
%       Ts - Property is of type 'double'  
%       C - Property is of type 'handle vector'  
%       L - Property is of type 'handle vector'  
%       EventData - Property is of type 'MATLAB array'  
%
%    sisodata.loopdata methods:
%       addLoop -  Adds a loop to loopdata and initialized listeners
%       addLoopView -  Add a loop view.
%       checkdata -  Check validity of imported data.
%       dataevent -  Issues LoopDataChanged event
%       describe -  Full description of tuned components.
%       drawdiagram -  Draws Simulink diagram for SISO Tool feedback loop.
%       exportdesign -  Exports SISO Tool data as @initdata object.
%       getclosedloop -  Gets the closed-loop model.
%       getconfig -  Returns current loop configuration
%       getmargins -  Computes stability margins of a given feedback loop.
%       getmodel -  Computes loop transfer functions as LTI objects.
%       hasFeedback -  Returns a boolean vector with true for compensator with
%       importdata -  Imports plant and compensator data.
%       importdesign -  Applies configuration settings
%       pfrespCL -  Computes closed-loop frequency response parameterized by the gain
%       reset -  Cleans up dependent data when core data changes.
%       setNominalModelIndex -  Sets the index for the nominal model.
%       setconfig -  Sets the loop configuration to one of the predefined choices.
%       store -  designs in design history.


properties (Access=protected, SetObservable)
    %CLOSEDLOOP Property is of type 'MATLAB array' 
    ClosedLoop = [];
    %LISTENERS Property is of type 'MATLAB array' 
    Listeners = struct( 'Fixed', [  ], 'Tuned', [  ] );
end

properties (SetObservable)
    %NAME Property is of type 'ustring' 
    Name = 'untitled';
    %IDENTIFIER Property is of type 'string' 
    Identifier = '';
    %HISTORY Property is of type 'MATLAB array' 
    History = [];
    %INPUT Property is of type 'MATLAB array' 
    Input = [];
    %OUTPUT Property is of type 'MATLAB array' 
    Output = [];
    %LOOPVIEW Property is of type 'MATLAB array' 
    LoopView = [];
    %PLANT Property is of type 'handle' 
    Plant = [];
    %TS Property is of type 'double' 
    Ts = 0;
    %C Property is of type 'handle vector' 
    C = [];
    %L Property is of type 'handle vector' 
    L = [];
    %EVENTDATA Property is of type 'MATLAB array' 
    EventData = struct( 'Phase', [  ], 'Scope', [  ], 'Component', [  ], 'Editor', [  ], 'Extra', [  ] );
end


events 
    FirstImport
    ConfigChanged
    LoopDataChanged
    MoveGain
    MovePZ
    SingularLoop
end  % events

    methods  % constructor block
        function h = loopdata
        % Constructor
        
        
        % set unique identifier for loopdata used by model api
                h.Identifier = ['SISOTool ',datestr(now)];
        end  % loopdata
        
    end  % constructor block

    methods 
        function set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function set.Identifier(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Identifier')
        obj.Identifier = value;
        end

        function set.Input(obj,value)
        obj.Input = LocalSetValue(obj,value);
        end

        function set.Output(obj,value)
        obj.Output = LocalSetValue(obj,value);
        end

        function set.Plant(obj,value)
            % DataType = 'handle'
        validateattributes(value,{'handle'}, {'scalar'},'','Plant')
        obj.Plant = value;
        end

        function set.Ts(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Ts')
        value = double(value); %  convert to double
        obj.Ts = value;
        end

        function set.C(obj,value)
            % DataType = 'handle vector'
        validateattributes(value,{'handle','double'},{},'','C')
        obj.C = value;
        end

        function set.L(obj,value)
            % DataType = 'handle vector'
        validateattributes(value,{'handle','double'},{},'','L')
        obj.L = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function addLoop(this,TunedLoops)
       % addLoop  Adds a loop to loopdata and initialized listeners
       
       
       % Append Loops to the list
       this.L = [this.L; TunedLoops];
       
       
       % Add listeners to the loops
       for ct = 1:length(TunedLoops);
           TunedLoops(ct).addListeners(this);
       end
           
       end  % addLoop
       
        %----------------------------------------
       function addLoopView(this,LoopTF)
       %ADDLOOPVIEW  Add a loop view.
       
       
       ColorStyle = {'b', 'g', 'r', 'c', 'm', 'y', ...
           'b--', 'g--', 'r--', 'c--', 'm--', 'y--', ...
           'b-.', 'g-.', 'r-.', 'c-.', 'm-.', 'y-.', ...
           'b^', 'g^', 'r^', 'c^', 'm^', 'y^'};
       
       LoopTF.Style = ColorStyle{mod(length(this.LoopView),length(ColorStyle))+1};
       this.LoopView(end+1,1) = LoopTF;
       
       end  % addLoopView
       
        %----------------------------------------
       function [InitData,Ts] = checkdata(this,InitData)
       %CHECKDATA  Check validity of imported data.
       
       %   Author(s): P. Gahinet
       nC = length(InitData.Tuned);
       nG = length(InitData.Fixed);
       
       % G and C are nG-by-1 and nC-by-1 structures with fields Name and Value
       FirstImport = isempty(this.Plant); % 1 if no data in yet
       
       % Validate tuned models
       for ct=1:nC
          Component = this.C(ct);
          CompID = InitData.Tuned{ct};
          CData = InitData.(CompID);
          % Check that ZPK2ParFcn and Par2ZPKFcn are valid g292839
          CData.utCheckParZPKFcn;
          if ~isequal(CData.Value,[])
             % Check validity of modified component
             % RE: [] indicates no change in value and avoids losing 
             %     complex & lead/lag groups in non-modified compensators
             %     (sisotool('nichols',1), add complex pair, change config)
             CData = LocalCheckCompensatorModelData(CData,Component.Identifier);
             InitData.(CompID) = CData;
          end
       end
       
       % Validate fixed models
       if getconfig(this.Plant)>0
          % Built-in loop structure
          idx = 1;
          GFRD = {};
          GSize = zeros(nG,1);
          for ct=1:nG
             Component = this.Plant.G(ct);
             CompID = InitData.Fixed{ct};
             GData = InitData.(CompID);
             if ~isempty(GData.Value)
                % Check validity of modified component
                GData = LocalCheckFixedModelData(GData,Component.Identifier);
                if isa(GData.Value,'frd')
                   GFRD{idx} = GData.Value; %#ok<AGROW>
                   idx = idx+1;
                end
             elseif FirstImport
                GData = struct('Name',sprintf('untitled%s',Component.Identifier),'Value',zpk(1));
             else
                GData = save(Component,GData);
             end
             GSize(ct) = nmodels(GData.Value);
             InitData.(CompID) = GData;
          end
          % Ensure FRD models are compatible
          if ~isempty(GFRD)
             try
                LocalCheckFRDConsistency(GFRD);
             catch ME
                ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck13')
             end
          end
          % Ensure Arrays are compatible
          % Elements must be single model or vectors of same size
          if ~all((GSize == 1) | (GSize == max(GSize)))
             ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck16')
          end
          
          
       else
          % Specifying augmented plant P
          if ~isempty(InitData.P.Value)
             % Check validity of P model
             InitData.P = LocalCheckP(InitData.P,length(this.C));
          elseif FirstImport
             ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck01')
          else
             InitData.P = save(this.Plant);
          end
       end
       
       
       % Check sample time consistency
       % RE: May affect "unchanged" components
       Ts = LocalCheckSampleTime(this,InitData);
       end  % checkdata
       
       
       
       
       %----------------- Local functions -----------------
       
       

        %----------------------------------------
       function dataevent(this,Scope,C)
       %DATAEVENT  Issues LoopDataChanged event
       
       
       % RE: Scope = what has changed (all|gain)
       %     C = what component was modified
       if nargin<3
          C = [];
       end
       
       % Clear derived data
       this.reset(Scope,C);
       
       % Broadcast event
       this.EventData.Scope = Scope;
       this.EventData.Component = C;
       this.notify('LoopDataChanged')
       
       end  % dataevent
       
        %----------------------------------------
       function Str = describe(this,idxC,CapitalizeFlag)
       % Full description of tuned components.
       
       %   Author(s): P. Gahinet
       if this.Ts
           DomainVar = 'z';
       else
           DomainVar = 's';
       end
       C = this.C(idxC);
       if CapitalizeFlag
          Str = sprintf('%s %s(%s)',C.Description,C.Identifier,DomainVar);
       else
          Str = sprintf('%s %s(%s)',lower(C.Description),C.Identifier,DomainVar);
       end   
       
       end  % describe
       
        %----------------------------------------
       function drawdiagram(LoopData)
       %DRAWDIAGRAM  Draws Simulink diagram for SISO Tool feedback loop.
       
       %   Author(s): K. Gondoly and P. Gahinet
       
       %---Check if the User has Simulink
       if license('test', 'SIMULINK')
           Answer = questdlg(...
               getString(message('Control:compDesignTask:DrawDiagramMsg1')),...
               getString(message('Control:compDesignTask:strDrawingSimulinkDiagrams')), ...
               getString(message('Control:compDesignTask:strYes')), ...
               getString(message('Control:compDesignTask:strNo')), ...
               getString(message('Control:compDesignTask:strYes')));
           if strcmp(Answer,getString(message('Control:compDesignTask:strYes')))
               LocalDrawDiagram(LoopData)
           end
       else
           warndlg(getString(message('Control:compDesignTask:DrawDiagramMsg2')),...
               getString(message('Control:compDesignTask:strSISOToolWarning')));
       end
       end  % drawdiagram
        
       
       %----------------- Local functions -----------------
       
       %%%%%%%%%%%%%%%%%%%%%%%%
       %%% LocalDrawDiagram %%%
       %%%%%%%%%%%%%%%%%%%%%%%%

        %----------------------------------------
       function Design = exportdesign(this)
       % Exports SISO Tool data as @initdata object.
       
       %   Author(s): P. Gahinet
       Config = getconfig(this.Plant);
       if Config==0
         
          Design = LocalConfig0Setup(this);
          Design.Name = this.Name;
          Design.Input = this.Input;
          Design.Output = this.Output; 
          Design = Design.setLoopView(this.LoopView);
          
       else
          Design = sisoinit(Config);
          Design.Name = this.Name;
          Design.FeedbackSign = this.Plant.LoopSign;
          Design.Input = this.Input;
          Design.Output = this.Output;
          Design = Design.setLoopView(this.LoopView);
          
          if ~isempty(this.Plant)
             for ct=1:length(this.Plant.G)
                Gid = Design.Fixed{ct};
                Design.(Gid) = save(this.Plant.G(ct),Design.(Gid));
             end
             
             for ct=1:length(this.C)
                Cid = Design.Tuned{ct};
                Design.(Cid) = save(this.C(ct),Design.(Cid));
             end
          end
       end
       Design.NominalModelIndex = this.Plant.getNominalModelIndex;
       end  % exportdesign
       
       
       
       

        %----------------------------------------
       function [CLNom,CL] = getclosedloop(this,outputs,inputs)
       %GETCLOSEDLOOP  Gets the closed-loop model.
       %
       %   GETCLOSEDLOOP(THIS) returns a MIMO @ssdata model
       %   mapping this.Input to this.Output.
       %
       %   GETCLOSEDLOOP(THIS,OUTPUTS,INPUTS) returns a
       %   structurally minimal @ssdata model of the 
       %   closed-loop map between the I/Os specified by
       %   INPUTS and OUTPUTS (index vectors or string
       %   vectors).
       
       %   Author(s): P. Gahinet, N. Hickey, K. Subbarao
       CL = this.ClosedLoop;
       if isequal(CL,[]) && ~isempty(this.Plant)
          % Recompute overall closed-loop model if not available
          nC = length(this.C);
       
          % Get augmented plant for closed-loop analysis
          Psim = getPsim(this.Plant);
          
          % Build vector of state-space models of C1,C2,...,CN
          if isa(Psim,'ltipack.frddata')
              C = createArray([nC 1], 'ltipack.frddata');
              freqs = Psim.Frequency;
              for ct=1:nC
                  C(ct,1) = frd(zpk(this.C(ct)),freqs);
              end
          else
              C = createArray([nC 1],'ltipack.ssdata');
              for ct=1:nC
                  C(ct) = ss(this.C(ct));
              end
          end
       
       
       
          % Close the loop
          try
             % Call optimize LTF code to close N SISO loops
             if isa(Psim,'ltipack.frddata')
                 CL = creaetArray([length(Psim) 1],'ltipack.frddata');
             else
                 CL = createArray([length(Psim) 1],'ltipack.ssdata');
             end
             for ct = 1:length(Psim)
                 CL(ct) = utSISOLFT(Psim(ct),C);
             end
          catch %#ok<CTCH>
             % Algebraic loop
             nu = length(this.Input);
             ny = length(this.Output);
             CL = ltipack.ssdata([],zeros(0,nu),zeros(ny,0),...
                NaN(ny,nu),[],this.Ts);
          end
          this.ClosedLoop = CL;
       end
       
       % Extract subsystem for specified I/Os
       if nargin>1
          if isnumeric(inputs)
             idxIn = inputs;
          else % char and cell of strings
             [~,idxIn] = ismember(inputs,this.Input);
             idxIn = idxIn(idxIn>0);
          end
          if isnumeric(outputs)
             idxOut = outputs;
          else
             [~,idxOut] = ismember(outputs,this.Output);
             idxOut = idxOut(idxOut>0);
          end
          if isempty(idxOut) || isempty(idxIn)
             CL = [];
          else
              for ct = 1:length(CL)
                  CL(ct) = getsubsys(CL(ct),idxOut,idxIn,'smin');
              end
          end
       end
       
       CLNom = CL(this.Plant.getNominalModelIndex);
       end  % getclosedloop
       
        %----------------------------------------
       function [ConfigID,FeedbackSigns] = getconfig(this)
       %GETCONFIG  Returns current loop configuration
       
       [ConfigID,FeedbackSigns] = getconfig(this.Plant);
       
       end  % getconfig
       
        %----------------------------------------
       function Margins = getmargins(this,idxL)
       % Computes stability margins of a given feedback loop.
       
       
       % RE: not called unless OpenLoop is well defined
       L = this.L(idxL);
       if isempty(L)
          Margins = [];
          return
       end
       
       % Recompute margins if not already cached
       if isempty(L.Margins)
          % Compute margins
          % RE: Units are: GM(absolute)  Pm(degree)  Wcg,Wcp(radians/sec)
          sw = warning('off','Control:transformation:StateSpaceScaling'); [lw,lwid] = lastwarn;
          [Gm,Pm,junk,Wcg,Wcp,isStable] = utGetMinMargins(allmargin(getOpenLoop(L)));
          warning(sw); lastwarn(lw,lwid);
          
          % Build and store result
          L.Margins = struct('Gm',Gm,'Pm',Pm,'Wcg',Wcg,'Wcp',Wcp,'Stable',isStable);
       end
       
       Margins = L.Margins;
       
       
       end  % getmargins
       
        %----------------------------------------
       function [NomModel,Model] = getmodel(this,LoopTF)
       %GETMODEL  Computes loop transfer functions as LTI objects.
       %
       %   LOOPTF is a structure specifying the loop transfer of interest
       %   (see LOOPTRANSFERS for details). The output MODEL is an @lti 
       %   object.
       
       %   Author(s): P. Gahinet
       
       NominalIdx = this.P.getNominalModelIndex;
       
       switch LoopTF.Type
          case 'G'
             Model = this.Plant.G(LoopTF.Index).Model;
             localSetDefaultIOName(Model);
             if nmodels(Model) == 1;
                 NomModel = Model;
             else
                 NomModel = Model(:,:,NominalIdx);
             end
          case 'C'
             Model = zpk.make(zpk(this.C(LoopTF.Index)));
             localSetDefaultIOName(Model);
             NomModel = Model;
             Model = [];
          case 'L'
             % getOpenLoop returns @ssdata or @frddata model
             P = this.Plant.getP;
             if isa(P,'ltipack.frddata')
                 DataModel = ltipack.frddata.array([length(P) 1]);
             else
                 DataModel = ltipack.ssdata.array([length(P) 1]);
             end    
             for ct = 1:length(P)
                 DataModel(ct,1) =  getOpenLoop(this.L(LoopTF.Index),[],ct);
             end  
             if isa(P,'ltipack.frddata')
                 Model = frd.make(DataModel);
             else
                 Model = ss.make(DataModel);
             end
            
             localSetDefaultIOName(Model);
             NomModel = Model(:,:,NominalIdx);
          case 'T'
             % getclosedloop returns @ssdata or @frddata model
             [~,ModelData] = getclosedloop(this,LoopTF.Index{:});
             if isa(ModelData,'ltipack.frddata')
                 Model = frd.make(ModelData);
             else
                 Model = ss.make(ModelData);
             end
             set(Model,...
                'InputName',this.Input(LoopTF.Index{2}),...
                'OutputName',this.Output(LoopTF.Index{1}));
             NomModel = Model(:,:,NominalIdx);
          case 'Tss'
             % Returns @ssdata or @frddata model
             [~,ModelData] = getclosedloop(this);
             if isa(ModelData,'ltipack.frddata')
                 Model = frd.make(ModelData);
             else
                 Model = ss.make(ModelData);
             end
             set(Model,'InputName',this.Input,'OutputName',this.Output);
             NomModel = Model(:,:,NominalIdx);
          case 'P'
             % Returns @ssdata or @frddata model
             ModelData = getP(this.Plant);
             if isa(ModelData,'ltipack.frddata')
                 Model = frd.make(ModelData);
             else
                 Model = ss.make(ModelData);
             end
             
             NomModel = Model(NominalIdx);
       end
       
       if ~isUncertain(this.P)
           Model = [];
       end
       
       
       end
       
       

        %----------------------------------------
       function boo = hasFeedback(this)
       % Returns a boolean vector with true for compensator with
       % feedback and false otherwise.
       
       nL = length(this.L);
       boo = false(nL,1);
       for ct=1:nL
          boo(ct) = this.L(ct).Feedback;
       end
       
       end  % hasFeedback
       
        %----------------------------------------
       function importdata(this,Design)
       %IMPORTDATA  Imports plant and compensator data.
       %
       %   Design is a @Design instance that contains data for
       %   the fixed and tuned components. Imported data includes
       %   model name and model value. To skip a particular component, 
       %   set its Value to [].
       
       %   Author(s): P. Gahinet
       
       
       % Check that data is valid (may throw an error)
       
       % Revisit
       [Design,Ts] = checkdata(this,Design);
       
       % Notify peers of first import
       if isempty(this.Plant)
          % Enable GUI functionality
          this.notify('FirstImport')
       end
       
       % Import compensator data
       for ct=1:length(Design.Tuned)
          Cdata = Design.(Design.Tuned{ct});
          this.C(ct).import(Cdata);
          this.C(ct).Ts = Ts;
       end
          
       % Import plant data
       % RE: After comp. data because setting P for config=0 will trigger
       %     ConfigChanged event that may access compensator data
       for ct=1:length(Design.Fixed)
          Gdata(ct,1) = Design.(Design.Fixed{ct});
          Gdata(ct,1).Value.Ts = Ts;
       end
       this.Plant.import(Gdata);
       
       % Import Loops data
       for ct=1:length(Design.Loops)
          Ldata = Design.(Design.Loops{ct});
          this.L(ct).Ts = Ts;
          this.L(ct).Identifier = Design.Loops{ct};
          this.L(ct).import(Ldata,this);
       end
       
       
       % Update overall loop sample time
       this.Ts = Ts;
       
       end  % importdata
       
        %----------------------------------------
       function importdesign(this,Design)
       % Applies configuration settings
       
       %   Author(s): P. Gahinet
       
       % Applies new configuration
       this.setconfig(Design)    % triggers config. rendering
       
       % Import data
       this.importdata(Design)
       
       % Update list of available loop views
       % RE: will trigger Viewer update if set of loop models changes
       this.LoopView = Design.getLoopView;
       
       % Set nominal value
       try
           Index = Design.NominalModelIndex;
           this.Plant.setNominalModelIndex(Index)
           Loops = this.L;
           for ct = 1:length(Loops)
               Loops(ct).Nominal = Index;
           end
       catch ME
           % Current value is invalid revert to first element
           Index = 1;
           this.Plant.setNominalModelIndex(Index)
           Loops = this.L;
           for ct = 1:length(Loops)
               Loops(ct).Nominal = Index;
           end
       end
       
       
       % Notify external clients of configuration change
       % RE: 1) Must be done after data import so that all names are uptodate
       %        (this event is responsible for updating system names on system 
       %        view and editors)
       %     2) This event must be issued prior to LoopDataChanged to update
       %        editor dependency list and hide irrelevant editors
       this.notify('ConfigChanged')  
       
       % Notify peers of data change
       this.dataevent('all')
       
       end  % importdesign
       
        %----------------------------------------
       function S = pfrespCL(this,w,C,Tin,Tout,idxM)
       % Computes closed-loop frequency response parameterized by the gain
       % of the compensator C with index IDXC.
       %
       % PFRESPCL computes a 2x2 frequency response together with the frequency
       % response of the normalized compensator C so that the closed-loop   
       % frequency response hT from input TIN to output TOUT is given by
       %    hT = lft(hP,g*hC)
       % where g = getgain(C,'mag') is the gain of C.
       %
       % This parameterized representation allows for fast update when 
       % dynamically modifying C.
       
       %   Author(s): P. Gahinet
       
       if nargin < 6
           idxM = this.Plant.getNominalModelIndex;
       end
       
       idxC = find(C == this.C);
       
       nw = length(w);
       nC = length(this.C);
       
       % Compute plant frequency response (NC+1-by-NC+1)
       h = fresp(this.Plant,w,Tin,Tout,'sim',idxM);
       
       % Compute permutation that reorders compensators so that 
       %   * IDXC is last
       %   * The external I/Os are second last
       idxf = [1:idxC-1 , idxC+1:nC];
       perm = [idxf+1,1,idxC+1];
       
       % Response of fixed compensators
       F = zeros(nw,nC-1);
       for ct=1:nC-1
          % Skip compensators with loop opened
          fh = fresp(zpk(this.C(idxf(ct))),w);
          F(:,ct) = fh(:);
       end
       
       % Response of 2x2 model P such that lft(P,C) is the plant model for the IDXOL loop
       P = zeros(2,2,nw);
       n = nC+1;  % row and col size
       for ctw=1:nw
          Pw = h(perm,perm,ctw);
          % Close upper loops around fixed compensators
          Fw = F(ctw,:);
          for ct=1:nC-1
             Pw(ct+1:n,ct+1:n) = Pw(ct+1:n,ct+1:n) + ...
                (Pw(ct+1:n,ct) * (Fw(ct)/(1-Pw(ct,ct)*Fw(ct)))) * Pw(ct,ct+1:n);
          end
          P(:,:,ctw) = Pw(nC:n,nC:n);
       end
          
       % Normalized response of modified compensator
       Cf = reshape(fresp(zpk(this.C(idxC),'norm'),w),nw,1);
       
       S = struct('P',permute(P,[3 1 2]),'C',Cf,'w',w);
       end  % pfrespCL
       
        %----------------------------------------
       function reset(this,Scope,C)
       % Cleans up dependent data when core data changes.
       %
       %   RESET(this,'all')
       %   RESET(this,'root',C)
       %   RESET(this,'gain',C)
       %   RESET(this,'ol',C)
       
       %   Author(s): P. Gahinet
       
       switch Scope
          case 'all'
              % Clear all dependent data
              this.ClosedLoop = [];
              % Set gain to [] as dirty indicator
              for ct = 1:length(this.C)
                  this.C(ct).reset('all');
              end
              for ct=1:length(this.L)
                  % Clear open-loop data
                  this.L(ct).reset(Scope);
              end
             
          case 'root'
             % Modified poles or zeros of C-th tuned model
             this.ClosedLoop = [];
             C.reset('all')
             % Clear open-loop data that depends on C
             for ct=1:length(this.L)
                % Clear open-loop data
                this.L(ct).reset(Scope,C); 
             end
             
          case 'gain'
             % Modified gain of C-th tuned model
             C.reset('gain')
             this.ClosedLoop = [];
             % Clear other open-loop models whose "plant" depends on C
             for ct=1:length(this.L)
                this.L(ct).reset(Scope,C);
             end
             
           case 'compensator'
               % Modified C-th tuned model
               C.reset('all')
               this.ClosedLoop = [];
               % Clear other open-loop models whose "plant" depends on C
               for ct=1:length(this.L)
                   this.L(ct).reset(Scope,C);
               end
             
             
          case 'cl'
             % Clear closed-loop model (e.g., when changing LoopStatus)
             this.ClosedLoop = [];
       
       end
       end  % reset
       
        %----------------------------------------
       function setNominalModelIndex(this,Index)
       %setNominalModelIndex  Sets the index for the nominal model.
       
       
       Plant = this.Plant;
       Loops = this.L;
       
       if (mod(Index,1) == 0) && (Index <= length(Plant.getP))&&(Index > 0)
           Plant.setNominalModelIndex(Index)
           for ct = 1:length(Loops)
               Loops(ct).Nominal = Index;
           end
           this.dataevent('all')
       else
           error(message('Control:compDesignTask:errNominalIndexOutOfRange',length(Plant.getP)))
       end
       end  % setNominalModelIndex
       
        %----------------------------------------
       function setconfig(this,Design)
       %SETCONFIG  Sets the loop configuration to one of the predefined choices.
       %
       %   L.SETCONFIG(Design)
       
       %   Author(s): P. Gahinet
       Plant = this.Plant;
       % New components should be initialized when data is already loaded
       InitFlag = ~isempty(Plant); 
       ConfigID = Design.Configuration;
       
       % Delete listeners
       if ishandle(this.Listeners.Tuned)
           delete(this.Listeners.Tuned)
       end
       
       % I/O names
       this.Input = Design.Input;
       this.Output = Design.Output;
       
       % Create compensators
       nC = length(Design.Tuned);
       LocalCreateComps(this,nC,InitFlag);
       for ct=1:nC
          Cid = Design.Tuned{ct};
          this.C(ct).Identifier = Cid;
       end
       
       if ConfigID>0
          % Built-in loop configurations
          if isequal(Plant,[]) || getconfig(this.Plant)<1
             % Switch plant representation
             Plant = sisodata.DistributedPlant;
             % Listener for change in open/closed loop connectivity
             this.Listeners.Fixed = addlistener(Plant,'LoopStatus',...
                   'PostSet',@(es,ed) LocalResetClosedLoop(es,ed,this));
             this.Plant = Plant;
          end
          
          % Set plant configuration
          Plant.setconfig(ConfigID,Design.FeedbackSign);
          
       else
          % Specifying augmented plant P directly
          if isequal(Plant,[]) || getconfig(this.Plant)>0
             % Switch plant representation
             Plant = sisodata.LumpedPlant;
             Plant.Configuration = ConfigID;
             % Listener for change in loop connectivity
             this.Listeners.Fixed = addlistener(Plant,'P',...
                'PostSet',{@LocalChangeConfig this});
             this.Plant = Plant;
          end
          Plant.nLoop = nC;
          
       end
       
       % Build Open Loops
       nL = length(Design.Loops);
       delete(this.L);
       this.L = [];
       
       if isequal(nL,0)
           this.Listeners.Tuned = [];
       else
           for ct=1:nL
               TLoops(ct) = sisodata.TunedLoop;
           end
           this.L = TLoops;
       
           % Listeners to compensator (@tunedmodel) properties
           L = addlistener(this.L,findprop(this.L(1),'LoopStatus'),...
               'PostSet',@(es,ed) LocalChangeOpenLoopConfig(this,ed));
           this.Listeners.Tuned = L;
       end
       end  % setconfig
       
       % RE: To complete update, caller should 
       %     1) Issue ConfigChanged event (after data import)
       %     2) Invoke LoopData.dataevent('all') to update derived data and plots.
       
       %-------------------------Listeners-------------------------
       

        %----------------------------------------
       function store(this,Name)
       % Stores designs in design history.
       
       %   Author(s): P. Gahinet
       CurrentDesign = exportdesign(this);
       CurrentDesign.Name = Name;
       
       % Tag each component with the "store" name
       fNames = CurrentDesign.Fixed;
       for ct=1:length(fNames)
          CurrentDesign.(fNames{ct}).Name = sprintf('%s_%s',Name,fNames{ct});
       end
       tNames = CurrentDesign.Tuned;
       for ct=1:length(tNames)
          CurrentDesign.(tNames{ct}).Name = sprintf('%s_%s',Name,tNames{ct});
       end
       
       % Update design history
       ind = find(strcmpi(Name,get(this.History,{'Name'})));
       if isempty(ind)
           this.History = [this.History; CurrentDesign];
       else
           this.History = ...
              [this.History(1:ind-1); CurrentDesign; this.History(ind+1:end)];
       end
       
       end  % store
       
end  % public methods 

end  % classdef

function valueStored = LocalSetValue(this, ProposedValue)

valueStored = ProposedValue(:);
end  % LocalSetValue

function LocalCheckFRDConsistency(FRDList)
% Checks all FRD models have the same frequency grid
sys1 = FRDList{1};
freqs = sys1.Frequency;
tunits = sys1.TimeUnit;
funits = sys1.FrequencyUnit;
for j=2:length(FRDList)
   sysj = FRDList{j};
   cf = funitconv(sysj.FrequencyUnit,funits,tunits);
   if ~FRDModel.isSameFrequencyGrid(freqs,cf*sysj.Frequency)
      ctrlMsgUtils.error('Control:ltiobject:mrgfreq1')
   end
end
end  % LocalCheckFRDConsistency


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckFixedModelData %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Data = LocalCheckFixedModelData(Data,Component)
% Checks model data for plant, sensor, prefilter, and compensator.

% Check model class
sys = Data.Value;
if isa(sys,'idfrd')
   sys = frd(sys);
elseif ~isa(sys,'frd')
   if ~isreal(sys)
      ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck03',Component)
   elseif isa(sys,'idlti')
      % IDMODEL support
      % Check the number of inputs to the model
      nu = size(sys,2);
      if nu > 0
         % If the model is not a time series extract the
         % model from the input channels to output channels.
         sys = zpk(sys);
      else
         % If the model is a time series model error out.
         ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck04',Component)
      end
   elseif isnumeric(sys)
      % Double
      sys = zpk(sys);
   end
end

% Check dimensions
if any(iosize(sys)~=1)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck06',Component)
end
sizes = size(sys);
if prod(sizes(3:end)) ~= max(sizes(3:end))
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck15',Component)
end

Data.Value = sys;
end  % LocalCheckFixedModelData


%%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckCompensatorModelData %
%%%%%%%%%%%%%%%%%%%%%%%
function Data = LocalCheckCompensatorModelData(Data,Component)
% Checks model data for plant, sensor, prefilter, and compensator.

% Check model class
sys = Data.Value;
if isa(sys,'frd')
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck02',Component)
elseif ~isreal(sys)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck03',Component)
elseif isa(sys,'idlti')
   % SITB support
   % Check the number of inputs to the model
   nu = size(sys,'nu');
   if nu > 0
      % If the model is not a time series extract the
      % model from the input channels to output channels.
      sys = zpk(sys);
   else
      % If the model is a time series model error out.
      ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck04',Component)
   end
elseif isnumeric(sys)
   % Double
   sys = zpk(sys);
end

% Check for delays
if hasdelay(sys),
   if sys.Ts,
      % Map delay times to poles at z=0 in discrete-time case
      sys = delay2z(sys);
   else
      ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck14',Component)
   end
end

% Check dimensions
sizes = size(sys);
if prod(sizes(3:end))~=1
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck05')
elseif any(sizes~=1)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck06',Component)
end

% Convert to zpk
sw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>
Data.Value = zpk(sys);
end  % LocalCheckCompensatorModelData




%%%%%%%%%%%%%%%
% LocalCheckP %
%%%%%%%%%%%%%%%
function P = LocalCheckP(P,nC)
% Checks model data for plant, sensor, prefilter, and compensator.

% Check model class
sys = P.Value;
if ~isa(sys,'ss')
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck07')
elseif ~isreal(sys)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck08')
end

% Check dimensions
sizes = size(sys);
if prod(sizes(3:end))~=1
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck05')
elseif any(sizes<=nC)
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck09',nC+1)
end
end  % LocalCheckP

   

%%%%%%%%%%%%%%%%%%%%%%%%
% LocalCheckSampleTime %
%%%%%%%%%%%%%%%%%%%%%%%%
function Ts = LocalCheckSampleTime(this,InitData)
% Checks sample time and time unit consistency

% Gather all models
nG = length(InitData.Fixed);
nC = length(InitData.Tuned);
AllModels = cell(nG+nC,1);
for ct=1:nG
   AllModels{ct} = InitData.(InitData.Fixed{ct}).Value;
end
for ct=1:nC
   C = InitData.(InitData.Tuned{ct}).Value;
   if isequal(C,[])
      C = this.C(ct).ss; % use current value
   end
   AllModels{nG+ct} = C;
end

% Reconcile plant/sensor/prefilter/compensator sample times and time units
% RE: The overall sample time is stored as this.Compensator.Ts
try
   [AllModels{1:nG+nC}] = matchSamplingTimeN(AllModels{:});
catch ME
   ctrlMsgUtils.error('Control:compDesignTask:LoopdataCheck11')
end
Ts = abs(AllModels{1}.Ts);
end  % LocalCheckSampleTime


function LocalDrawDiagram(LoopData)

% Find adequate name for new diagram
AllDiagrams = find_system('Type','block_diagram');
% name must be a valid function name
DiagramName = strrep(LoopData.Name,' ','_'); %remove  spaces
DiagramName = strrep(DiagramName,')',''); % Remove (
DiagramName = strrep(DiagramName,'(',''); % Remove )
if ~isvarname(DiagramName)
    DiagramName = 'untitled';
end
if ~isempty(AllDiagrams)
   %---Look first for an exact match
   ExactMatch = strmatch(DiagramName,AllDiagrams,'exact');
   if ~isempty(ExactMatch)
      DiagramName = sprintf('%s_',DiagramName);
      % Look for an available name of the form DiagramName_xxx
      UsedInds = strmatch(DiagramName,AllDiagrams);
      if ~isempty(UsedInds)
         %---Look for minimum available number to use
         UsedNames = strvcat(AllDiagrams{UsedInds});
         %---Weed out names that don't end in scalar values.
         strVals = real(UsedNames(:,length(DiagramName)+1:end));
         strVals(find(strVals(:,1)<48 | strVals(:,1)>57),:)=[];
         RealVals = zeros(size(strVals,1),1);
         for ctR=1:size(strVals,1),
            RealVals(ctR,1) = str2double(char(strVals(ctR,:)));
         end
         if ~isnan(RealVals),
            NextInd = setdiff(1:max(RealVals)+1,RealVals);
            NextInd = NextInd(1);
         else
            NextInd=1;
         end
      else
         NextInd=1;
      end % if/else isempty(UsedInds)
      DiagramName = sprintf('%s%d',DiagramName,NextInd);
   end % if ~isempty(ExactMatch)
end % if ~isempty(AllDiagrams)

%---Open New Simulink diagram
NewDiagram = new_system(DiagramName,'model');

% Write model data in workspace
NominalModelIdx = LoopData.Plant.getNominalModelIndex;
assignin('base',LoopData.Plant.G(1).Name,LoopData.Plant.G(1).Model(:,:,NominalModelIdx));
assignin('base',LoopData.Plant.G(2).Name,LoopData.Plant.G(2).Model(:,:,NominalModelIdx));
assignin('base',LoopData.C(2).Name,utCreateLTI(zpk(LoopData.C(2))));
assignin('base',LoopData.C(1).Name,utCreateLTI(zpk(LoopData.C(1))));

%---Open CSTBLOCKS, if not already open
% @todo update the usage of edit-time filter filterOutInactiveVariantSubsystemChoices()
% instead use the post-compile filter activeVariants() - g2603738
BlockOpenFlag = find_system('MatchFilter',@Simulink.match.internal.filterOutInactiveVariantSubsystemChoices,  'Name', 'cstblocks' ); % look only inside active choice of VSS
if isempty(BlockOpenFlag)
   load_system('cstblocks');
end

switch LoopData.getconfig
    case {1,2,3,4}
        CompBlock = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
        set_param(CompBlock,'MaskValueString',[LoopData.C(1).Name,'|[]']);
        InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
        OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
        SumBlock = add_block('built-in/Sum',[DiagramName,'/Sum']);
        PlantBlock = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
        set_param(PlantBlock,'MaskValueString',[LoopData.Plant.G(1).Name,'|[]']);
        SensorBlock = add_block('cstblocks/LTI System',[DiagramName,'/Sensor Dynamics']);
        set_param(SensorBlock,'MaskValueString',[LoopData.Plant.G(2).Name,'|[]']);
        FilterBlock = add_block('cstblocks/LTI System',[DiagramName,'/Feed Forward']);
        set_param(FilterBlock,'MaskValueString',[LoopData.C(2).Name,'|[]']);
    case 5
        assignin('base',LoopData.Plant.G(3).Name,LoopData.Plant.G(3).Model(:,:,NominalModelIdx));
        CompBlock = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
        set_param(CompBlock,'MaskValueString',[LoopData.C(1).Name,'|[]']);
        FilterBlock = add_block('cstblocks/LTI System',[DiagramName,'/Feed Forward']);
        set_param(FilterBlock,'MaskValueString',[LoopData.C(2).Name,'|[]']);
        InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
        InBlock2 = add_block('built-in/SignalGenerator',[DiagramName,'/Input2']);
        OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
        SumBlock = add_block('built-in/Sum',[DiagramName,'/Sum']);
        PlantBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
        set_param(PlantBlock1,'MaskValueString',[LoopData.Plant.G(1).Name,'|[]']);
        PlantBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Plant2']);
        set_param(PlantBlock2,'MaskValueString',[LoopData.Plant.G(2).Name,'|[]']);
        DisturbanceBlock = add_block('cstblocks/LTI System',[DiagramName,'/Disturbance Dynamics']);
        set_param(DisturbanceBlock,'MaskValueString',[LoopData.Plant.G(3).Name,'|[]']);
    case 6
        assignin('base',LoopData.Plant.G(3).Name,LoopData.Plant.G(3).Model(:,:,NominalModelIdx));
        assignin('base',LoopData.Plant.G(4).Name,LoopData.Plant.G(4).Model(:,:,NominalModelIdx));
        assignin('base',LoopData.C(3).Name,utCreateLTI(zpk(LoopData.C(3))));
        CompBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Compensator']);
        set_param(CompBlock1,'MaskValueString',[LoopData.C(1).Name,'|[]']);
        CompBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Compensator2']);
        set_param(CompBlock2,'MaskValueString',[LoopData.C(2).Name,'|[]']);
        FilterBlock= add_block('cstblocks/LTI System',[DiagramName,'/Prefilter']);
        set_param(FilterBlock,'MaskValueString',[LoopData.C(3).Name,'|[]']);
        InBlock = add_block('built-in/SignalGenerator',[DiagramName,'/Input']);
        OutBlock = add_block('built-in/Scope',[DiagramName,'/Output']);
        SumBlock = add_block('built-in/Sum',[DiagramName,'/Sum']);
        PlantBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Plant']);
        set_param(PlantBlock1,'MaskValueString',[LoopData.Plant.G(1).Name,'|[]']);
        PlantBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Plant2']);
        set_param(PlantBlock2,'MaskValueString',[LoopData.Plant.G(2).Name,'|[]']);
        SensorBlock1 = add_block('cstblocks/LTI System',[DiagramName,'/Sensor1']);
        set_param(SensorBlock1,'MaskValueString',[LoopData.Plant.G(3).Name,'|[]']);
        SensorBlock2 = add_block('cstblocks/LTI System',[DiagramName,'/Sensor2']);
        set_param(SensorBlock2,'MaskValueString',[LoopData.Plant.G(4).Name,'|[]']);
end

%---Close CSTBLOCKS, if it wasn't open before
if isempty(BlockOpenFlag),
   close_system('cstblocks')
end

if (LoopData.Plant.LoopSign(1)>0)
    SumStr='++';
else
    SumStr='+-';
end
set_param(SumBlock,'Inputs',SumStr)


if ((LoopData.getconfig~= 5) && (LoopData.getconfig~= 6))
    set_param(NewDiagram,'Location',[70, 200, 560, 420])
    set_param(SensorBlock,'Orientation','left');
end

open_system(NewDiagram)

% Diagram topology depends on loop configuration
switch LoopData.getconfig
    case 1 % Forward
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
    case 2 % Feedback
        set_param(SumBlock,'Position',[165, 42, 195, 73])
        set_param(OutBlock,'Position',[440, 45, 465, 75])
        set_param(InBlock,'Position',[15, 35, 45, 65])
        set_param(PlantBlock,'Position',[255, 42, 320, 78])
        set_param(SensorBlock,'Position',[310, 112, 375, 148])
        set_param(CompBlock,'Position',[200, 112, 265, 148],'Orientation','left')
        set_param(FilterBlock,'Position',[65, 32, 130, 68])
        LinePos=[{[305 130;270 130]};
            {[200 60;250 60]};
            {[195 130;150 130;150 65;160 65]};
            {[50 50;60 50]};
            {[135 50;160 50;]};
            {[325 60; 435 60]};
            {[400 60; 400 130; 380 130]}];
    case 3 % Filter in the Feedforward path
        set_param(SumBlock,'Position',[155 62 185 93])
        set_param(OutBlock,'Position',[485 60 510 90])
        set_param(InBlock,'Position',[15 55 45 85])
        set_param(PlantBlock,'Position',[370 57 435 93])
        set_param(SensorBlock,'Position',[285 137 350 173])
        set_param(CompBlock,'Position',[210 62 275 98])
        set_param(FilterBlock,'Position',[85 12 150 48])
        SumBlock2 = add_block('built-in/Sum',[DiagramName,'/Sum2'],'Position',[310 57 340 88],'Inputs','++');
        LinePos={[155 30;295 30;295 65;305 65] ; ...
            [50 70;60 70;60 30;80 30];...
            [60 70;150 70];...
            [280 155;130 155;130 85;150 85];...
            [190 80;205 80];...
            [280 80;305 80];...
            [345 75;365 75];...
            [440 75;455 75;455 155;355 155];...
            [455 75;480 75]};
    case 4 %  Filter in the Feedback path
        set_param(SumBlock,'Position',[80 37 110 68])
        set_param(OutBlock,'Position',[450 50 475 80])
        set_param(InBlock,'Position',[15 30 45 60])
        set_param(PlantBlock,'Position',[315 47 380 83])
        set_param(SensorBlock,'Position',[310 147 375 183])
        set_param(CompBlock,'Position',[135 37 200 73])
        set_param(FilterBlock,'Position',[187 105 253 145],'Orientation','up')
        if LoopData.Plant.LoopSign(2)>0,
            SumStr2='++';
        else
            SumStr2='+-';
        end
        SumBlock2 = add_block('built-in/Sum',[DiagramName,'/Sum2'],...
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

    case 5
        set_param(InBlock,'Position',[80 200 110 230]);
        set_param(FilterBlock,'Position',[145 197 205 233 ]);
        set_param(SumBlock,'Position',[245 207 295 243]);
        set_param(CompBlock,'Position',[340 207 400 243]);
        set_param(PlantBlock1,'Position',[490 207 550 243 ]);
        set_param(PlantBlock2,'Position',[490 287 550 323]);
        set_param(DisturbanceBlock,'Position',[475 142 535 178]);
        set_param(OutBlock,'Position',[840 179 870 211]);
        set_param(InBlock2,'Position',[375 145 405 175]);
        SumBlock2 = add_block('built-in/Sum',[DiagramName,'/Sum2'],'Position',[600 129  665 256],'Inputs','++');
        SumBlock3 = add_block('built-in/Sum',[DiagramName,'/Sum3'],'Position',[660 345 680 365],'IconShape','Round','orientation','down','Inputs','|-+');
        LinePos = {[115 215;140 215];[210 215;240 215];[670 370;230 370;230 235;240 235];...
           [300 225;335 225];[408 225;485 225];[420 225;420 305;485 305];...
           [540 160;595 160];[555 225;595 225];...
           [410 160;470 160];...
           [750 195;835 195];...
           [555 305;670 305;670 340];...
           [750 195;750 355;685 355];...
           [670 195;750 195]}; 
    case 6
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
        if LoopData.Plant.LoopSign(2)>0,
            SumStr2='++';
        else
            SumStr2='+-';
        end
        SumBlock2 = add_block('built-in/Sum',[DiagramName,'/Sum2'],'Position',[430 217 480 253],'Inputs',SumStr2);
        LinePos = {[115 215;135 215];[205 215;240 215];[750 415;205 415;205 235;240 235];[685 235;710 235];[815 235;855 235];...
           [300 225;335 225];[405 225;425 225];[560 325;405 325;405 245;425 245];...
           [485 235;515 235];[585 235;615 235];[710 235;745 235];[855 235;915 235];...
           [710 235;710 325;630 325];[855 235;855 415;820 415]};
       
end


for ctLine = 1:length(LinePos)
   add_line(NewDiagram,LinePos{ctLine});
end

open_system(NewDiagram);
end  % LocalDrawDiagram





function Design = LocalConfig0Setup(LoopData)
% Fixed and tuned components
Fixed = {'P'};
TunedNames = get(LoopData.C,{'Identifier'});
LoopNames = get(LoopData.L,{'Identifier'});
Design = sisodata.design(Fixed,TunedNames,LoopNames,0);

% Add instance prop for each new name
Design.P.Value = utCreateLTI(getP(LoopData.Plant));

nC = length(TunedNames);
for ct=1:nC
   tn = TunedNames{ct};
   Design.(tn) = save(LoopData.C(ct));
end

nC = length(LoopNames);
for ct=1:nC
   tn = LoopNames{ct};
   Design.(tn) = save(LoopData.L(ct));
end
end  % LocalConfig0Setup

function Model = localSetDefaultIOName(Model)
set(Model,'InputName',sprintf('Input'),...
    'OutputName',sprintf('Output'));
end
function LocalChangeOpenLoopConfig(this,eventdata)
% Callback when changing the open/closed status of other loops 
% for a given loop
L = eventdata.AffectedObject;
idxC = find(L==this.L);
% Clear dependent data
this.reset('ol',idxC)
% Update dependency info and propagate to editors
this.send('ConfigChanged')  
% Send event to trigger update
% RE: Not enough to issue dataevent('gain',idxC) to update 
%     the editors for the loop #idxC. Indeed, changing the
%     status of outer loops may alter the number of plant and 
%     closed-loop poles seen by loop #idxC, resulting in errors
%     in the root locus editor
this.dataevent('all')

end  % LocalChangeOpenLoopConfig


function LocalResetClosedLoop(eventsrc,eventdata,this)
% Clear augmented plant for closed-loop sim
this.reset('cl')

end  % LocalResetClosedLoop


function LocalChangeConfig(eventsrc,eventdata,this)
end  % LocalChangeConfig

% Responds to change in loop topology
% Rebuild dependency lists for each open loop 
% REVISIT For config=0 (SCD case)plant cannot change during session
% this.Plant.oloopdepend(this.L)
% Notify peers (so that editors can rebuild their dependency lists)
% this.send('ConfigChanged')  
% % Send event to trigger global update
% this.dataevent('all')


%---------------- Local Functions -------------------------

function LocalCreateComps(this,nC,InitFlag)
% Adjust the lists of fixed and tuned models
nC0 = length(this.C);
if nC0>nC,
   delete(this.C(nC+1:nC0));
   this.C = this.C(1:nC);
else
   for ct=nC0+1:nC
      % Compensator model
      C = sisodata.TunedZPK;
      C.SSData = ltipack.ssdata;
      this.C = [this.C ; C];
   end
end
end  % LocalCreateComps

