classdef design < dynamicprops & matlab.mixin.SetGet
%sisodata.design class
%    sisodata.design properties:
%       Name - Property is of type 'ustring'  
%       Configuration - Property is of type 'double'  (read only) 
%       Description - Property is of type 'ustring'  
%       FeedbackSign - Property is of type 'MATLAB array'  
%       Input - Property is of type 'string vector'  
%       Output - Property is of type 'string vector'  
%       LoopView - Property is of type 'MATLAB array'  (read only) 
%       Fixed - Property is of type 'string vector'  (read only) 
%       Tuned - Property is of type 'string vector'  (read only) 
%       Loops - Property is of type 'string vector'  (read only) 
%
%    sisodata.design methods:
%       display - method for @design class
%       getLoopView -  Returns the loop view property of the Design object
%       getTs -  Get sampling time for @design object
%       loopviews -  Updates list of viewable loop transfer functions for each built-in configuration.
%       mapto -  Transfer settings when changing configuration.
%       setConfig -  Sets the configuration of the design object
%       setLoopView -  Sets the loop view property of the Design object
%       snap -  Takes snapshot of @design object.
%       utExportStructure -  Map old sessions into new


properties 
    %NAME Property is of type 'ustring' 
    Name = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = 'Design snapshot.';
    %FEEDBACKSIGN Property is of type 'MATLAB array' 
    FeedbackSign = [];
    %INPUT Property is of type 'string vector' 
    Input = cell(0,1);
    %OUTPUT Property is of type 'string vector' 
    Output = cell(0,1);
end

properties (Access=protected)
    %VERSION Property is of type 'double' 
    Version = 0.0;
end

properties (Hidden)
    %NOMINALMODELINDEX Property is of type 'double'  (hidden)
    NominalModelIndex = 1;
end

properties (SetAccess=protected)
    %CONFIGURATION Property is of type 'double'  (read only)
    Configuration = 0;
    %LOOPVIEW Property is of type 'MATLAB array'  (read only)
    LoopView = [];
    %FIXED Property is of type 'string vector'  (read only)
    Fixed = cell(0,1);
    %TUNED Property is of type 'string vector'  (read only)
    Tuned = cell(0,1);
    %LOOPS Property is of type 'string vector'  (read only)
    Loops = cell(0,1);
end


    methods  % constructor block
        function this = design(FixedNames,TunedNames,LoopNames,config)
        % Constructor for @design class
        
        %   Author(s): P. Gahinet
        
        
                
        % Version 1 for 2006a
        % this.Version = 1.0;
        % Version 2 for 2010b (multimodel support)
        this.Version = 2.0;
        
        if nargin==0
           % load call
           return
        end
        
        if isequal(nargin,4)
            this.Configuration = config;
        end
        
        % Fixed and tuned components
        this.Fixed = FixedNames(:);
        this.Tuned = TunedNames(:);
        this.Loops = LoopNames(:);
        
        % Add instance prop for each new name
        initsys = zpk(1);
        
        for ct=1:length(FixedNames)
           fn = FixedNames{ct};
           try 
              addprop(this,fn);
           catch ME
               ctrlMsgUtils.error('Control:compDesignTask:DesignSnapshot1')
           end
           fm = sisodata.system;
           fm.Name = fn;
           fm.Value = initsys;
           this.(fn) = fm;
        end
        
        nC = length(TunedNames);
        for ct=1:nC
           tn = TunedNames{ct};
           try 
              addprop(this,tn);
           catch
               ctrlMsgUtils.error('Control:compDesignTask:DesignSnapshot2')
           end
           if ~isequal(config,0)
               tm = sisodata.TunedZPKSnapshot;
               tm.Name = tn;
               tm.Value = initsys;
               this.(tn) = tm;
           end
        end
        
        
        nC = length(LoopNames);
        for ct=1:nC
           tn = LoopNames{ct};
           try 
              addprop(this,tn);
           catch
               ctrlMsgUtils.error('Control:compDesignTask:DesignSnapshot3')
           end
           tm = sisodata.TunedLoopSnapshot;
           % Revisit: Determine what other fields need to added here
           tm.Name = tn;
           tm.View = {'bode'};
           this.(tn) = tm;
        end
        end  % design
        
    end  % constructor block

    methods 
        function obj = set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function obj = set.Configuration(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Configuration')
        value = double(value); %  convert to double
        obj.Configuration = value;
        end

        function obj = set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function obj = set.Input(obj,value)
            % DataType = 'string vector'
        % no cell string checks yet'
        obj.Input = value;
        end

        function obj = set.Output(obj,value)
            % DataType = 'string vector'
        % no cell string checks yet'
        obj.Output = value;
        end

        function obj = set.Fixed(obj,value)
            % DataType = 'string vector'
        % no cell string checks yet'
        obj.Fixed = value;
        end

        function obj = set.Tuned(obj,value)
            % DataType = 'string vector'
        % no cell string checks yet'
        obj.Tuned = value;
        end

        function obj = set.Loops(obj,value)
            % DataType = 'string vector'
        % no cell string checks yet'
        obj.Loops = value;
        end

        function obj = set.NominalModelIndex(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','NominalModelIndex')
        value = double(value); %  convert to double
        obj.NominalModelIndex = value;
        end

        function obj = set.Version(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Version')
        value = double(value); %  convert to double
        obj.Version = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function display(this)
       % Display method for @design class
       
       disp(rmfield(get(this),{'Fixed','Tuned','Loops'}))
       end  % display
       
       
        %----------------------------------------
       function Ts = getTs(this)
       % Get sampling time for @design object
       % Returns the sampling time from first tuned model
       
       
       Ts = this.(this.Tuned{1}).getProperty('Ts');
       
       end  % getTs
       
        %----------------------------------------
       function LoopTF = loopviews(this,Configuration)
       % Updates list of viewable loop transfer functions for each built-in configuration.
       
       %   Author(s): P. Gahinet
       
       % UDDREVISIT: private static
       inames = this.Input;
       onames = this.Output;
       
       switch Configuration
          case {1,2,3,4}
             % Single-loop configurations
             for ct=10:-1:1
                LoopTF(ct,1) = sisodata.looptransfer;
             end
             % Closed-loop responses
             LoopTF(1).Type = 'T';
             LoopTF(1).Index = {1 1};
             LoopTF(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{1})); % r to y
             LoopTF(1).ExportAs = 'T_r2y';
             LoopTF(1).Style = 'b';
             LoopTF(2).Type = 'T';
             LoopTF(2).Index = {2 1};
             LoopTF(2).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{2})); % r to u
             LoopTF(2).ExportAs = 'T_r2u';
             LoopTF(2).Style = 'g';
             LoopTF(3).Type = 'T';
             LoopTF(3).Index = {1 3};
             LoopTF(3).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{3},onames{1})); % du to y
             LoopTF(3).ExportAs = 'S_in';
             LoopTF(3).Style = 'r';
             LoopTF(4).Type = 'T';
             LoopTF(4).Index = {1 2};
             LoopTF(4).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{2},onames{1})); % dy to y
             LoopTF(4).ExportAs = 'S_out';
             LoopTF(4).Style = 'c';
             LoopTF(5).Type = 'T';
             LoopTF(5).Index = {1 4};
             LoopTF(5).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{4},onames{1})); % n to y
             LoopTF(5).ExportAs = 'S_noise';
             LoopTF(5).Style = 'm';
             % Open-loop responses
             LoopTF(6).Type = 'L';
             LoopTF(6).Index = 1;
             LoopTF(6).Description = getString(message('Control:compDesignTask:strOpenLoopL','L'));
             LoopTF(6).ExportAs = 'L';
             LoopTF(6).Style = 'y';
             LoopTF(7).Type = 'C';
             LoopTF(7).Index = 1;
             LoopTF(7).Style = 'r--';
             LoopTF(8).Type = 'C';
             LoopTF(8).Index = 2;
             switch Configuration
                case {1 2}
                   LoopTF(7).Description = getString(message('Control:compDesignTask:strCompensatorC','C'));
                   LoopTF(8).Description = getString(message('Control:compDesignTask:strPrefilterF','F'));
                case 3
                   LoopTF(7).Description = getString(message('Control:compDesignTask:strCompensatorC','C'));
                   LoopTF(8).Description = getString(message('Control:compDesignTask:strFeedforwardF','F'));
                case 4
                   LoopTF(7).Description = getString(message('Control:compDesignTask:strPrimaryCompensatorC','C1'));
                   LoopTF(8).Description = getString(message('Control:compDesignTask:strMinorLoopCompensatorC','C2'));
             end
             LoopTF(8).Style = 'g--';
             LoopTF(9).Type = 'G';
             LoopTF(9).Index = 1;
             LoopTF(9).Description = getString(message('Control:compDesignTask:strPlantG','G'));
             LoopTF(9).Style = 'b--';
             LoopTF(10).Type = 'G';
             LoopTF(10).Index = 2;
             LoopTF(10).Description = getString(message('Control:compDesignTask:strSensorH','H'));
             LoopTF(10).Style = 'm--';
             
           case 5
             for ct=8:-1:1
                LoopTF(ct,1) = sisodata.looptransfer;
             end
             LoopTF(1).Type = 'T';
             LoopTF(1).Index = {1 1};
             LoopTF(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{1})); % r to y
             LoopTF(1).ExportAs = 'T_r2y';
             LoopTF(1).Style = 'b';
             
             LoopTF(2).Type = 'T';
             LoopTF(2).Index = {2 1};
             LoopTF(2).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{2})); % r to u
             LoopTF(2).ExportAs = 'T_r2u';
             LoopTF(2).Style = 'g';
             
             LoopTF(3).Type = 'L';
             LoopTF(3).Index = 1;
             LoopTF(3).Description = getString(message('Control:compDesignTask:strOpenLoopL','L'));
             LoopTF(3).ExportAs = 'L';
             LoopTF(3).Style = 'r';
             
             LoopTF(4).Type = 'C';
             LoopTF(4).Index = 1;
             LoopTF(4).Description =  getString(message('Control:compDesignTask:strCompensatorC','C'));
             LoopTF(4).Style = 'c';
             
             LoopTF(5).Type = 'C';
             LoopTF(5).Index = 2;
             LoopTF(5).Description = getString(message('Control:compDesignTask:strPrefilterF','F'));
             LoopTF(5).Style = 'm';
             
             LoopTF(6).Type = 'G';
             LoopTF(6).Index = 1;
             LoopTF(6).Description = getString(message('Control:compDesignTask:strPlantG','G1'));
             LoopTF(6).Style = 'y';
             
             LoopTF(7).Type = 'G';
             LoopTF(7).Index = 2;
             LoopTF(7).Description = getString(message('Control:compDesignTask:strPlantG','G2'));
             LoopTF(7).Style = 'b--';
             
             LoopTF(8).Type = 'G';
             LoopTF(8).Index = 3;
             LoopTF(8).Description = getString(message('Control:compDesignTask:strDisturbanceModelGd','Gd'));
             LoopTF(8).Style = 'g--';
       
           
           case 6
             for ct=10:-1:1
                 LoopTF(ct,1) = sisodata.looptransfer;
             end
             LoopTF(1).Type = 'T';
             LoopTF(1).Index = {4 1};
             LoopTF(1).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{4})); % r to y
             LoopTF(1).ExportAs = 'T_r12y1';
             LoopTF(1).Style = 'b';
             
             LoopTF(2).Type = 'T';
             LoopTF(2).Index = {2 1};
             LoopTF(2).Description = getString(message('Control:compDesignTask:strClosedLoopFromTo',inames{1},onames{3})); % r to u
             LoopTF(2).ExportAs = 'T_r12u2';
             LoopTF(2).Style = 'g';
             
             LoopTF(3).Type = 'L';
             LoopTF(3).Index = 1;
             LoopTF(3).Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf','C1'));
             LoopTF(3).ExportAs = 'L';
             LoopTF(3).Style = 'r';
             
             LoopTF(4).Type = 'L';
             LoopTF(4).Index = 2;
             LoopTF(4).Description = getString(message('Control:compDesignTask:strOpenLoopOutputOf','C2'));
             LoopTF(4).ExportAs = 'L';
             LoopTF(4).Style = 'c';
             
             LoopTF(5).Type = 'C';
             LoopTF(5).Index = 1;
             LoopTF(5).Description =  getString(message('Control:compDesignTask:strCompensatorC','C1'));
             LoopTF(5).Style = 'm';
             
             LoopTF(6).Type = 'C';
             LoopTF(6).Index = 2;
             LoopTF(6).Description =  getString(message('Control:compDesignTask:strCompensatorC','C2'));
             LoopTF(6).Style = 'y';
             
             LoopTF(7).Type = 'C';
             LoopTF(7).Index = 3;
             LoopTF(7).Description = getString(message('Control:compDesignTask:strPrefilterF','F'));
             LoopTF(7).Style = 'b--';
             
             LoopTF(7).Type = 'G';
             LoopTF(7).Index = 1;
             LoopTF(7).Description = getString(message('Control:compDesignTask:strPlantG','G1'));
             LoopTF(7).Style = 'g--';
             
             LoopTF(8).Type = 'G';
             LoopTF(8).Index = 2;
             LoopTF(8).Description = getString(message('Control:compDesignTask:strPlantG','G2'));
             LoopTF(8).Style = 'r--';
             
             LoopTF(9).Type = 'G';
             LoopTF(9).Index = 3;
             LoopTF(9).Description = getString(message('Control:compDesignTask:strSensorH','H1'));
             LoopTF(9).Style = 'c--';
             
             LoopTF(10).Type = 'G';
             LoopTF(10).Index = 4;
             LoopTF(10).Description = getString(message('Control:compDesignTask:strSensorH','H2'));
             LoopTF(10).Style = 'm--';
       
       
       end
       
       end  % loopviews
       
        %----------------------------------------
       function init2 = mapto(init1,init2,currentData)
       % Transfer settings when changing configuration.
       % 
       %   Returns logical vector MAPPEDC indicating which 
       %   tuned models in INIT2 have been inherited from
       %   INIT1.
       
       init2.Name = init1.Name;
       fn = fieldnames(currentData);
       
       % Transfer feeback signs
       if length(init1.FeedbackSign)==length(init2.FeedbackSign)
          init2.FeedbackSign = init1.FeedbackSign;
       end
       
       % Transfer data for plant components with the same identifier
       % otherwise try reusing current value
       [junk,ia] = intersect(init2.Fixed,fn);
       % for ct=1:length(ia)
       %    G = init2.Fixed{ia(ct)};
       %    set(init2.(G), currentData.(G));
       % end
       [junk,ia] = intersect(init2.Fixed,init1.Fixed);
       for ct=1:length(ia)
          G = init2.Fixed{ia(ct)};
          init2.(G) = init1.(G);
       end
       
       % Transfer data for compensators with the same identifier,
       % otherwise try reusing current value
       [junk,ia] = intersect(init2.Tuned,fn);
       % for ct=1:length(ia)
       %    C = init2.Tuned{ia(ct)};
       %    set(init2.(C), currentData.(C));
       % end
       [junk,ia] = intersect(init2.Tuned,init1.Tuned);
       for ct=1:length(ia)
          C = init2.Tuned{ia(ct)};
          init2.(C) = init1.(C);
       end
       
       
       end  % mapto
       
        %----------------------------------------
       function this = setConfig(this,Config)
       %setConfig  Sets the configuration of the design object
       
       
       this.Configuration = Config;
       end  % setConfig
       
        %----------------------------------------
       function LoopView = getLoopView(this)
       % Returns the loop view property of the Design object
       LoopView = this.LoopView;
       end % getLoopView

        %----------------------------------------
       function this = setLoopView(this,LoopView)
       % Sets the loop view property of the Design object
       
       
       this.LoopView = LoopView;
       end  % setLoopView
       
        %----------------------------------------
       function s = snap(this)
       % Takes snapshot of @design object.
       %
       %   Returns a structure and performs deep copies.
       
       s = get(this);
       
       % Copy @system and @compensator objects
       Components = [this.Fixed ; this.Tuned];
       for ct=1:length(Components)
          H = Components{ct};
          s.(H) = get(this.(H));
       end
       
       end  % snap
       
        %----------------------------------------
       function [NewArch, NewResp, RespIdxMapping, LoopIdxMapping, BlockIdxMapping] = utExportStructure(this, ExportAsDesign, varargin)
       % Map old sessions into new
       
       
       RespIdxMapping = [];
       LoopIdxMapping = [];
       BlockIdxMapping = [];
       if ExportAsDesign
           for ct = 1:numel(this.Tuned)
               NewArch.(this.Tuned{ct}) = this.(this.Tuned{ct}).Value;
           end
           NewResp = [];
       else
           NewResp = repmat(struct('Definition',[]),0,1);
           if this.Configuration == 0
               NewArch.Name = this.Name;
               NewArch.NominalIndex = 1;
               NewArch.Config = this.Configuration;
               NewArch.TimeUnits = 'seconds';
               TB = arrayfun(@(x)this.(x{:}).Name,this.Tuned,'UniformOutput',false);
               NewArch.Data = slTuner(this.Name, TB);
               if all(isa(varargin{:},'linearize.IOPoint'))
                   NewArch.Data.addPoint(varargin{:});
               end
               NewArch.Data.Ts = this.getTs;
               IDList = {NewArch.Data.getSLTunableBlocks.Name};
               PathList = {NewArch.Data.getSLTunableBlocks.BlockPath};
               for ct = 1:numel(this.Tuned)
                   NewArch.TunedBlocks(ct) =  this.(this.Tuned{ct}).utExportStructure;
                   NewArch.TunedBlocks(ct).Identifier =  IDList{ismember(PathList,this.(this.Tuned{ct}).Name)};
                   NewArch.TunedBlocks(ct).Name =  IDList{ismember(PathList,this.(this.Tuned{ct}).Name)};
               end
               Points = getPoints(NewArch.Data);
               ExpandedPoints = getPointExpandedNames(NewArch.Data);
               for ct=1:numel(this.Input)
                   NewInputs(ct) = localGetPointName(this.Input{ct},Points, ExpandedPoints);
               end
               
               for ct=1:numel(this.Output)
                   NewOutputs(ct) = localGetPointName(this.Output{ct},Points, ExpandedPoints);
               end
               
               % Responses used for analysis plots
               LoopView = this.LoopView;
               for ct1=1:numel(LoopView)
                   if strcmpi(LoopView(ct1).Type,'T')
                       iIn = LoopView(ct1).Index{2};
                       iOut = LoopView(ct1).Index{1};
                       if ~isempty(NewInputs{iIn}) && ~isempty(NewOutputs{iOut})
                           Definition.Name = matlab.lang.makeValidName(sprintf('T_%s2%s',this.Input{iIn},this.Output{iOut}));
                           Definition.Description = '';
                           Definition.Input = NewInputs(iIn);
                           Definition.Output =  NewOutputs(iOut);
                           Definition.Openings = [];
                           Definition.Type = 'IOTransfer';
                           Definition.Models = NaN;
                           NewResp(end+1).Definition = Definition;
                           RespIdxMapping = [RespIdxMapping; ct1 numel(NewResp)];
                       end
                   elseif strcmpi(LoopView(ct1).Type,'C')
                       % Block plot - definition not needed. Cache mapping to
                       % load plots and design constraints
                       BlockIdxMapping = [BlockIdxMapping; [ct1 LoopView(ct1).Index]];
                       
                   end
               end
               ctCurrent = numel(NewResp);
               % Responses used for graphical editors
               for ct=1:numel(this.Loops)
                   Definition = this.(this.Loops{ct}).utExportStructure(NewInputs,NewOutputs);
                   if ~isempty(Definition)
                       NewResp(end+1).Definition = Definition;
                       RespIdxMapping = [RespIdxMapping; ct+ctCurrent numel(NewResp)];
                       LoopIdxMapping = [LoopIdxMapping; ct numel(NewResp)];
                   end
               end
               
               
           else
               
               DefaultSignals = varargin{1};
               NewArch.Name = sprintf('Feedback Configuration %d',this.Configuration);
               NewArch.NominalIndex = 1;
               NewArch.Config = this.Configuration;
               NewArch.TimeUnits = 'seconds';
               NewArch.LoopSign = this.FeedbackSign;
               
               
               Data = [this.Input(:); this.Output(:)];
               
               NewArch.SignalsWithID = [DefaultSignals,Data];
               
               
               for ct = 1:numel(this.Tuned)
                   NewArch.TunedBlocks(ct)=  this.(this.Tuned{ct}).utExportStructure;
                   NewArch.TunedBlocks(ct).Identifier = this.Tuned{ct};
               end
               
               for ct = 1:numel(this.Fixed)
                   NewArch.FixedBlocks(ct)=  this.(this.Fixed{ct}).utExportStructure;
                   NewArch.FixedBlocks(ct).Identifier = this.Fixed{ct};
               end
               
               %% Responses
               
               % Export the tuned loops. Each tuned loop gets converted to a
               % LoopTransfer or IOTransfer Response.
               
               % ResponseIdxMapping is CETMLoopViewIdx -> CSDResponseIdx
               % We need ResponseIdxMapping for analysis plots. The Response is an
               % index into loopviews.
               
               % LoopIdxMapping is CETMTunedLoopIdx -> CSDResponseIdx
               % We need LoopIdxMapping for graphical editors - EditedLoop is an
               % index into TunedLoops
               
               ExistingIOTransfers = [];
               for ct = 1:numel(this.Loops)
                   Definition = this.(this.Loops{ct}).utExportStructure(this.Input,this.Output);
                   NewResp(end+1).Definition = Definition;
                   LoopIdxMapping = [LoopIdxMapping; [ct numel(NewResp)]];
                   
                   if strcmpi(Definition.Type,'IOTransfer')
                       ExistingIOTransfers = [ExistingIOTransfers; NewResp(end)];
                       ExistingIOTransfers(end).Idx = numel(NewResp);
                   end
               end
               
               LoopTF = this.LoopView;
               for ct = 1:numel(LoopTF)
                   switch LoopTF(ct).Type
                       case 'G'
                       case 'C'
                           % Block plot - definition not needed. Cache mapping to
                           % load plots and design constraints
                           BlockIdxMapping = [BlockIdxMapping; [ct LoopTF(ct).Index]];
                       case 'L'
                           % getOpenLoop returns @ssdata or @frddata model
                           % Get openings if any
                           Definition = this.(this.Loops{LoopTF(ct).Index}).utExportStructure;
                           RespNames = arrayfun(@(x)NewResp(x).Definition.Name,1:numel(NewResp),'UniformOutput',false);
                           [b,idx] = ismember(Definition.Name,RespNames);
                           if b
                               % already exists
                               RespIdxMapping = [RespIdxMapping; [ct idx]];
                           else
                               NewResp(end+1).Definition = Definition;
                               RespIdxMapping = [RespIdxMapping; [ct numel(NewResp)]];
                           end
                       case 'T'
                           % Closed loop response
                           Definition.Name = LoopTF(ct).ExportAs;
                           Definition.Description = LoopTF(ct).Description;
                           Definition.Input = this.Input(LoopTF(ct).Index{2});
                           Definition.Output = this.Output(LoopTF(ct).Index{1});
                           Definition.Openings = [];
                           Definition.Type = 'IOTransfer';
                           Definition.Models = NaN;
                           NewResp(end+1).Definition = Definition;
                           RespIdxMapping = [RespIdxMapping; ct numel(NewResp)];
                           
                           for cte=1:numel(ExistingIOTransfers)
                               if strcmpi(ExistingIOTransfers(cte).Definition.Input,Definition.Input) && ...
                                       strcmpi(ExistingIOTransfers(cte).Definition.Output,Definition.Output)
                                   NewResp = NewResp(1:end-1);
                                   % Remap to already existing response
                                   RespIdxMapping(end,2) =  ExistingIOTransfers(cte).Idx ;
                               end
                           end
                       case 'Tss'
                           %                 % Entire system
                           %                 Definition.Name = LoopTF(ct).ExportAs;
                           %                 Definition.Description = LoopTF(ct).Description;
                           %                 Definition.Type = 'IOTransferEntireSystem';
                           %                 Definition.Models = NaN;
                           %                 NewResp(end+1).Definition = Definition;
                           %                 RespIdxMapping = [RespIdxMapping; ct numel(NewResp)];
                   end
               end
           end
       end
       end
       

end  % public methods 
end  % classdef

function NewPointName = localGetPointName(OldPoint, NewPoints, NewExpandedPoints)
NewPointName = [];
SubsystemPoint = strfind(OldPoint, ' (pt');

if isempty(SubsystemPoint)
    MIMOPoint = strfind(OldPoint, ' (ch');
else
    MIMOPoint = strfind(OldPoint, ',ch');
end

if isempty(MIMOPoint) && isempty(SubsystemPoint)
    idxNew = slLinearizer.resolveSignalID(OldPoint,NewPoints);
    NewPointName = NewPoints(idxNew);
elseif isempty(MIMOPoint) && ~isempty(SubsystemPoint)
    Point = strfind(OldPoint, ' (pt');
    TempInput = OldPoint(1:Point-1);
    PortNumber = OldPoint(Point+5);
    TempInput = strcat(TempInput,['/',PortNumber]);
    NewPointName = NewPoints(slLinearizer.resolveSignalID(TempInput,NewPoints));
elseif ~isempty(MIMOPoint) && isempty(SubsystemPoint)
    Point = strfind(OldPoint, ' (ch');
    TempInput = OldPoint(1:Point-1);
    PortNumber = mat2str(1);
    ChannelNumber = OldPoint(Point+5);
    TempInput = strcat(TempInput,['/',PortNumber,'(',ChannelNumber,')']);
    [Pt,Idx] = slLinearizer.resolveSignalID(TempInput,NewExpandedPoints);
    ii = 1;
    while ii<=numel(Idx)
        if strfind(NewExpandedPoints{Pt(ii)},Idx)
            NewPointName = NewExpandedPoints(Pt(ii));
            break;
        end
        ii=ii+1;
    end
else
    % MIMO subsystem
    Point = strfind(OldPoint, ' (pt');
    TempInput = OldPoint(1:Point-1);
    PortNumber = OldPoint(Point+5);
    Point = strfind(OldPoint, ',ch');
    ChannelNumber = OldPoint(Point+4);
    TempInput = strcat(TempInput,['/',PortNumber,'(',ChannelNumber,')']);
    [Pt,Idx] = slLinearizer.resolveSignalID(TempInput,NewExpandedPoints);
    ii = 1;
    while ii<=numel(Idx)
        if strfind(NewExpandedPoints{Pt(ii)},Idx)
            NewPointName = NewExpandedPoints(Pt(ii));
            break;
        end
        ii=ii+1;
    end
end
end
