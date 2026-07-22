function [isInList,ListIndex] = findItemIndexInList(item,list)
% Utility function to check whether an ITEM ISINLIST (true or false) in the
% LIST. LISTINDEX is the index of found item.

% Copyright 2013 The MathWorks, Inc.

    ListIndex = cellfun(@(x) isequaln(x,item),list);
    isInList = any(ListIndex);
end