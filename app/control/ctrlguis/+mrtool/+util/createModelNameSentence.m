function Sentence = createModelNameSentence(ModelName)
arguments
    ModelName (:,1) string
end
% creates a sentence if there are 3 or less model names. Otherwise return
% string for the number of models

Sentence = "";
if length(ModelName)<4    
    for ct=1:length(ModelName)-1
        Sentence = Sentence+ModelName(ct)+", ";
    end
    Sentence = Sentence+ModelName(end);
else
    Sentence = mat2str(length(ModelName));    
end