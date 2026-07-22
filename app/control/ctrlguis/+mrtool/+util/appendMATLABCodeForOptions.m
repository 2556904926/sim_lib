function Text = appendMATLABCodeForOptions(Text,Options,varargin)
% Low level utility function to add MATLAB Code for Options to Text

% Copyright 2015-2024 The MathWorks, Inc.
switch class(Options)
    case 'mor.BalancedTruncationOptions'
        CommandName = getString(message('Control:mrtool:BalancedTruncationTab'));
        Tag = 'BT';
        DefaultOptions = mor.BalancedTruncationOptions();
        WeightStrings = varargin{1};
    case 'mor.ModalTruncationOptions'
        CommandName = getString(message('Control:mrtool:ModalTruncationTab'));
        Tag = 'MT';
        DefaultOptions = mor.ModalTruncationOptions();
    case 'mor.SparseBalancedTruncationOptions'
        CommandName = getString(message('Control:mrtool:BalancedTruncationTab'));
        Tag = 'SparseBT';
        DefaultOptions = mor.SparseBalancedTruncationOptions();
    case 'mor.SparseModalTruncationOptions'
        CommandName = getString(message('Control:mrtool:ModalTruncationTab'));
        Tag = 'SparseMT';
        DefaultOptions = mor.SparseModalTruncationOptions();
    case 'mor.ProperOrthogonalDecompositionOptions'
        CommandName = getString(message('Control:mrtool:ProperOrthogonalDecompositionTab'));
        Tag = 'POD';
        DefaultOptions = mor.ProperOrthogonalDecompositionOptions();
end
% Find all differing options
FieldNames = fieldnames(DefaultOptions);
OptionNamesToSet={};
OptionValuesToSet={};
for ct=1:length(FieldNames)
    if ~isequal(Options.(FieldNames{ct}),DefaultOptions.(FieldNames{ct}))
        OptionNamesToSet = vertcat(OptionNamesToSet,FieldNames(ct)); %#ok<AGROW>
        if isa(Options,'mor.BalancedTruncationOptions') && strcmpi(FieldNames{ct},"InputWeight")
            Value = WeightStrings(1);
        elseif isa(Options,'mor.BalancedTruncationOptions') && strcmpi(FieldNames{ct},"OutputWeight")
            Value = WeightStrings(2);
        else
            Value = Options.(FieldNames{ct});
        end
        OptionValuesToSet = vertcat(OptionValuesToSet,Value); %#ok<AGROW>
    end
end
% Add code if differing options found
if ~isempty(OptionNamesToSet)
    % put the title
    OptionsTitle = ['% ' getString(message('Control:mrtool:CodegenCreateOptionsMOR',CommandName))];
    Text = controllib.internal.codegen.appendMATLABCode(Text,OptionsTitle);
    for ct=1:size(OptionNamesToSet,1)
        Comment = ['% ',getString(message(['Control:mrtool:CodegenOptions' Tag OptionNamesToSet{ct}]))];
        Text = controllib.internal.codegen.appendMATLABCode(Text,Comment);
        VarName = sprintf('R.Options.%s',OptionNamesToSet{ct});
        if isa(Options,'mor.BalancedTruncationOptions') && any(strcmpi(OptionNamesToSet{ct},["InputWeight" "OutputWeight"]))
            Text = controllib.internal.codegen.appendMATLABCode(Text,evalin('base',OptionValuesToSet{ct}),VarName);
        else
            Text = controllib.internal.codegen.appendMATLABCode(Text,OptionValuesToSet{ct},VarName);
        end
    end
end