function h = bodemenu(this,Anchor,MenuType)
%BODEMENU  Creates menus specific to the Bode editor.
% 
%   H = BODEMENU(EDITOR,ANCHOR,MENUTYPE) creates a menu item, related
%   submenus, and associated listeners.  The menu is attached to the 
%   parent object with handle ANCHOR.

%   Author(s): P. Gahinet, N. Hickey
%   Copyright 1986-2023 The MathWorks, Inc.

switch MenuType
   
   case 'magphase'
      % Mag and phase submenus
      h1 = uimenu(Anchor,'Label', ...
          getString(message('Control:compDesignTask:strMagnitude')), ...
         'Checked',this.MagVisible);
      h2 = uimenu(Anchor,'Label', ...
          getString(message('Control:compDesignTask:strPhase')), ...
         'Checked',this.PhaseVisible);
      h = [h1;h2];
      set(h,'Callback',{@LocalShowMagPhase this h})
      
      lsnr = [addlistener(this,'MagVisible',...
            'PostSet',@(es,ed)LocalSetCheck(es,h1,this)) ; ...
            addlistener(this,'PhaseVisible',...
            'PostSet',@(es,ed)LocalSetCheck(es,h2,this))];
      set(h1,'UserData',lsnr)  % Anchor listeners for persistency
      
end

%----------------------------- Listener callbacks ----------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%
%%% LocalShowMagPhase %%%
%%%%%%%%%%%%%%%%%%%%%%%%%
function LocalShowMagPhase(hSrc,~,Editor,hMagPhase)
% Callbacks for Mag/Phase submenus

idxSrc = find(hSrc==hMagPhase);

% Determine new states of mag/phase menus
isOn = strcmp(get(hMagPhase,'Checked'),'on');
isOn(idxSrc) = ~isOn(idxSrc);

if any(isOn)
    % Set corresponding mode
    States = {'off','on'};
    if idxSrc==1
        Editor.MagVisible = States{1+isOn(1)};
    else
        Editor.PhaseVisible = States{1+isOn(2)};
    end
end


%%%%%%%%%%%%%%%%%%%%%
%%% LocalSetCheck %%%
%%%%%%%%%%%%%%%%%%%%%
function LocalSetCheck(es,hMenu,this)
% Callbacks for property listeners
set(hMenu,'Checked',this.(es.Name));
