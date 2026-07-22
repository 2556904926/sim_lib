function tableData = createImportTableData(data)
% Helper to create import table

% Copyright 2020 The MathWorks, Inc.
arguments
    data = [];
end
variableNames = {'Variable Name',...
                 'Size',...
                 'Bytes',...
                 'Class'};
if ~isempty(data)
    localCreateVariables(data);
    variableClass = cell(size(data,1),1);
    variableSize = cell(size(data,1),1);
    variableBytes = zeros(size(data,1),1);
    for k = 1:size(data,1)
        w = whos(data{k,1});
        variableBytes(k) = w.bytes;
        variableClass{k} = w.class;
        variableSize{k} = [mat2str(w.size(1)),' x ',mat2str(w.size(2))];
    end
    tableData = table(data(:,1),...
        variableSize,variableBytes,variableClass,...
        'VariableNames',variableNames);
else
    tableData = table([],[],[],[],'VariableNames',variableNames);
end
end

function localCreateVariables(data)
for k = 1:size(data,1)
    assignin('caller',data{k,1},data{k,2});
end
end