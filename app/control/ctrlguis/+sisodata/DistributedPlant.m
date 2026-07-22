classdef DistributedPlant < sisodata.plant
%sisodata.DistributedPlant class
%   sisodata.DistributedPlant extends sisodata.plant.
%

%    sisodata.DistributedPlant properties:
%       nLoop - Property is of type 'MATLAB array'  
%       Configuration - Property is of type 'double'  
%       NominalIdx - Property is of type 'MATLAB array'  
%       TimeUnits - Property is of type 'String'  
%       Connectivity - Property is of type 'MATLAB array'  
%       G - Property is of type 'handle vector'  
%       LoopSign - Property is of type 'MATLAB array'  
%       LoopStatus - Property is of type 'MATLAB array'  
%
%    sisodata.DistributedPlant methods:
%       clearPsim -  Clears plant model for closed-loop analysis
%       fresp -  Plant frequency response.
%       getP -  Returns augmented plant model P (and recomputes it if necessary).
%       getPsim -  Returns augmented plant model Psim used for closed-loop analysis 
%       getconfig -  Returns current loop configuration
%       import -  plant data.
%       isempty -  Checks if no data has been imported
%       isstatic -  Returns TRUE if model is a pure gain.
%       loopIC -  Defines connectivity matrix for various loop configurations
%       setconfig -  Sets plant configuration


properties (Access=protected, SetObservable)
    %PSIM Property is of type 'MATLAB array' 
    Psim = [];
end

properties (SetObservable)
    %CONNECTIVITY Property is of type 'MATLAB array' 
    Connectivity = [];
    %G Property is of type 'handle vector' 
    G = [];
    %LOOPSIGN Property is of type 'MATLAB array' 
    LoopSign = [];
    %LOOPSTATUS Property is of type 'MATLAB array' 
    LoopStatus = [];
end


    methods 
        function set.G(obj,value)
            % DataType = 'handle vector'
        validateattributes(value,{'handle'}, {'vector'},'','G')
        obj.G = value;
        end

        function set.LoopStatus(obj,value)
        obj.LoopStatus = LocalClearPsim(obj,value);
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function clearPsim(this)
       % Clears plant model for closed-loop analysis
       
       this.Psim = [];
       end  % clearPsim
       
        %----------------------------------------
       function h = fresp(this,w,Input,Output,SimFlag,idxM)
       % Plant frequency response.
       % 
       % The index vectors INPUT and OUPT select the desired external 
       % inputs and outputs.
       
       %   Author(s): P. Gahinet
       
       if nargin < 6
           idxM = this.getNominalModelIndex;
       end
       
       nw = length(w);
       nG = length(this.G);
       nC = this.nLoop;
       if nargin==4 || all(this.LoopStatus)
          IC = this.Connectivity;
       else
          % Frequency response for closed-loop analysis
          IC = this.loopIC(this.Configuration,this.LoopSign.*this.LoopStatus);
       end
       
       % Extract appropriate IC submatrix with 
       %   1) fixed G's at the top
       %   2) Selected I/Os in the middle
       %   2) tuned C's at the bottom
       [rs,cs] = size(IC);
       indrow = [1:nG nG+Output rs-nC+1:rs];
       indcol = [1:nG nG+Input cs-nC+1:cs];
       IC = IC(indrow,indcol);
       
       % Response of fixed components
       F = zeros(nw,nG);
       for ct=1:nG,
           if length(this.G(ct).ModelData) == 1
               GModelData = this.G(ct).ModelData;
           else
               GModelData = this.G(ct).ModelData(idxM);
           end
           fh = fresp(GModelData,w);
           F(:,ct) = fh(:);
       end
       
       % Desired plant response
       [rs,cs] = size(IC);
       h = zeros(rs-nG,cs-nG,nw);
       for ctw=1:nw
          hw = IC;
          % Close upper loops around fixed components
          Fw = F(ctw,:);
          for ct=1:nG
             hw(ct+1:rs,ct+1:cs) = hw(ct+1:rs,ct+1:cs) + ...
                (hw(ct+1:rs,ct) * (Fw(ct)/(1-hw(ct,ct)*Fw(ct)))) * hw(ct,ct+1:cs);
          end
          h(:,:,ctw) = hw(nG+1:rs,nG+1:cs);
       end
       
       end  % fresp
       
        %----------------------------------------
       function P = getP(this)
       % Returns augmented plant model P (and recomputes it if necessary).
       
       %   Author(s): P. Gahinet, C. Buhr
       P = this.P;
       if isempty(P)
          % Recompute plant model P
          % Build @ssdata or @frddata model for IC matrix
          [ny,nu] = size(this.Connectivity);   
          Ts = this.G(1).ModelData.Ts;
          P = ltipack.ssdata([],zeros(0,nu),zeros(ny,0),this.Connectivity,[],Ts);
          G = this.G;
          
          % Set Plant Time Units
          this.TimeUnits = this.G(1).Model.TimeUnit;
          
          
          % Check if any G has FRD data
          isFRD = false;
          for ct=1:length(G)
              if isa(G(ct).ModelData,'ltipack.frddata')
                  isFRD = true;
                  break;
              end
          end
          
          % Close the fixed model loops
          if isFRD
              P = localPfrddataArray(P,G);
          else
              P = localPssddataArray(P,G);
          end
              
          this.P = P;
       end
       end
       
       
       % function P = localPssddata(P,G)
       % % Close each fixed model loop 
       % for ct=1:length(G)
       %     P = lft(G(ct).ModelData,P,1,1,1,1);
       % end
       % end
       
       

        %----------------------------------------
       function Psim = getPsim(this)
       % Returns augmented plant model Psim used for closed-loop analysis 
       % and simulation.
       
       %   Author(s): P. Gahinet
       if all(this.LoopStatus)
          % Use open-loop model
          Psim = getP(this);
       else
          if isempty(this.Psim)
             % Recompute closed-loop model
             nG = length(this.G);
             
             % Compute interconnection matrix for closed-loop simulation (taking 
             % into account open/closed status of each loop)
             e = this.LoopSign .* this.LoopStatus;
             IC = this.loopIC(this.Configuration,e);
             [ny,nu] = size(IC);
             
             % Build @ssdata model for IC matrix
             Ts = this.G(1).SSData.Ts;
             D = ltipack.ssdata([],zeros(0,nu),zeros(ny,0),...
                IC([nG+1:ny,1:nG],[nG+1:nu,1:nG]),[],Ts);
             
             % Build vector of state-space models of G1,G2,...
             G = ltipack.ssdata.array([nG 1]);
             for ct=1:nG
                G(ct) = this.G(ct).SSData;
             end
             
             % Close each fixed model loop 
             this.Psim = utSISOLFT(D,G);
          end
          Psim = this.Psim;
       end
       
       
       end  % getPsim
       
        %----------------------------------------
       function [ConfigID,FeedbackSigns] = getconfig(this)
       %GETCONFIG  Returns current loop configuration
       
       ConfigID = this.Configuration;
       FeedbackSigns = this.LoopSign;
       end  % getconfig
       
        %----------------------------------------
       function import(this,G)
       % Imports plant data.
       
       %   Author(s): P. Gahinet
       for ct=1:length(G)
          this.G(ct).import(G(ct))
       end
       
       % Reset P
       this.P = [];
       this.Psim = [];
       
       end  % import
       
        %----------------------------------------
       function boo = isempty(this)
       % Checks if no data has been imported
       
       boo = isempty(this.G) || isempty(this.G(1).Model);
          
       end  % isempty
       
        %----------------------------------------
       function boo = isstatic(this)
       % Returns TRUE if model is a pure gain.
       
       
       numPlants = length(this.G);
       boo = false(numPlants,1);
       
       for cnt = 1:numPlants
           boo(cnt) = isstatic(this.G(cnt));
       end
       end  % isstatic
       
        %----------------------------------------
       function ICMat = loopIC(this,Config,e)
       % Defines connectivity matrix for various loop configurations
       
       
       % UDDREVISIT: private static
       switch Config
           case 1
             ICMat = [...
                   0 0 0 0 1 0 1 0;...
                   1 0 0 1 0 0 0 0;...
                   1 0 0 1 0 0 0 0;...
                   0 0 0 0 1 0 1 0;...
                   0 e 0 0 0 e 0 1;...
                   0 0 1 0 0 0 0 0];
               
           case 2
             ICMat = [...
                   0 0 0 0 1 0 e 1;...
                   1 0 0 1 0 0 0 0;...
                   1 0 0 1 0 0 0 0;...
                   0 0 0 0 1 0 e 1;...
                   0 1 0 0 0 1 0 0;...
                   0 0 1 0 0 0 0 0];  
               
           case 3
             ICMat = [...
                   0 0 0 0 1 0 1 1;...
                   1 0 0 1 0 0 0 0;...
                   1 0 0 1 0 0 0 0;...
                   0 0 0 0 1 0 1 1;...
                   0 e 1 0 0 e 0 0;...
                   0 0 1 0 0 0 0 0];
             
           case 4
             ICMat = [...
                   0 0 0 0 1 0 1 e(2);...
                   1 0 0 1 0 0 0 0;...
                   1 0 0 1 0 0 0 0;...
                   0 0 0 0 1 0 1 e(2);...
                   0 e(1) 1 0 0 e(1) 0 0;...
                   0 1 0 0 0 1 0 0];
                      
           case 5
             ICMat = [...
                   0  0 0 0 1 0 1 0;...
                   0  0 0 0 0 0 1 0;...
                   0  0 0 0 0 1 0 0;...
                   1  0 1 0 0 0 0 0;...
                   0  0 0 0 1 0 1 0;...
                   1 -1 1 0 0 0 0 0; ...
                   e(1) -e(1) e(1) 0 0 0 0 1; ...
                   0  0 0 1 0 0 0 0];
               
           case 6
             ICMat = [...
                   0 0 0 0 0 1 0 0 0 0 0 1 0;...
                   1 0 0 0 0 0 1 0 0 0 0 0 0;...
                   1 0 0 0 0 0 0 0 0 0 0 0 0;...
                   0 1 0 0 0 0 0 1 0 0 0 0 0;...
                   0 0 0 0 0 1 0 0 0 0 0 1 0;...
                   1 0 0 0 0 0 0 0 0 0 0 0 0;...
                   1 0 0 0 0 0 1 0 0 0 0 0 0;... 
                   0 1 0 0 0 0 0 1 0 0 0 0 0;...
                   0 0 0 e(1) 0 0 0 0 0 e(1) 0 0 1;...
                   0 0 e(2) 0 0 0 0 0 e(2) 0 1 0 0;...
                   0 0 0 0 1 0 0 0 0 0 0 0 0];
                   
       end
       end  % loopIC
       
        %----------------------------------------
       function setconfig(this,ConfigID,LoopSign)
       % Sets plant configuration
       
       %   Author(s): P. Gahinet
       
       % New G components should be initialized when data is already loaded
       InitFlag = ~isempty(this);
       
       % Set up desired loop configuration
       switch ConfigID
          case {1 2 3 4}
             % Single loop with 
             %   * Fixed models G, H
             %   * Compensator C in forward or feedback path
             %   * Prefilter or feedforward F
             this.nLoop = 2;
             LocalCreateModels(this,2,InitFlag)
             this.G(1).Identifier = 'G';
             this.G(1).Description = 'Plant';
             this.G(2).Identifier = 'H';
             this.G(2).Description = 'Sensor';
           case 5
             this.nLoop = 2;
             LocalCreateModels(this,3,InitFlag)
             this.G(1).Identifier = 'G1';
             this.G(1).Description = 'Plant';
             this.G(2).Identifier = 'G2';
             this.G(2).Description = 'Plant2';
             this.G(3).Identifier = 'Gd';
             this.G(3).Description = 'Disturbance Dynamics';
           case 6
             this.nLoop = 3;
             LocalCreateModels(this,4,InitFlag)
             this.G(1).Identifier = 'G1';
             this.G(1).Description = 'Plant';
             this.G(2).Identifier = 'G2';
             this.G(2).Description = 'Plant2';
             this.G(3).Identifier = 'H1';
             this.G(3).Description = 'Sensor';
             this.G(4).Identifier = 'H2';
             this.G(4).Description = 'Sensor2';
             
       end
       
       % RE: All feedback junctions are closed by default
       this.LoopSign = LoopSign;
       this.LoopStatus = true(size(LoopSign)); 
       
       % Config data
       this.Configuration = ConfigID;
       this.Connectivity = this.loopIC(ConfigID,LoopSign);
       
       % Clear dependencies
       this.P = [];
       this.Psim = [];
       end  % setconfig
       
       
       %---------------- Local Functions -------------------------
       

end  % public methods 

end  % classdef

function v = LocalClearPsim(this,v)
% Clear Psim 
clearPsim(this)
end  % LocalClearPsim
function P = localPssddataArray(P,G)

NumPlants = 1;
for ct = 1:length(G)
    NumPlants = max(NumPlants, length(G(ct).ModelData));
end

for k = 1:NumPlants
    % Close each fixed model loop
    Ptemp = P;
    for ct=1:length(G)
        % Use the kth model or scalar expansion
        if length(G(ct).ModelData) == 1
            GModel = G(ct).ModelData(1);
        else
            GModel = G(ct).ModelData(k);
        end
        Ptemp = lft(GModel,Ptemp,1,1,1,1);
    end
    Plant(k,1) = Ptemp;
end

P = Plant;

end

function P = localPfrddataArray(P,G)

% Create frequency vector based on FRD data of G
w = [];
for ct=1:length(G)
    if isa(G(ct).ModelData(1),'ltipack.frddata')
        w = G(ct).ModelData(1).Frequency;  % in rad/TimeUnit
        break
    end
end

% Convert interconnection matrix to FRD
P = frd(P,w);

NumPlants = 1;
for ct = 1:length(G)
    NumPlants = max(NumPlants, length(G(ct).ModelData));
end


for k = 1:NumPlants
    % Close each fixed model loop
    Ptemp = P;
    % Close each fixed model loop
    for ct=1:length(G)
        % Use the kth model or scalar expansion
        if length(G(ct).ModelData) == 1
            Gfrd = localConvertToFRD(G(ct).ModelData(1),w);
        else
            Gfrd = localConvertToFRD(G(ct).ModelData(k),w);
        end
        % Perform interconnection
        Ptemp = lft(Gfrd,Ptemp,1,1,1,1);
        
    end
    Plant(k,1) = Ptemp;
end

P = Plant;

end

function Gfrd = localConvertToFRD(ModelData,w)
        % Preprocess each plant model to ensure proper frd data
        if isa(ModelData,'ltipack.frddata')
            Gfrd = elimDelay(ModelData);
            % Interpolate (W in rad/TimeUnit)
            Gfrd.Response = fresp(Gfrd,w);
            Gfrd.Frequency = w;
        else
            % Convert models to FRD
            Gfrd = frd(ModelData,w);
        end
end


% function P = localPfrddata(P,G)
% 
% % Create frequency vector based on FRD data of G
% w = [];
% for ct=1:length(G)
%     if isa(G(ct).ModelData,'ltipack.frddata')
%         w = unitconv(G(ct).ModelData.Frequency, ...
%             G(ct).ModelData.FreqUnits,'rad/s');
%     end
% end
% 
% % Convert interconnection matrix to FRD
% P = frd(P,w,'rad/s');
% 
% % Close each fixed model loop
% for ct=1:length(G)
%     % Preprocess each plant model to ensure proper frd data
%     if isa(G(ct).ModelData,'ltipack.frddata')
%         Gfrd = G(ct).ModelData;
%         % Make sure data is in rad/s and interpolate
%         Gfrd.Frequency = unitconv(Gfrd.Frequency,Gfrd.FreqUnits,'rad/s');
%         Gfrd.FreqUnits = 'rad/s';
%         Gfrd.Response = fresp(Gfrd,w,'rad/s');
%         Gfrd.Frequency = w;
%     else
%         % Convert models to FRD
%         Gfrd = frd(G(ct).ModelData,w,'rad/s');
%     end
%     % Perform interconnection
%     P = lft(Gfrd,P,1,1,1,1);
% end
% 
% end
function LocalCreateModels(this,nG,InitFlag)
% Adjust the lists of fixed and tuned models
nG0 = length(this.G);
if nG0>nG,
   delete(this.G(nG+1:nG0));
   this.G = this.G(1:nG);
else
   for ct=nG0+1:nG
      G = sisodata.fixedmodel;
      if InitFlag
         G.import(struct('Name','','Value',zpk(1),'Variable',''))
      end
      this.G = [this.G ; G];
   end
end
end  % LocalCreateModels

