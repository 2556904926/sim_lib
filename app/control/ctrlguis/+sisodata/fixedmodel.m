classdef fixedmodel < matlab.mixin.SetGet & matlab.mixin.Copyable
%sisodata.fixedmodel class
%    sisodata.fixedmodel properties:
%       Name - Property is of type 'ustring'  
%       Description - Property is of type 'ustring'  
%       Identifier - Property is of type 'string'  
%       Variable - Property is of type 'ustring'  
%       Model - Property is of type 'MATLAB array'  
%       ModelData - Property is of type 'MATLAB array'  
%
%    sisodata.fixedmodel methods:
%       import -  model data.
%       isstatic -  Returns TRUE if model array is a pure gain.
%       save -  model data.
%       ss -  Returns @ssdata representation of plant component.
%       zpk -  Returns @zpkdata model of plant component.


properties (SetObservable)
    %NAME Property is of type 'ustring' 
    Name = '';
    %DESCRIPTION Property is of type 'ustring' 
    Description = '';
    %IDENTIFIER Property is of type 'string' 
    Identifier = '';
    %VARIABLE Property is of type 'ustring' 
    Variable = '';
    %MODEL Property is of type 'MATLAB array' 
    Model = [];
    %MODELDATA Property is of type 'MATLAB array' 
    ModelData = [];
end


    methods 
        function set.Name(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Name = value;
        end

        function set.Description(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Description = value;
        end

        function set.Identifier(obj,value)
            % DataType = 'string'
        validateattributes(value,{'char'}, {'row'},'','Identifier')
        obj.Identifier = value;
        end

        function set.Variable(obj,value)
            % DataType = 'ustring'
        % no cell string checks yet'
        obj.Variable = value;
        end

    end   % set and get functions 

    methods  % public methods
        %----------------------------------------
       function import(this,G)
       % Imports model data.
       % G is a structure with fields Name and Model.
       
       
       this.Name = G.Name;
       this.Variable = G.Variable;
       this.Model = G.Value;
       
       % @ssdata or @frddata representation
       if isa(this.Model,'frd')
           D = getPrivateData(chgTimeUnit(this.Model(1,1,:),'seconds'));
       else
           D = getPrivateData(chgTimeUnit(ss(this.Model(1,1,:)),'seconds'));
       end
       
       this.ModelData = D;
       
       
       
       end  % import
       
        %----------------------------------------
       function boo = isstatic(this)
       % Returns TRUE if model array is a pure gain.
       
       
       boo = true;
       P = this.ModelData;
       for ct = 1:numel(P)
           if ~isstatic(P(ct));
               boo = false;
               break;
           end
       end
       
       end  % isstatic
       
        %----------------------------------------
       function Data = save(this,Data)
       % Saves model data.
       
       if nargin==1
          Data = struct('Name',this.Name,'Value',this.Model,'Variable',this.Variable);
       else
          Data.Name = this.Name;
          Data.Value = this.Model;
          Data.Variable = this.Variable;
       end
          
       
       end  % save
       
        %----------------------------------------
       function D = ss(this)
       % Returns @ssdata representation of plant component.
       
       
       if isa(this.ModelData,'ltipack.ssdata')
           D = this.ModelData;
       else
           ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
               'frddata cannot be converted to a state-space model.');
       end
       end  % ss
       
        %----------------------------------------
       function D = zpk(this)
       % Returns @zpkdata model of plant component.
       
       
       try 
           D = zpk(this.ModelData);
       catch ME
           ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
               'The model cannot be converted to a zpk model.');
       end
       end  % zpk
       
end  % public methods 

end  % classdef

