function [H,B,S,R] = getLFTModel(sys,varargin)
%GETLFTMODEL  Decomposes a generalized LTI model.
%
%   Generalized LTI models (GENSS, GENFRD, USS, UFRD) are models of the form 
%      SYS = LFT( H , blkdiag(B{:}) - S )
%   where
%      * B is a list of Control Design blocks 
%      * H is a SS or FRD model describing how the blocks B are connected 
%        together
%      * S is a numeric array (block offsets).
%
%   [H,B,S] = GETLFTMODEL(SYS) extracts the components H,B,S making up the 
%   generalized LTI model SYS (see GENLTI). The Control Design blocks entering 
%   SYS are listed in the cell array B and some blocks may appear multiple times.
%
%   See also GENSS, GENFRD, USS, UFRD, GENLTI, CONTROLDESIGNBLOCK, LFT.

%   Author(s): P. Gahinet
%   Copyright 1986-2010 The MathWorks, Inc.

% Undocumented syntax: [H,B,S,R] = getLFTModel(sys) for uncertain blocks.
% REVISIT: Need to implement setLFTModel because of offsets!
Data = sys.Data_;
if numel(Data)~=1
   ctrlMsgUtils.error('Control:general:RequiresSingleModel','getLFTModel')
end
DH = Data.IC;

% Get block list and transformations
[B,R,S] = getBlockList(Data.Blocks);
if nargout<4 && ~isempty(R)
   % Absorb R into H
   [nyz,nuw] = iosize(DH);
   [nw,nz] = size(S);
   DH = lft(DH,DH.createGain(R),nuw-nw+1:nuw,nyz-nz+1:nyz,1:nz,1:nw);
end

% Construct H
if isa(sys,'FRDModel')
   H = frd.make(DH);
   H.TimeUnit = sys.TimeUnit;
   H = chgFreqUnit(H,sys.FrequencyUnit);
else
   H = ss.make(DH);
   H.TimeUnit = sys.TimeUnit;
end
H = transferInputOutput(H,sys,0,0);
