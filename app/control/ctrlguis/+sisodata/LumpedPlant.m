classdef LumpedPlant < sisodata.plant
%sisodata.LumpedPlant class
%   sisodata.LumpedPlant extends sisodata.plant.
%

%    sisodata.LumpedPlant properties:
%       nLoop - Property is of type 'MATLAB array'  
%       Configuration - Property is of type 'double'  
%       NominalIdx - Property is of type 'MATLAB array'  
%       TimeUnits - Property is of type 'String'  
%       Pfr - Property is of type 'MATLAB array'  
%
%    sisodata.LumpedPlant methods:
%       fresp -  Plant frequency response.
%       import -  plant model.
%       setP -  Sets value of augmented plant P.


properties (GetAccess=protected, SetObservable)
    %PFR Property is of type 'MATLAB array' 
    Pfr = [];
end


    methods 
    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function h = fresp(this,w,Input,Output,~,idxM)
       % Plant frequency response.
       % 
       % The index vectors INPUT and OUPT select the desired external 
       % inputs and outputs.
       
       
       if nargin < 6
           idxM = this.getNominalModelIndex;
       end
       
       [ny,nu] = iosize(this.P);
       nC = this.nLoop;
       % Select plant I/Os of interest
       indrow = [Output ny-nC+1:ny];
       indcol = [Input nu-nC+1:nu];
       h = fresp(getsubsys(this.Pfr(:,:,idxM),indrow,indcol),w);
       end  % fresp
       
        %----------------------------------------
       function import(this,P)
       % Imports plant model.
       
       this.setP(getPrivateData(P.Value))
       
       end  % import
       
        %----------------------------------------
       function setP(this,P)
       % Sets value of augmented plant P.
       
       
       this.P = P; % set private value
       
       % Update plant representation for fast frequency response evaluation
       try
           this.Pfr = zpk(P);
       catch ME %#ok<NASGU>
           % FRD or Model with Internal Delays
           this.Pfr = P;
       end
       
       
       end  % setP
       
end  % public methods 

end  % classdef

