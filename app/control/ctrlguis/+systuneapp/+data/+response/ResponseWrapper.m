classdef (Hidden) ResponseWrapper < handle & matlab.mixin.Copyable
    % Wrapper class for Responses
    
    % Copyright 2009-2013 The MathWorks, Inc.
    
    properties (SetObservable)
        Response      
    end
    properties (Transient)
        EditHandles = [];
    end
    
   methods       
       function Name = getName(this)
           Name = this.Response.Name;
       end    
       function hText = getDisplayPreviewText(this)
           hText = this.Response.getDisplayPreviewText;
       end    
   end                         

   methods(Hidden)
       function l = addListenerToSyncData(this,fcn)
           l = addlistener(this,'Response','PostSet',fcn);
       end
   end
end
