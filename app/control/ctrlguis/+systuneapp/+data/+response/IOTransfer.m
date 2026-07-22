classdef (Hidden) IOTransfer < systuneapp.data.response.Generic
    % Class for input output transfer responses
    
    % Copyright 2009-2014 The MathWorks, Inc.
    
    properties
 % Input signal names (string or string vector).
      %
      % In MATLAB, you can refer to any input of the control system model.
      % In Simulink, you can refer to any signal listed in the slTunable 
      % interface as "Controls", "Measurements", or "IOs" of type 'in',
      % 'inout', or 'outin' (see slTunable for details).
      Input
      
      % Output signal names (string or string vector).
      %
      % In MATLAB, you can refer to any output of the control system model.
      % In Simulink, you can refer to any signal listed in the slTunable 
      % interface as "Controls", "Measurements", or "IOs" of type 'out',
      % 'inout', or 'outin' (see slTunable for details).
      Output
      
    end
    
   methods
       % Constructor
       function this = IOTransfer(InputName,OutputName)
           narginchk(2,2)
           try
               this.Input = InputName;
               this.Output = OutputName;
           catch ME
               throw(ME)
           end
       end             
       
       function this = set.Input(this,Value)
           % SET function for Input
           [ok,this.Input] = ltipack.isNameList(Value);
           if ~ok
               error(message('Controllib:general:UnexpectedError','Invalid input channel name specified.'))
           end
       end
       
       function this = set.Output(this,Value)
           % SET function for Output
           [ok,this.Output] = ltipack.isNameList(Value);
           if ~ok
               error(message('Controllib:general:UnexpectedError','Invalid output channel name specified.'))
           end
       end       
         
       function T = getValue(this,CL)
           % Computes scaled closed-loop transfer from inputs to outputs
           T = getIOTransfer(CL,this.Input,this.Output,this.Openings,this.Models);
           T = sminreal(getValue(T,'usample'));
           T.Name = this.Name;
       end
       
       function DisplayText = getDisplayPreviewText(this)
           % I/O Transfer Function
           TypeSection = systuneapp.util.createDisplayText('type', ... 
               getString(message('Control:systunegui:ResponseTypeIOTransferFunction')));           
           % Name Label, Response Name
           NameSection = systuneapp.util.createDisplayText('line', ...
               getString(message('Control:systunegui:DisplayName')), this.Name);           
           % Input Label, Inputs
           InputSection = systuneapp.util.createDisplayText('section', ...               
               getString(message('Control:systunegui:DisplayInput')),this.Input);           
           % Output Label, Outputs
           OutputSection = systuneapp.util.createDisplayText('section', ...               
               getString(message('Control:systunegui:DisplayOutput')),this.Output);           
           % If exist, Opening Label, Openings
           OpeningsSection = systuneapp.util.createDisplayText('section', ...
                    getString(message('Control:systunegui:DisplayOpening')),this.Openings);
           % Construct Display Text
           DisplayText = [  TypeSection, ...
                            NameSection, ...
                            InputSection, ...
                            OutputSection, ...
                            OpeningsSection ];         
       end       
   end            
end
