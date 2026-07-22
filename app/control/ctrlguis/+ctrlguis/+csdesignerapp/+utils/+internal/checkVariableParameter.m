function [List VariableInfo] = checkVariableParameter(TunedBlocks)
% CHECKVARIABLEPARAMETER  check whether the same variable parameter will be
% written multiple times when blocks are updated by control design tools.
% Return
%   List: list of duplicated variable names with block path in cell array.
%   Empty if no duplicated variables are found.
%   VariableInfo: structure of variable information to be used by routine
%   updateBlockParameter
 
% Author(s): R. Chen
% Copyright 2005-2010 The MathWorks, Inc.

NumOfBlocks = length(TunedBlocks);
strAll = {};
blkAll = {};
IsVariable = cell(NumOfBlocks,1);
wksp = cell(NumOfBlocks,1);
IsDuplicated = cell(NumOfBlocks,1);
len = zeros(NumOfBlocks,1);
%% For each block, obtain variable information for each parameter
wkspAll = '';
for ct = 1:NumOfBlocks
    % find tunable parameters
    blk = getPath(TunedBlocks(ct));
    Parameters = getParameters(TunedBlocks(ct));
    TunableIndex = find(strcmp({Parameters.Tunable},'on'));
    lenBlock = length(TunableIndex);
    % for each parameter, check whether it is a variable in workspace
    if lenBlock>0
        strBlock = cell(lenBlock,1);
        IsVariableBlock = false(lenBlock,1);
        wkspBlock = repmat('N',lenBlock,1);
        wkspBlockFull = cell(lenBlock,1);
        for ct2 = 1:lenBlock
            % get parameter string 
            strBlock{ct2} = get_param(blk,Parameters(TunableIndex(ct2)).Name);
            % check whether it is a variable
            try
                wks = slResolve(strBlock{ct2},blk,'context');
                IsVariableBlock(ct2) = true;
                wkspBlock(ct2) = wks(1); % 'M' for model and 'G' for base workspace
                wkspBlockFull(ct2) = {wks};
            catch %#ok<CTCH>
                wkspBlockFull(ct2) = {'Numerical'};
            end
        end
        IsVariable(ct) = {IsVariableBlock};
        wksp(ct) = {wkspBlockFull};
        len(ct) = lenBlock;
        wkspAll = [wkspAll;wkspBlock]; %#ok<*AGROW>
        strAll = [strAll;strBlock];
        blkAll = [blkAll;repmat({blk},lenBlock,1)];
    end
end
IsVariableAll = cell2mat(IsVariable);
%% Find duplicated variables in workspaces
[IsDuplicatedG IsDuplicatedGblk] = getDuplicated('G',IsVariableAll,wkspAll,strAll,blkAll);
[IsDuplicatedM IsDuplicatedMblk] = getDuplicated('M',IsVariableAll,wkspAll,strAll,blkAll);
%% Prepare variable information
IsDuplicatedAll = IsDuplicatedG | IsDuplicatedM; 
offset = 0;
for ct=1:length(len)
    IsDuplicated{ct} = IsDuplicatedAll(offset+(1:len(ct)));
    offset = offset + len(ct);
end
VariableInfo = struct('IsVariable',IsVariable,'wksp',wksp,'IsDuplicated',IsDuplicated);
%% Prepare list of duplicated variables
List = '';
if ~isempty(IsDuplicatedGblk)
    msgG = sprintf('%s:\n\n',ctrlMsgUtils.message('Slcontrol:controldesign:PVbase'));
    for i=1:length(IsDuplicatedGblk)
        info = IsDuplicatedGblk{i};
        blks = sprintf(repmat('"%s", ',1,length(info)-1),info{2:end});
        blks(end-1:end) = '';
        msgG = [msgG sprintf('    %s\n',getString(message('Slcontrol:controldesign:SISOCheckVarParInBlocks',info{1},blks)))];
    end
    List = msgG;
end
if ~isempty(IsDuplicatedMblk)
    msgM = sprintf('%s:\n\n',ctrlMsgUtils.message('Slcontrol:controldesign:PVmodel'));
    for i=1:length(IsDuplicatedMblk)
        info = IsDuplicatedMblk{i};
        blks = sprintf(repmat('"%s", ',1,length(info)-1),info{2:end});
        blks(end-1:end) = '';
        msgM = [msgM sprintf('    %s\n',getString(message('Slcontrol:controldesign:SISOCheckVarParInBlocks',info{1},blks)))];
    end
    if isempty(List)
        List = msgM;    
    else
        List = sprintf('%s\n%s',List,msgM);
    end
end

%% local function
function [IsDuplicated Info] = getDuplicated(Scope,IsVariableAll,wkspAll,strAll,blkAll)
lenAll = length(IsVariableAll);
IsDuplicated = false(lenAll,1);
Index = find(IsVariableAll&(Scope==wkspAll));
str = strAll(Index);
len = length(str);
[~,~,idx] = unique(str,'first');
Info = {};
for i=1:len
    idxdup = (idx==i);
    if sum(idxdup)>1
        IsDuplicated(Index(idxdup)) = true;
        Info = [Info {[strAll(Index(find(idxdup,1)));blkAll(Index(idxdup))]}];
    end
end

