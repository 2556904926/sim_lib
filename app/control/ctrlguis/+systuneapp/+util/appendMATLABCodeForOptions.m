function Text = appendMATLABCodeForOptions(Text,Options)
% Low level utility function to add MATLAB Code for Options to Text

% Copyright 2014 The MathWorks, Inc.

% put the title
OptionsName = 'Options';
OptionsTitle = ['%% ' getString(message('Control:systunegui:CodegenOptions'))];
Text = controllib.internal.codegen.appendMATLABCode(Text,OptionsTitle);
CreateOptionsCode = sprintf('%s = systuneOptions();',OptionsName);
Text = controllib.internal.codegen.appendMATLABCode(Text,CreateOptionsCode);

DefaultOptions = systuneOptions();
FieldNames = fieldnames(DefaultOptions);
OptionNamesToSet={};
OptionValuesToSet={};
for ct=1:length(FieldNames)
    if ~isequal(Options.(FieldNames{ct}),DefaultOptions.(FieldNames{ct}))
        OptionNamesToSet = vertcat(OptionNamesToSet,FieldNames(ct));
        Value = Options.(FieldNames{ct});
        OptionValuesToSet = vertcat(OptionValuesToSet,Value);
    end
end

if ~isempty(OptionNamesToSet)
    for ct=1:size(OptionNamesToSet,1)
        VarName = sprintf('%s.%s',OptionsName,OptionNamesToSet{ct});
        Comment = getString(message(['Control:systunegui:CodegenOptions' OptionNamesToSet{ct}]));
        Text = controllib.internal.codegen.appendMATLABCode(Text,OptionValuesToSet{ct},VarName,Comment);
    end
end
