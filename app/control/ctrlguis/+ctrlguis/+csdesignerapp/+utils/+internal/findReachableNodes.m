function nodeIdx = findReachableNodes(M, StartNodeIdx)                   
% FINDREACHABLENODES - Find the reachable nodes in a graph.
%
% Input:
% - M: An n-by-n Boolean Adjacency matrix. M(i,j) == 1 if there is an
%   edge from the i-th node to the j-th node. (1<=i,j<=n).
% - StartNodeIdx: A Boolean vector. StartNodeIdx(i) == 1 if there is the 
%   i-th node is a source.
%
% Output:
% - nodeIdx: A Boolean vector. nodeIdx(i) == 1, if the i-th node can be 
%   structrually reached from any of the source.

% Copyright 2015 The MathWorks, Inc.

numBlocks = size(M,1);

assert(numBlocks == size(M,2));
assert(numBlocks == size(StartNodeIdx,1));
assert(size(StartNodeIdx,2) == 1);

nodeIdx = false(numBlocks, 1);

if numBlocks
	% Logicalize
	if islogical(M)
		MS = M;
	else
		MS = (M~=0);
	end
	if ~islogical(StartNodeIdx)		
		StartNodeIdx = (StartNodeIdx~=0);
	end
	
	% Preprocess for Dulmage-Mendelsohn decomposition
	MS(1:numBlocks+1:numBlocks^2) = true;
	
	% Find structurally reachable blocks
	xc = false(numBlocks + 1, 1);
	[p,~,r] = dmperm([MS'  StartNodeIdx; true(1, numBlocks + 1)]);
	ipd = find(p == numBlocks + 1);
	ir =  find(r <= ipd, 1, 'last');
	xc(p(r(ir):r(ir+1)-1)) = true;
	nodeIdx = xc(1:end-1);	
end
end