classdef RootLocusUncertain < handle
    % @RootLocusUncertain class definition
    
    %   Copyright 1986-2014 The MathWorks, Inc.
    properties (SetObservable)
        Parent
        Roots  
        RootsPatch
        RootsLine
        ZLevel = -5.5;
        FaceColor = [0.9804 .9*0.9804 0.8235];
        Visible
    end
    
    methods
        %%
        function this = RootLocusUncertain(Parent)
            % Constructor
            this.Parent = Parent;
            
        end
        
        %%
        function setData(this,roots)
            this.Roots = roots;
            this.drawLine;
        end
        
        %%
        function setZLevel(this,ZLevel)
            this.ZLevel = ZLevel;
        end
        
        %%
        function drawPatch(this)
            if isempty(this.RootsPatch)
                RootLocusAxes = this.Parent.Axes.getAxes;
                this.RootsPatch = patch(nan,nan,this.ZLevel,'Parent', RootLocusAxes);
                controllib.plot.internal.utils.setColorProperty(this.RootsPatch,...
                    "FaceColor",this.FaceColor);
            end
            
            X = real(this.Roots);
            Y = imag(this.Roots);
            if length(X) > 1;
                try
                k = convhull(X,Y);           
                set(this.RootsPatch,'XData', X(k), 'YData', Y(k),'ZData',ones(size(X(k)))*this.ZLevel);
                catch
                    set(this.RootsPatch,'XData', X, 'YData', Y,'ZData',ones(size(X))*this.ZLevel);
                end
            else
                set(this.RootsPatch,'XData', nan, 'YData', nan,'ZData',this.ZLevel);
            end
       
        end
        
         function drawLine(this)
            if isempty(this.RootsLine)
                RootLocusAxes = this.Parent.Axes.getAxes;
                this.RootsLine = line(nan,nan,this.ZLevel,'Parent', RootLocusAxes, ...
                    'LineStyle','none','marker','s');
                controllib.plot.internal.utils.setColorProperty(this.RootsLine,...
                    ["MarkerEdgeColor","MarkerFaceColor"],this.FaceColor);
            end
            
            if isVisible(this)
                X = real(this.Roots);
                Y = imag(this.Roots);
                if length(X) > 1;
                    set(this.RootsLine,'XData', X, 'YData', Y,'ZData',ones(size(X))*this.ZLevel,'visible','on');
                else
                    set(this.RootsLine,'XData', nan, 'YData', nan,'ZData',this.ZLevel,'visible','off');
                end
            else
                set(this.RootsLine,'XData', nan, 'YData', nan,'ZData',this.ZLevel,'visible','off');
            end
       
         end
        
         function b = isVisible(this)
             if strcmpi(this.Visible,'on')
                 b = true;
             else
                 b= false;
             end
             
         end
         
         function set.Visible(this,value)
             this.Visible = value;
             drawLine(this);
         end
         
         function setColor(this,Color)
             if isnumeric(Color)
                % Convert numeric color
                hsvcolor = rgb2hsv(Color);
                Color = hsv2rgb(hsvcolor.*[1,.2,1]);
                this.FaceColor = Color;
             else
                % Convert semantic color
                this.FaceColor = controllib.plot.internal.utils.convertSemanticColor(...
                    Color,"tertiary");
             end
             if ~isempty(this.RootsPatch)
                 controllib.plot.internal.utils.setColorProperty(this.RootsPatch,...
                     "FaceColor",this.FaceColor);
             end
             if ~isempty(this.RootsLine)
                 controllib.plot.internal.utils.setColorProperty(this.RootsLine,...
                     ["MarkerEdgeColor","MarkerFaceColor"],this.FaceColor);
             end
                 
         end
        
    end
    
    
    methods (Access = private)
        
        %%
        
        
    end
end

%--------------------------------------------------------------------------


