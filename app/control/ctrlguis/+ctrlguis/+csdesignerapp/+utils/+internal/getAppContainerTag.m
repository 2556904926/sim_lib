function tag = getAppContainerTag(tagType)
% tag = ctrlguis.csdesignerapp.utils.internal.getAppContainerTag('ResponsePlot')
%
%   "tag" is a string that represents the tag for the FigureDocumentGroup
%   and FigureDocuments for response plots in the Control System Designer
%   App Container

% Copyright 2020 The MathWorks, Inc.

arguments
    tagType char {mustBeMember(tagType,{'ResponsePlotDocumentGroup','HomeTabGroup','HomeTab',...
                    'BodeEditorDocumentGroup','BodeEditorTabGroup','BodeEditorTab',...
                    'RootLocusEditorDocumentGroup','RootLocusEditorTabGroup','RootLocusEditorTab',...
                    'NicholsEditorDocumentGroup','NicholsEditorTabGroup','NicholsEditorTab'})}
end

tag = "CSD_" + string(tagType);
end