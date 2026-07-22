classdef FixedBlock < ctrlguis.csdesignerapp.data.architectures.internal.Block
    % FIXEDBLOCK class to encapsulate a fixed model that does not change
    % due to tuning/ designing.
    
    % Copyright 2014-2015 The MathWorks, Inc.
    properties (Dependent = true)
        Name
    end
        
    %% Private Properties
    properties (Access = private)
        Description     % Model description (e.g. Sensor)
        Identifier      % Model identifier (W.R.T closed loop configuration)
        Model           % @lti model
        ModelData       % @ssdata or @frddata representation
        DisplayDialog
    end
    
    %% Public methods
    methods
        % Constructor
        function this = FixedBlock(Identifier, Model)
            % Class that manages blocks that are fixed.
            % Input: Model:       The @lti model behind the fixed block.
            %        Identifier:  Identifier that is used to identify the 
            %                     fixed block in a given block diagram
            
            % Parse inputs
            narginchk(2,2);
            
            % Validate and set Model
            this.Model = Model;
            
            % Set the ID
            this.Identifier =  Identifier;
        end
                
        function Name = get.Name(this)
            % Get the name from the Model
            Name = this.Model.Name;
        end
        
        function set.Name(this, Name)
            % Get the name from the Model
            this.Model.Name = Name;
        end
        
        function ID = getIdentifier(this)
            ID = cell(0,1);
            for ct = 1:numel(this)
                % Return name of Tuned Block
                ID = [ID; {this(ct).Identifier}];
            end
            if numel(this) == 1
                ID = ID{1,:};
            end
        end
        
        %% Display preview text
        function DisplayText = getDisplayPreviewText(this)
            DisplayText = [ ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('type', ...
                getString(message('Control:designerapp:DisplayFixedBlock'))), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayName')),this.Name), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayTs')),this.Model.Ts), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayText('line', ...
                getString(message('Control:designerapp:DisplayValue')), ...
                ctrlguis.csdesignerapp.utils.internal.createDisplayBlock(this)), ...
                ];
        end
        
        function openDisplayDialog(this, hAnchor, Region)
            if nargin < 2
                hAnchor = [];
            end
            if nargin < 3
                Region = 'CENTER';
            end
            if isempty(this.DisplayDialog)
                this.DisplayDialog = ctrlguis.csdesignerapp.dialogs.internal.FixedBlockDisplayDialog(this);
                registerDialog(hAnchor,this.DisplayDialog);
            end
            this.DisplayDialog.show(hAnchor,Region);
        end
        
        function [ny,nu] = iosize(this)
            [ny, nu] = iosize(this.Model);
            if nargout==1
                ny = [ny nu];
            end
        end
        
        function setValue(this, NewModel, varargin)
            if isnumeric(NewModel)
                NewModel = ss(NewModel);
            end
            if isa(NewModel, 'lti')
                % Condense everything
                this.Model = NewModel(:,:,:);
                
                % Convert generalized models to frd/ss
                if isa(this.Model,'genfrd')
                    this.Model = frd(this.Model);
                elseif isa(this.Model,'genss')
                    this.Model = ss(this.Model);
                end
                
                % Update name
                if isempty(this.Model.Name)
                    this.Model.Name = this.Identifier;
                end
                
                % Update model data to match model
                setModelData(this);
                if nargin==2
                    this.notify('ValueChanged');
                end
                if ~isempty(this.DisplayDialog)
                    updateUI(this.DisplayDialog);
                end
            else
                error(message('Controllib:general:UnexpectedError', ...
                    'Model must be an @lti object'));
            end
        end
        
        function Data = getValue(this)
            Data = this.Model;
        end

        function Data = ss(this)
            % Return ssdata object for model
            if isa(this.ModelData,'ltipack.ssdata')
                Data = this.ModelData;
            else
                ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                    'frddata cannot be converted to a state-space model.');
            end
        end
        
        function Data = zpk(this)
            % Return zpkdata object for model
            try
                Data = zpk(this.ModelData);
            catch
                ctrlMsgUtils.error('Controllib:general:UnexpectedError', ...
                    'The model cannot be converted to a zpk model.');
            end
        end
        
        function S = saveSession(this)           
            S = struct(...
                'Identifier', this.Identifier, ...
                'Description', this.Description, ...
                'Value', this.Model);
        end
    end
    
    %% Private methods
    methods (Access = private)
        function setModelData(this)
            if isa(this.Model,'frd')
                this.ModelData =  getPrivateData(chgTimeUnit(this.Model,'seconds'));
            else
                this.ModelData =  getPrivateData(chgTimeUnit(ss(this.Model(1,1,:)),'seconds'));
            end
        end
    end
    
    %% Events
    events
        ValueChanged % Fires when value of plant changes
    end
end