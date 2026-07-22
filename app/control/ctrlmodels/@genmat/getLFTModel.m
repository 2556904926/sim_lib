function [H,B,S,R] = getLFTModel(M,varargin)
%GETLFTMODEL  Decomposes a generalized matrix.
%
%   [H,B,S] = GETLFTMODEL(M) returns the matrices H,S and the Control 
%   Design blocks B that make up the generalized matrix M. The matrix H  
%   describes how the blocks B are connected together and the matrix S 
%   contains block offsets. The model M is related to H,B,S by
%        M = LFT( H , blkdiag(B{:}) - S ) .
%
%   See also GENMAT, UMAT, CONTROLDESIGNBLOCK, LFT.

%   Author(s): P. Gahinet
%   Copyright 1986-2011 The MathWorks, Inc.

% Undocumented syntax: [H,B,S,R] = getLFTModel(M) for uncertain blocks.
Data = M.Data_;
if numel(Data)~=1
   ctrlMsgUtils.error('Control:general:RequiresSingleModel','getLFTModel')
end
H = Data.IC;
[B,R,S] = getBlockList(Data.Blocks);
if nargout<4 && ~isempty(R)
   [nw,nz] = size(S);
   H = lft(H,R,nw,nz);
end
