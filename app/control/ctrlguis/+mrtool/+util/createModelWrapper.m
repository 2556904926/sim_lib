function ModelWrappers = createModelWrapper(Models,VariableNames)
% Models are cell arrays and it returns model wrappers as arrays. This
% function decides the name. It takes the name from name field. Then uses
% inputname. At last, it uses untitled

ModelWrappers = mrtool.data.ModelWrapper.empty(length(Models),0);
for ct=1:length(Models)
    if ~isempty(VariableNames{ct})
        varName = VariableNames{ct};
    else
        varName = 'Untitled';
    end
    ModelWrappers(ct) = mrtool.data.ModelWrapper(varName,Models{ct});
end

