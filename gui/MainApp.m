classdef MainApp < handle
    % MAINAPP 主应用程序
    
    properties
        % 主窗口
        fig
        
        % 模块
        current_module
        modules
        
        % 导航
        navigation
        
        % 数据
        system_model
        raw_data
    end
    
    methods
        function obj = MainApp()
            % 构造函数
            obj.createMainWindow();
            obj.createNavigation();
            obj.createModules();
            
            % 默认显示第一个模块
            obj.switchModule('system_id');
        end
        
        function createMainWindow(obj)
            % 创建主窗口
            obj.fig = figure('Name', '系统辨识与控制器设计平台', ...
                'NumberTitle', 'off', ...
                'Position', [100, 50, 1400, 800], ...
                'MenuBar', 'none', ...
                'ToolBar', 'figure', ...
                'CloseRequestFcn', @(~,~) obj.closeApp());
        end
        
        function createNavigation(obj)
            % 创建导航面板
            nav_panel = uipanel('Parent', obj.fig, ...
                'Title', '导航', ...
                'Position', [0.01, 0.90, 0.98, 0.09], ...
                'BackgroundColor', [0.9, 0.95, 1.0]);
            
            % 导航按钮
            buttons = {
                'system_id',    '系统辨识';
                'controller',   '控制器设计';
                'help',         '帮助'
            };
            
            for i = 1:size(buttons, 1)
                uicontrol('Parent', nav_panel, ...
                    'Style', 'pushbutton', ...
                    'String', buttons{i, 2}, ...
                    'Position', [50 + (i-1)*180, 10, 150, 35], ...
                    'FontSize', 11, ...
                    'FontWeight', 'bold', ...
                    'Tag', buttons{i, 1}, ...
                    'Callback', @(~,~) obj.switchModule(buttons{i, 1}));
            end
            
            % 状态显示
            obj.navigation.status = uicontrol('Parent', nav_panel, ...
                'Style', 'text', ...
                'String', '就绪', ...
                'Position', [600, 10, 300, 35], ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.9, 0.95, 1.0]);
        end
        
        function createModules(obj)
            % 创建模块
            modules_panel = uipanel('Parent', obj.fig, ...
                'Position', [0.01, 0.01, 0.98, 0.88], ...
                'BorderType', 'none', ...
                'BackgroundColor', [0.96, 0.96, 0.96]);
            
            % 创建系统辨识模块
            obj.modules.system_id = SystemIDModule(modules_panel, obj);
            
            % 创建控制器设计模块
            obj.modules.controller = ControllerModule(modules_panel, obj);
            
            % 创建帮助模块
            obj.modules.help = obj.createHelpModule(modules_panel);
        end
        
        function help_module = createHelpModule(obj, parent)
            % 创建帮助模块
            help_panel = uipanel('Parent', parent, ...
                'Title', '帮助', ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.96, 0.96, 0.96], ...
                'Visible', 'off');
            
            % 帮助文本
            help_text = {
                '=== 系统辨识与控制器设计平台 ===';
                '';
                '使用说明:';
                '1. 在"系统辨识"模块中加载数据并进行系统辨识';
                '2. 在"控制器设计"模块中基于辨识结果设计控制器';
                '3. 可以导出模型和控制器供其他用途';
                '';
                '主要功能:';
                '  • 系统辨识: 基于输入输出数据辨识系统模型';
                '  • 控制器设计: 支持PID、模糊、MPC等多种控制器';
                '  • 仿真验证: 验证控制器性能';
                '  • 导出功能: 导出MAT文件或Simulink模型';
                '';
                '注意事项:';
                '  • 数据格式: 时间向量t，输入向量u，输出向量y';
                '  • 采样时间: 需要均匀采样';
                '  • 系统阶次: 根据系统特性选择合适的阶次';
                '';
                '快捷键:';
                '  • Ctrl+S: 保存当前结果';
                '  • Ctrl+E: 导出结果';
                '  • F1: 显示帮助';
                '';
                '作者: Your Name';
                '版本: 1.0.0';
            };
            
            uicontrol('Parent', help_panel, ...
                'Style', 'text', ...
                'String', help_text, ...
                'Position', [20, 20, 800, 600], ...
                'FontSize', 10, ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.96, 0.96, 0.96]);
            help_module = struct(...
                'panel', help_panel, ...
                'name', 'help', ...
                'show', @() set(help_panel, 'Visible', 'on'), ...
                'hide', @() set(help_panel, 'Visible', 'off'));
        end
        
        function switchModule(obj, module_name)
            % 切换模块
            if ~isempty(obj.current_module)
                obj.current_module.hide();
            end
            
            switch module_name
                case 'system_id'
                    obj.current_module = obj.modules.system_id;
                case 'controller'
                    obj.current_module = obj.modules.controller;
                case 'help'
                    obj.current_module = obj.modules.help;
                    set(obj.modules.help.panel, 'Visible', 'on');
                    return;
            end
            
            obj.current_module.show();
            set(obj.navigation.status, 'String', ...
                sprintf('当前模块: %s', obj.current_module.name));
        end
        
        function updateSystemModel(obj, sys_model)
            % 更新系统模型
            obj.system_model = sys_model;
            
            % 通知控制器模块
            if isa(obj.modules.controller, 'ControllerModule')
                obj.modules.controller.setSystemModel(sys_model);
            end
            
            set(obj.navigation.status, 'String', ...
                sprintf('系统模型已更新，可以开始控制器设计'), ...
                'ForegroundColor', 'green');
        end
        
        function updateStatus(obj, message, color)
            % 更新状态
            if nargin < 3
                color = 'black';
            end
            
            set(obj.navigation.status, 'String', message, 'ForegroundColor', color);
            drawnow;
        end
        
        function closeApp(obj)
            % 关闭应用程序
            choice = questdlg('确定要退出吗？', '确认退出', '是', '否', '否');
            
            if strcmp(choice, '是')
                delete(obj.fig);
            end
        end
        
        function run(obj)
            % 运行应用程序
            uiwait(obj.fig);
        end
    end
end