classdef ControllerModule < BaseModule
    % CONTROLLERMODULE 控制器设计模块
    
    properties
        name = '控制器设计'
        description = '基于系统模型的控制器设计'
        
        % 控制器UI管理器
        controller_uis
        
        % 当前激活的UI
        current_ui
        
        % 控制器类型列表
        controller_types = {
            'PID',      'PID控制器';
            'Fuzzy',    '模糊控制器';
            'MPC',      '模型预测控制';
            'LQR',      'LQR最优控制'
        };
    end
    
    methods
        function obj = ControllerModule(parent, app_handle)
            % 构造函数
            % 初始化控制器UI
            obj = obj@BaseModule(parent, app_handle);
            obj.controller = PIDController();
            obj.controller_uis = containers.Map();
            obj.initializeControllerUIs();
            obj.controller = PIDController();
            
            % 默认显示PID控制器
            obj.switchToController('PID');
        end
        
        function initializeControllerUIs(obj)
            % 初始化所有控制器UI
            obj.controller_uis('PID') = PIDControllerUI(obj.panel, obj.app_handle);
            obj.controller_uis('Fuzzy') = FuzzyControllerUI(obj.panel, obj.app_handle);
            obj.controller_uis('MPC') = MPCControllerUI(obj.panel, obj.app_handle);
            obj.controller_uis('LQR') = LQRControllerUI(obj.panel, obj.app_handle);
        end
        
        function createUI(obj)
            % 创建UI
            obj.panel = uipanel('Parent', obj.parent, ...
                'Title', '控制器设计', ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.96, 0.96, 0.96], ...
                'Visible', 'off');
            
            % 创建控制区域
            control_panel = uipanel('Parent', obj.panel, ...
                'Title', '控制器选择', ...
                'Position', [0.01, 0.85, 0.98, 0.14], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 控制器类型选择
            y_pos = 30;
            
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '控制器类型:', ...
                'Position', [20, y_pos, 70, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92], ...
                'FontWeight', 'bold');
            
            obj.controls.controller_type = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', obj.controller_types(:, 2), ...
                'Value', 1, ...
                'Position', [90, y_pos, 120, 25], ...
                'BackgroundColor', 'white', ...
                'Callback', @(~,~) obj.onControllerTypeChanged());
            
            % 信息文本
            obj.controls.info_text = uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '请选择控制器类型', ...
                'Position', [750, y_pos-5, 200, 30], ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 控制器内容区域
            content_panel = uipanel('Parent', obj.panel, ...
                'Position', [0.01, 0.01, 0.98, 0.83], ...
                'BorderType', 'none', ...
                'BackgroundColor', [0.96, 0.96, 0.96]);
        end
        
        function onControllerTypeChanged(obj)
            % 控制器类型改变回调
            controller_idx = get(obj.controls.controller_type, 'Value');
            controller_name = obj.controller_types{controller_idx, 1};
            
            % 切换到选择的控制器
            obj.switchToController(controller_name);
        end
        
        function switchToController(obj, controller_name)
            % 切换到指定的控制器UI
            if ~isKey(obj.controller_uis, controller_name)
                return;
            end
            
            % 隐藏当前UI
            if ~isempty(obj.current_ui)
                obj.current_ui.hide();
            end
            
            % 显示新的UI
            obj.current_ui = obj.controller_uis(controller_name);
            obj.current_ui.show();
            
            % 设置系统模型
            if ~isempty(obj.app_handle) && isfield(obj.app_handle, 'system_model') && ~isempty(obj.app_handle.system_model)
                obj.setSystemModel(obj.app_handle.system_model);
            end
            
            % 更新信息
            obj.updateInfo();
        end
        
        function setSystemModel(obj, system_model)
            % 设置系统模型
            if isempty(obj.current_ui)
                return;
            end
            
            if ~isempty(obj.current_ui.controller)
                obj.current_ui.controller.setPlantModel(system_model);
                obj.current_ui.updateUI();
            end
            
            obj.updateInfo();
        end
        
        function updateInfo(obj)
            % 更新信息显示
            if isempty(obj.current_ui) || isempty(obj.current_ui.controller) || isempty(obj.current_ui.controller.plant_model)
                set(obj.controls.info_text, 'String', '请先设置系统模型', 'ForegroundColor', 'blue');
            else
                [num, den] = tfdata(obj.current_ui.controller.plant_model, 'v');
                sys_info = sprintf('系统模型: %d阶/%d阶', length(num)-1, length(den)-1);
                set(obj.controls.info_text, 'String', sys_info, 'ForegroundColor', 'green');
            end
        end
        
        function designController(obj)
            % 设计控制器
            if ~isempty(obj.current_ui)
                obj.current_ui.designController();
            end
        end
        
        function simulateControl(obj)
            % 仿真控制
            if ~isempty(obj.current_ui)
                obj.current_ui.simulateControl();
            end
        end
        
        function updateUI(obj)
            % 更新UI
            if ~isempty(obj.current_ui)
                obj.current_ui.updateUI();
            end
            obj.updateInfo();
        end
        
        function process(obj)
            % 处理数据
            obj.designController();
        end
    end
end