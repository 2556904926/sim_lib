classdef InputOutputData < wavepack.InputOutputData
    
    % Data is a structure with timeseries for I/Os.
    
    methods
        % Data = struct('Input', TS1, 'Output', TS2);
        function D = InputOutputData(varargin)
            D = D@wavepack.InputOutputData(varargin{:});
            D.IsTimeData = true;
        end
        
        function commit(D)
            
        end
        
        function iosize = getIOSize(D)
            iosize = ones(1,2);
            if isempty(D.Data.Input), iosize(2) = 0; end
            if isempty(D.Data.Output), iosize(1) = 0; end
        end
        
        function val  = getInputName(D)
            Data = D.Data;
            if ~isempty(Data.Input)
                val = {Data.Input.Name};
            else
                val = cell(0,1);
            end
        end
        
        
        function val  = getOutputName(D)
            Data = D.Data;
            if ~isempty(Data.Output)
                val = {Data.Output.Name};
            else
                val = cell(0,1);
            end
        end
        
        
        function data = getData(D, varargin)
            data = D.Data;
        end
        
        
        function signal = getSignalData(D,name,varargin)
            if isempty(name)
                signal = [D.Data.Output; D.Data.Input]; return
            end
            if ~iscell(name), name = {name}; end
            uname = getInputName(D);
            yname = getOutputName(D);
            signal = timeseries(1,1); signal = signal(zeros(0,1));
            for ct = 1:numel(name)
                if ~isempty(uname) && strcmp(name{ct},uname{1})
                    signal(end+1) = D.Data.Input;
                elseif ~isempty(yname) && strcmp(name{ct},yname{1})
                    signal(end+1) = D.Data.Output;
                end
            end
        end
        
        function setSignalData(D,name,data)
            
            uname = getInputName(D);
            I = find(strcmp(uname,name));
            if ~isempty(I)
                D.Data.Input = data;
            else
                % try output signals
                yname = getOutputName(D);
                I = find(strcmp(yname,name));
                if ~isempty(I)
                    D.Data.Output = data;
                end
            end
        end
    end
    
end