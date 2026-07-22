function [NewItems,CommonItems,CommonItemIndexInAllItems,CommonItemIndexInItems,NewItemIndexinItems] = newOrCommonItemsInList(items,AllItems)
% Utility function to find new or common ITEMS in ALLITEMS. NEW ITEMS are
% ITEMS not in ALLITEMS and COMMONITEMS are in ALLITEMS. Both ITEMS and
% ALLTEMS are cell arrays.
%
% COMMONITEMINDEXINALLITEMS: indices of COMMONITEMS in ALLITEMS list. 
% COMMONITEMINDEXINITEMS: indices of COMMONITEMS in ITEMS list.

% Copyright 2013 The MathWorks, Inc.

    NewItems = cell(0,1);
    CommonItems = cell(0,1);
    CommonItemIndexInAllItems = zeros(0,1);
    CommonItemIndexInItems = zeros(0,1);
    NewItemIndexinItems = zeros(0,1);

    % check each item already in the list
    for ct=1:length(items)
        CurrentItem = items(ct);
        [isInList,ListIndex] = systuneapp.util.findItemIndexInList(CurrentItem,AllItems);
        if isInList
            % if in the list, item is common
            CommonItems = vertcat(CommonItems,CurrentItem);
            CommonItemIndexInAllItems = vertcat(CommonItemIndexInAllItems,find(ListIndex,1)); 
            CommonItemIndexInItems = vertcat(CommonItemIndexInItems,ct);
        else
            % if not in the list, item is new
            NewItems = vertcat(NewItems,CurrentItem);
            NewItemIndexinItems = vertcat(NewItemIndexinItems,ct);
        end
    end
end