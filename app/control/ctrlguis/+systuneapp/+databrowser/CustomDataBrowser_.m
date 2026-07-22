classdef CustomDataBrowser_ < handle
    % Undocked Data Browser for Control System Tuner App, adapted from Data
    % Browser Showcase
    
    % Copyright 2020-2021 The Mathworks, Inc.
    
    properties (Hidden,SetAccess=private)
        ControllerDataBrowser
        TuningGoalDataBrowser
        ResponseDataBrowser
        DesignDataBrowser
        DisplayDataBrowser
    end

    properties(Access=private)
        App
    end
    
    methods
        function this = CustomDataBrowser_(app)
            import matlab.ui.internal.*;
            import matlab.ui.internal.databrowser.*;
            
            this.App = app;

            %% Construct an AppContainer
            % Construct the app
            
            %% Add ControllerDataBrowser
            this.ControllerDataBrowser = systuneapp.databrowser.ControllerDataBrowser_('ControllerDB',this.App);
            addToAppContainer(this.ControllerDataBrowser,this.App.AppContainer);
            %% Add TuningGoalDataBrowser
            this.TuningGoalDataBrowser = systuneapp.databrowser.TuningGoalDataBrowser_('TuningGoalDB',this.App);
            addToAppContainer(this.TuningGoalDataBrowser, this.App.AppContainer);
            %% Add ResponseDataBrowser
            this.ResponseDataBrowser = systuneapp.databrowser.ResponseDataBrowser_('ResponseDB',this.App);
            addToAppContainer(this.ResponseDataBrowser,this.App.AppContainer);
            %% Add DesignDataBrowser
            this.DesignDataBrowser = systuneapp.databrowser.DesignDataBrowser_('DesignDB',this.App);
            addToAppContainer(this.DesignDataBrowser, this.App.AppContainer);
            
            %% Add Display Preview
            this.DisplayDataBrowser = systuneapp.databrowser.PreviewPanel_(...
                'DisplayDB',getString(message('Control:systunegui:DataBrowserTitleDisplay')));
            addToAppContainer(this.DisplayDataBrowser, this.App.AppContainer);
            
            %% Connect data browsers with Preview Panel
            monitor(this.DisplayDataBrowser, this.ControllerDataBrowser);
            monitor(this.DisplayDataBrowser, this.TuningGoalDataBrowser);
            monitor(this.DisplayDataBrowser, this.ResponseDataBrowser);
            monitor(this.DisplayDataBrowser, this.DesignDataBrowser);            
        end
        
        function delete(this)
            delete(this.ControllerDataBrowser);
            delete(this.TuningGoalDataBrowser);
            delete(this.ResponseDataBrowser);
            delete(this.DesignDataBrowser);
            delete(this.DisplayDataBrowser);
        end
    end
end