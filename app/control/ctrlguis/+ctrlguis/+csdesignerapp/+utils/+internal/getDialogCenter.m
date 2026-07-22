function DialogCenter = getDialogCenter(Dialog)  

% GETTOOLGROUPCENTER  Return the center of dialog so that diagnostic
% viewer is centered with respect to it.
%

sz = Dialog.Peer.getWrappedComponent.getSize;
sz = [sz.getWidth, sz.getHeight];
loc = Dialog.Peer.getWrappedComponent.getLocation;
loc = [loc.getX, loc.getY];
DialogCenter = loc+0.5*sz;