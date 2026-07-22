classdef plant < matlab.mixin.SetGet & matlab.mixin.Copyable
%sisodata.plant class
%    sisodata.plant properties:
%       nLoop - Property is of type 'MATLAB array'  
%       Configuration - Property is of type 'double'  
%       NominalIdx - Property is of type 'MATLAB array'  
%       TimeUnits - Property is of type 'String'  
%
%    sisodata.plant methods:
%       getClosedLoopModel -  Computes a structurally minimal model for the closed-loop transfer 
%       getNominalModelIndex -  Returns the Nominal Model Index
%       getOpenLoopModel -  Computes a structurally minimal model for the open-loop transfer 
%       getP -  Returns augmented plant model P.
%       getPsim -  Returns augmented plant model for closed-loop analysis.
%       getconfig -  Returns current loop configuration
%       isUncertain -  Checks if the plant is uncertain (e.g. an array)
%       isempty -  Checks if no data has been imported
%       isstatic -  Returns TRUE if model array is a pure gain.
%       setNominalModelIndex -  Sets the Nominal Model Index


properties (Access=protected, SetObservable)
    %P Property is of type 'MATLAB array' 
    P = [];
end

properties (SetObservable)
    %NLOOP Property is of type 'MATLAB array' 
    nLoop = [];
    %CONFIGURATION Property is of type 'double' 
    Configuration = 0;
    %NOMINALIDX Property is of type 'MATLAB array' 
    NominalIdx = 1;
    %TIMEUNITS Property is of type 'String' 
    TimeUnits = 'seconds';
end


    methods 
        function set.Configuration(obj,value)
            % DataType = 'double'
        validateattributes(value,{'numeric'}, {'scalar'},'','Configuration')
        value = double(value); %  convert to double
        obj.Configuration = value;
        end

        function set.P(obj,value)
        obj.P = LocalSetP(obj,value);
        end

        function set.TimeUnits(obj,value)
            % DataType = 'String'
        % no cell string checks yet'
        obj.TimeUnits = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function [cList,G] = getClosedLoopModel(this,idxIn,idxOut,idxOpenings)
       % Computes a structurally minimal model for the closed-loop transfer 
       % function from input #idxIn to output #idxOut, taking into account  
       % loop opening at the outputs of the compensators C(IDXOPENINGS).
       %
       % The resulting model is of the form
       %    CL = lft(G , C(cList))
       % where G is a structurally minimal state-space model and the index 
       % vector CLIST indicates which compensators the closed-loop transfer 
       % function depends on.
       %
       % This function is used to build @TunedLoop data structures for 
       % closed-loop analysis.
       
       %   Author(s): P. Gahinet, C. Buhr
       
       nC = this.nLoop;  % number of compensators
       
       % Get Plant
       P = getP(this);
       
       for ct = 1:length(P)
           [cList,G(ct)] = localComputeModel(P(ct),nC,idxIn,idxOut,idxOpenings);
       end
       
       end
       

        %----------------------------------------
       function Idx = getNominalModelIndex(this)
       %getNominalModelIndex  Returns the Nominal Model Index
       
       
       Idx = this.NominalIdx;
       
       
       end  % getNominalModelIndex
       
        %----------------------------------------
       function [cList,G] = getOpenLoopModel(this,idxOL,idxOpenings)
       % Computes a structurally minimal model for the open-loop transfer 
       % function measured at the output of the compensator C(IDXOL), 
       % taking into account loop opening at the outputs of the compensators
       % C(IDXOPENINGS).
       %
       % The resulting model is of the form
       %    OL = lft(G , C(cList))
       % where G is a structurally minimal state-space model and the index 
       % vector CLIST indicates which compensators the open-loop transfer 
       % function depends on.
       %
       % This function is used to build @TunedLoop data structures for 
       % open-loop analysis.
       
       %   Author(s): P. Gahinet, C. Buhr
       
       
       
       nC = this.nLoop;  % number of compensators
       
       % Get Plant
       P = getP(this);
       
       for ct = 1:length(P)
           [cList,G(ct)] = localComputeModel2(P(ct),nC,idxOL,idxOpenings);
       end
       
       end
       

        %----------------------------------------
       function P = getP(this)
       % Returns augmented plant model P.
       
       %   Author(s): P. Gahinet
       P = this.P; % read private value
       end  % getP
       
        %----------------------------------------
       function Psim = getPsim(this)
       % Returns augmented plant model for closed-loop analysis.
       
       Psim = this.P;
       end  % getPsim
       
        %----------------------------------------
       function [ConfigID,FeedbackSigns] = getconfig(this)
       %GETCONFIG  Returns current loop configuration
       
       ConfigID = this.Configuration;
       FeedbackSigns = [];
       
       end  % getconfig
       
        %----------------------------------------
       function boo = isUncertain(this)
       % Checks if the plant is uncertain (e.g. an array)
       
       boo = numel(this.getP)>1;
          
       end  % isUncertain
       
        %----------------------------------------
       function boo = isempty(this)
       % Checks if no data has been imported
       
       boo = isempty(this.P);
          
       end  % isempty
       
        %----------------------------------------
       function boo = isstatic(this)
       % Returns TRUE if model array is a pure gain.
       
       
       boo = true;
       P = this.P;
       for ct = 1:numel(P)
           if ~isstatic(P(ct));
               boo = false;
               break;
           end
       end
       
       end  % isstatic
       
        %----------------------------------------
       function setNominalModelIndex(this,Idx)
       %setNominalModelIndex  Sets the Nominal Model Index
       
       
       if (Idx > numel(this.getP)) || (Idx < 0)
           error(message('Controllib:general:UnexpectedError', ...
               getString(message('Control:compDesignTask:errNominalValueIndexOutOfRange',numel(this.getP)))))
       else
           this.NominalIdx = Idx;
       end
       
       end  % setNominalModelIndex
       
end  % public methods 

end  % classdef

function valueStored = LocalSetP(this, ProposedValue)
if this.NominalIdx > length(ProposedValue)
    this.NominalIdx = 1;
end
valueStored = ProposedValue;
end  % LocalSetP

function [cList,G] = localComputeModel(P,nC,idxIn,idxOut,idxOpenings)

if isa(P,'ltipack.frddata')
    [ny,nu] = iosize(P);
    
    indrow = [idxOut , ny-nC+1:ny];
    indcol = [idxIn , nu-nC+1:nu];
    
    M = any(P.Response(indrow,indcol,:),3);
    M(:,idxOpenings+1) = 0;
    
    idx = 2:size(M,1);
    
    [~,~,~,~,keep] = smreal(M(idx,idx),M(idx,1),M(1,idx),[]);
    
    cList = find(keep(1:nC));
    
    iokeep = [1 ; 1+cList];
    G = getsubsys(P,iokeep,iokeep);
    
else
    % Get plant data
    a = P.a;
    b = P.b;
    c = P.c;
    d = P.d;
    e = P.e;
    [ny,nu] = size(d);
    
    DelayStruct = P.Delay;
    nID = length(DelayStruct.Internal); % number of internal delays
    
    % Keep only (idxIn,idxOut) I/O pair
    indrow = [idxOut , ny-nC-nID+1:ny];
    indcol = [idxIn , nu-nC-nID+1:nu];
    d = d(indrow,indcol);
    b = b(:,indcol);
    c = c(indrow,:);
    DelayStruct.Input = DelayStruct.Input([idxIn,nu-nID-nC+1:nu-nID],:);
    DelayStruct.Output = DelayStruct.Output([idxOut,ny-nID-nC+1:ny-nID],:);
    
    % Perform structural analysis
    M = [d c;b a];
    M(:,idxOpenings+1) = 0;  % take loop openings into account
    idx = 2:size(M,1);
    if isempty(e); % Handle improper case
        [~,~,~,~,keep] = smreal(M(idx,idx),M(idx,1),M(1,idx),[]);
    else
        Me = blkdiag(eye(size(d)),e);
        [~,~,~,~,keep] = smreal(M(idx,idx),M(idx,1),M(1,idx),Me(idx,idx));
    end
    
    % Compensators this loop depends on
    cList = find(keep(1:nC));
    
    % Internal Delays this loop depends on
    idList = find(keep(nC+1:nC+nID));
    
    % States this loop depends on
    xkeep = find(keep(nC+nID+1:end));
    
    iokeep = [1 ; 1+cList; 1+nC+idList];
    if ~isempty(e); % Update E for improper case
        e = e(xkeep,xkeep);
    end
    
    DelayStruct.Input = DelayStruct.Input([1 ; cList],:);
    DelayStruct.Output = DelayStruct.Output([1 ; cList],:);
    DelayStruct.Internal = DelayStruct.Internal(idList,:);
    
    G = ltipack.ssdata(a(xkeep,xkeep),b(xkeep,iokeep),c(iokeep,xkeep),...
        d(iokeep,iokeep),e,P.Ts);
    
    G.Delay = DelayStruct;
end
end

function [cList,G] = localComputeModel2(P,nC,idxOL,idxOpenings)

if isa(P,'ltipack.frddata')
    [ny,nu] = iosize(P);
    
    idx = [1:idxOL-1,idxOL+1:nC];
    
    indrow = ny-nC-1:ny;
    indcol = nu-nC+1:nu;
    % Eliminate External I/O
    % Determine hard zeros in I/O channels of P
    M = any(P.Response(indrow,indcol,:),3);
    M(:,idxOpenings) = 0;
    keep = false(nC,1);
    
    [~,~,~,~,keep(idx)] = smreal(M(idx,idx),M(idx,idxOL),M(idxOL,idx),[]);
    
    cList = find(keep(1:nC));
    
    iokeep = [idxOL ; cList];
    G = getsubsys(P,ny-nC+iokeep,nu-nC+iokeep);
    
else
    % Get plant data
    a = P.a;
    b = P.b;
    c = P.c;
    d = P.d;
    e = P.e;
    [ny,nu] = size(d);
    nx = size(a,1);
    
    DelayStruct = P.Delay;
    nID = length(DelayStruct.Internal); % number of internal delays
    
    % Eliminate external I/Os
    indrow = ny-nC-nID+1:ny;
    indcol = nu-nC-nID+1:nu;
    d = d(indrow,indcol);
    b = b(:,indcol);
    c = c(indrow,:);
    DelayStruct.Input = DelayStruct.Input(nu-nID-nC+1:nu-nID,:);
    DelayStruct.Output = DelayStruct.Output(ny-nID-nC+1:ny-nID,:);
    
    % Perform structural analysis
    M = [d c;b a];
    M(:,idxOpenings) = 0;  % take loop openings into account
    keep = false(nC+nID+nx,1);
    idx = [1:idxOL-1,idxOL+1:nC+nID+nx];
    if isempty(e); % Handle improper case
        [~,~,~,~,keep(idx)] = smreal(M(idx,idx),M(idx,idxOL),M(idxOL,idx),[]);
    else
        Me = blkdiag(eye(size(d)),e);
        [~,~,~,~,keep(idx)] = smreal(M(idx,idx),M(idx,idxOL),M(idxOL,idx),Me(idx,idx));
    end
    
    
    % Compensators this loop depends on
    cList = find(keep(1:nC));
    
    % Internal Delays this loop depends on
    idList = find(keep(nC+1:nC+nID));
    
    % States this loop depends on
    xkeep = find(keep(nC+nID+1:end));
    iokeep = [idxOL ; cList; nC+idList];
    if ~isempty(e); % Update E for improper case
        e = e(xkeep,xkeep);
    end
    
    
    DelayStruct.Input = DelayStruct.Input([1 ; cList],:);
    DelayStruct.Output = DelayStruct.Output([1 ; cList],:);
    DelayStruct.Internal = DelayStruct.Internal(idList,:);
    
    G = ltipack.ssdata(a(xkeep,xkeep),b(xkeep,iokeep),c(iokeep,xkeep),...
        d(iokeep,iokeep),e,P.Ts);
    
    G.Delay = DelayStruct;
end
end
