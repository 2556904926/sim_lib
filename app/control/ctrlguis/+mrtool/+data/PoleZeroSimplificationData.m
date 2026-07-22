classdef (Hidden) PoleZeroSimplificationData < mrtool.data.AbstractData
    % Pole/Zero Simplification Data Class for Pole/Zero Simplification Tool
    
    % Author(s): S. Gumussoy, A. Ouellette
    % Copyright 2015-2024 The MathWorks, Inc. 
    
    properties (SetObservable, AbortSet)
        ComparisonPlot = "modelResponse";
        AnalysisPlot = "pzplot";
        Tolerance = 1e-5;
    end

    %% Constructor
    methods
        function this = PoleZeroSimplificationData(Target)
            this = this@mrtool.data.AbstractData(Target);
        end  
    end

    %% Get/Set
    methods
        % Tolerance
        function set.Tolerance(this,Tolerance)
            arguments
                this (1,1) mrtool.data.PoleZeroSimplificationData
                Tolerance (1,1) double {mustBeInRange(Tolerance,0,1,"exclude-lower")}
            end
            this.Tolerance = Tolerance;
            if this.IsValid
                computeReducedSystem(this);
            end
        end

        % ComparisonPlot
        function set.ComparisonPlot(this,ComparisonPlot)
            arguments
                this (1,1) mrtool.data.PoleZeroSimplificationData
                ComparisonPlot (1,1) string {mustBeMember(ComparisonPlot,["modelResponse","absoluteError","relativeError"])}
            end
            this.ComparisonPlot = ComparisonPlot;
        end

        % AnalysisPlot
        function set.AnalysisPlot(this,AnalysisPlot)
            arguments
                this (1,1) mrtool.data.PoleZeroSimplificationData
                AnalysisPlot (1,1) string {mustBeMember(AnalysisPlot,"pzplot")}
            end
            this.AnalysisPlot = AnalysisPlot;
        end
    end

    %% Public methods
    methods
        function [Text,localVariables] = generateMATLABCode(this,optionalInputs)
            arguments
                this (1,1) mrtool.data.PoleZeroSimplificationData
                optionalInputs.OutputName (1,1) string = "ReducedSystem"
                optionalInputs.PlotCommand (1,1) string = "bodeplot"
                optionalInputs.IsLiveEditor (1,1) logical = false
                optionalInputs.AbsorbDelay (1,1) logical = false
            end
            Text = cell(0,1);            
            localVariables = strings(0,1);
            Text = controllib.internal.codegen.appendMATLABCode(Text,['%% ' getString(message('Control:mrtool:CodegenPZTitle'))]); 
            SystemName = ltipack.createVarName(this.TargetName);
            if optionalInputs.IsLiveEditor
                SystemName = "`"+SystemName+"`";
            end
            if optionalInputs.AbsorbDelay
                Text = controllib.internal.codegen.appendMATLABCode(...
                    Text,['% ',getString(message('Control:mrtool:CodegenAbsorbDelayComment'))]);
                Text = controllib.internal.codegen.appendMATLABCode(...
                    Text,sprintf('DelayAbsorbedSystem = absorbDelay(%s);',SystemName));
                Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
                SystemName = "DelayAbsorbedSystem";
                localVariables = [localVariables;"DelayAbsorbedSystem"];
            end
            SystemName = sprintf('ScaledSystem = prescale(ss(%s));',SystemName);
            localVariables = [localVariables;"ScaledSystem"];
            Text = controllib.internal.codegen.appendMATLABCode(Text,SystemName,[],getString(message('Control:mrtool:CodegenSystem')));
            Text = controllib.internal.codegen.appendMATLABCode(Text,this.Tolerance,'Tol',getString(message('Control:mrtool:CodegenPZTolerance')));
            localVariables = [localVariables;"Tol"];
            Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
            Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenPZReduceCommand'))]);
            Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('%s = minreal(ScaledSystem,Tol,false);',optionalInputs.OutputName));
            if optionalInputs.PlotCommand ~= "none"
                Text = controllib.internal.codegen.appendMATLABCode(Text,' ');
                Text = controllib.internal.codegen.appendMATLABCode(Text,['% ' getString(message('Control:mrtool:CodegenCreatePlot'))]);
                Text = controllib.internal.codegen.appendMATLABCode(Text,'f = figure();');
                Text = controllib.internal.codegen.appendMATLABCode(Text,sprintf('h = %s(f,ScaledSystem,%s);',optionalInputs.PlotCommand,optionalInputs.OutputName));
                legendcode1 = sprintf('legend(h,[''%s ('',mat2str(order(%s)),'' states)''],...',...
                    getString(message('Control:mrtool:CodegenOriginalModel')),this.TargetName);
                legendcode2 = sprintf('         [''%s ('',mat2str(order(%s)),'' states)'']);',...
                    getString(message('Control:mrtool:CodegenReducedModel')),optionalInputs.OutputName);
                Text = controllib.internal.codegen.appendMATLABCode(Text,legendcode1);
                Text = controllib.internal.codegen.appendMATLABCode(Text,legendcode2);
                Text = controllib.internal.codegen.appendMATLABCode(Text,'h.AxesStyle.GridVisible = true;');
                localVariables = [localVariables;"f";"h"];
            end
            if ~optionalInputs.IsLiveEditor
                controllib.internal.codegen.showGeneratedMATLABCode(Text,false);
            end            
        end  

        % Load/Save Session
        function loadSessionToolData(this,SessionData)
            this.Tolerance = SessionData.Tolerance; 
            if isfield(SessionData,'ComparisonPlot')
                this.ComparisonPlot = SessionData.ComparisonPlot;
            else
                % Pre 2024a data
                switch find(SessionData.Visualizations)
                    case 1
                        comparisonPlot = "modelResponse";
                    case 2
                        comparisonPlot = "absoluteError";
                    case 3
                        comparisonPlot = "relativeError";
                end
                this.ComparisonPlot = comparisonPlot;
            end
        end        

        function SessionData = saveSessionToolData(this,SessionData)
            SessionData.ToolType = 'PoleZeroSimplification';
            SessionData.Tolerance = this.Tolerance;
        end        
    end

    %% Protected methods
    methods (Access = protected)
        function ReducedSystem = localComputeReducedSystem(this)
            sys = prescale(ss(this.TargetSystem));
            ReducedSystem = minreal(sys,this.Tolerance,false);
        end
    end
end