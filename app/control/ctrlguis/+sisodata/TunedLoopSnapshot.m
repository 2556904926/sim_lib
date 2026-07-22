classdef TunedLoopSnapshot
%sisodata.TunedLoopSnapshot class
%    sisodata.TunedLoopSnapshot properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%       View - Property is of type 'MATLAB array'  
%
%    sisodata.TunedLoopSnapshot methods:
%       display - method for snapshot
%       getProperty -  Returns the property specified by PropName
%       setProperty -  Sets the property specified by PropName with PropValue
%       utExportStructure -  stores TunedLoop into a TunedLoopSnapshot
%       utRestoreTunedLoop -  Restores TunedLoop from a TunedLoopSnapshot
%       utStoreTunedLoop -  stores TunedLoop into a TunedLoopSnapshot


properties 
    %NAME Property is of type 'ustring' 
    Name = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
    %VIEW Property is of type 'MATLAB array' 
    View = [];
end

properties (Access=protected)
    %FEEDBACK Property is of type 'bool' 
    Feedback = false;
    %LOOPCONFIG Property is of type 'MATLAB array' 
    LoopConfig = [];
    %TUNEDLFTBLOCKS Property is of type 'MATLAB array' 
    TunedLFTBlocks = [];
    %TUNEDLFTSSDATA Property is of type 'MATLAB array' 
    TunedLFTSSData = [];
    %TUNEDFACTORS Property is of type 'MATLAB array' 
    TunedFactors = [];
    %CLOSEDLOOPIOS Property is of type 'MATLAB array' 
    ClosedLoopIOs = [];
    %VERSION Property is of type 'double' 
    Version = 1.0;
end


    methods 
        function obj = set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function obj = set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function obj = set.Feedback(obj,value)
            % DataType = 'bool'
        validateattributes(value,{'numeric','logical'}, {'scalar','nonnan'},'','Feedback')
        value = logical(value); %  convert to logical
        obj.Feedback = value;
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
       % Display method for snapshot
       
       
       this.get
       end  % display
       
        %----------------------------------------
       function Prop = getProperty(this,PropName)
       % Returns the property specified by PropName
       
       
       Prop = this.(PropName);
       end  % getProperty
       
        %----------------------------------------
       function this = setProperty(this,PropName,PropValue)
       % Sets the property specified by PropName with PropValue
       
       
       this.(PropName) = PropValue;
       end  % setLoopView
       
        %----------------------------------------
       function Response = utExportStructure(this,Input,Output)
       % stores TunedLoop into a TunedLoopSnapshot
       
       
       Response.Name = this.Name;
       Response.Description = this.Description;
       if isempty(this.LoopConfig)
           % Closed loop response
           if isempty(Input(this.ClosedLoopIOs(2))) || isempty(Output(this.ClosedLoopIOs(1)))
               Response = [];
           else
               Response.Input = Input(this.ClosedLoopIOs(2));
               Response.Output = Output(this.ClosedLoopIOs(1));
               Response.Openings = [];
               Response.Type = 'IOTransfer';
           end
       else
           Response.Location = this.LoopConfig.OpenLoop;
           Response.Openings = this.LoopConfig.LoopOpenings;
           Response.Type = 'LoopTransfer';
       end
       
       Response.Models = NaN;
       
       
       end  % utExportStructure
       
        %----------------------------------------
       function utRestoreTunedLoop(this,TunedLoop,LoopData);
       % Restores TunedLoop from a TunedLoopSnapshot
       
       
       
       TunedLoop.Name = this.Name;
       TunedLoop.Description = this.Description;
       TunedLoop.Feedback = this.Feedback;
       
       if this.Feedback
           TunedLoop.LoopConfig = this.LoopConfig;
           if isequal(getconfig(LoopData),0)
               C = LoopData.C;
               CompIDs = get(C,{'Identifier'});
               
               TunedFactors = [];
               for ct = 1:length(this.TunedFactors)
                   TunedFactors(ct) =  C(find(strcmp(this.TunedFactors{ct},CompIDs)));
               end
               TunedLoop.TunedFactors = TunedFactors;
               
               Blocks = [];
               for ct = 1:length(this.TunedLFTBlocks)
                   Blocks(ct) =  C(find(strcmp(this.TunedLFTBlocks{ct},CompIDs)));
               end
               TunedLoop.setTunedLFT(this.TunedLFTSSData, Blocks);
               TunedLoop.LoopConfig = this.LoopConfig;
           else
               TunedLoop.computeTunedLoop(LoopData)       
           end
       else
           C = LoopData.C;
           CompIDs = get(C,{'Identifier'});
       
           for ct = 1:length(this.TunedFactors)
               TunedFactors(ct) =  C(find(strcmp(this.TunedFactors{ct},CompIDs)));
           end
           TunedLoop.TunedFactors = TunedFactors;
           % Revisit
           TunedLoop.setTunedLFT(ltipack.ssdata([],zeros(0,1),zeros(1,0),1,[],LoopData.Ts),[]);
           TunedLoop.LoopConfig = this.LoopConfig;
       
           TunedLoop.ClosedLoopIO = this.ClosedLoopIOs;
       end
       
       
       end  % utRestoreTunedLoop
       
        %----------------------------------------
       function this = utStoreTunedLoop(this,TunedLoop);
       % stores TunedLoop into a TunedLoopSnapshot
       
       
       this.Name = TunedLoop.Name;
       this.Feedback = TunedLoop.Feedback;
       this.Description = TunedLoop.Description;
       
       this.TunedFactors = get(TunedLoop.TunedFactors,{'Identifier'});
       this.TunedLFTBlocks = get(TunedLoop.TunedLFT.Blocks,{'Identifier'});
       this.TunedLFTSSData = TunedLoop.TunedLFT.IC;
       this.LoopConfig = TunedLoop.LoopConfig;
       
       this.ClosedLoopIOs = TunedLoop.ClosedLoopIO;
       
       
       
       
       
       end  % utStoreTunedLoop
       
end  % public methods 

end  % classdef

