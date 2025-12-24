classdef ControllerModule < BaseModule
    % CONTROLLERMODULE 控制器设计模块
    
    properties
        name = '控制器设计'
        description = '基于系统模型的控制器设计'
        
        % 控制器
        controller
        
        % 绘图坐标轴
        axes_handles
        
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
            obj = obj@BaseModule(parent, app_handle);
            
            % 初始化为PID控制器
            obj.controller = PIDController();
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
                'Title', '设计参数', ...
                'Position', [0.01, 0.85, 0.98, 0.14], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 控制器选择
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
            
            % 设计方法（针对PID）
            obj.controls.method_label = uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '设计方法:', ...
                'Position', [220, y_pos, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92], ...
                'Visible', 'on');
            
            obj.controls.method = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', {'Ziegler-Nichols', 'Cohen-Coon', 'IMC', 'ITAE最优', '手动调节', '自动整定', '频域设计'}, ...
                'Value', 1, ...
                'Position', [280, y_pos, 100, 25], ...
                'BackgroundColor', 'white', ...
                'Visible', 'on');
            
            % 性能指标
            y_pos2 = y_pos - 35;
            
            % 上升时间
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '上升时间:', ...
                'Position', [20, y_pos2, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.rise_time = uicontrol('Parent', control_panel, ...
                'Style', 'edit', ...
                'String', '1.0', ...
                'Position', [80, y_pos2, 60, 25], ...
                'BackgroundColor', 'white');
            
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', 's', ...
                'Position', [145, y_pos2, 20, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 超调量
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '超调量:', ...
                'Position', [170, y_pos2, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.overshoot = uicontrol('Parent', control_panel, ...
                'Style', 'edit', ...
                'String', '5.0', ...
                'Position', [230, y_pos2, 60, 25], ...
                'BackgroundColor', 'white');
            
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '%', ...
                'Position', [295, y_pos2, 20, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 控制器类型（P/PI/PID）
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', 'PID类型:', ...
                'Position', [320, y_pos2, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92], ...
                'Visible', 'on');
            
            obj.controls.pid_type = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', {'PID', 'PI', 'P'}, ...
                'Value', 1, ...
                'Position', [380, y_pos2, 60, 25], ...
                'BackgroundColor', 'white', ...
                'Visible', 'on');
            
            % 控制按钮
            obj.controls.design = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '设计控制器', ...
                'Position', [460, y_pos-10, 100, 35], ...
                'BackgroundColor', [0.2, 0.5, 0.8], ...
                'ForegroundColor', 'white', ...
                'FontWeight', 'bold', ...
                'Callback', @(~,~) obj.designController());
            
            obj.controls.simulate = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '仿真', ...
                'Position', [570, y_pos-10, 80, 35], ...
                'BackgroundColor', [0.3, 0.7, 0.3], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.simulateControl());
            
            obj.controls.export = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '导出', ...
                'Position', [660, y_pos-10, 80, 35], ...
                'BackgroundColor', [0.8, 0.5, 0.2], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.exportController());
            
            % 手动调节参数面板
            obj.createManualTuningPanel(control_panel);
            
            % 信息文本
            obj.controls.info_text = uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '请先加载系统模型', ...
                'Position', [750, y_pos-5, 200, 30], ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 结果显示区域
            results_panel = uipanel('Parent', obj.panel, ...
                'Title', '设计结果', ...
                'Position', [0.01, 0.01, 0.98, 0.83], ...
                'BackgroundColor', 'white');
            
            % 创建绘图坐标轴
            obj.createAxes(results_panel);
        end
        
        function createManualTuningPanel(obj, parent)
            % 创建手动调节面板
            tuning_panel = uipanel('Parent', parent, ...
                'Title', '手动调节参数', ...
                'Position', [0.01, -0.25, 0.98, 0.35], ...
                'BackgroundColor', [0.95, 0.95, 0.95], ...
                'Visible', 'off');
            
            obj.controls.tuning_panel = tuning_panel;
            
            % Kp调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Kp:', ...
                'Position', [20, 40, 30, 20], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.kp_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 10, 'Value', 1, ...
                'Position', [50, 40, 150, 20]);
            
            obj.controls.kp_value = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', 'String', '1.0', ...
                'Position', [210, 40, 60, 25], ...
                'Callback', @(~,~) obj.onManualParamChanged('kp'));
            
            % Ti调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Ti:', ...
                'Position', [20, 10, 30, 20], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.ti_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0.1, 'Max', 10, 'Value', 1, ...
                'Position', [50, 10, 150, 20]);
            
            obj.controls.ti_value = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', 'String', '1.0', ...
                'Position', [210, 10, 60, 25], ...
                'Callback', @(~,~) obj.onManualParamChanged('ti'));
            
            % Td调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Td:', ...
                'Position', [280, 40, 30, 20], ...
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.td_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 5, 'Value', 0, ...
                'Position', [310, 40, 150, 20]);
            
            obj.controls.td_value = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', 'String', '0.0', ...
                'Position', [470, 40, 60, 25], ...
                'Callback', @(~,~) obj.onManualParamChanged('td'));
            
            % 应用按钮
            obj.controls.apply_tuning = uicontrol('Parent', tuning_panel, ...
                'Style', 'pushbutton', ...
                'String', '应用调节', ...
                'Position', [540, 25, 80, 30], ...
                'BackgroundColor', [0.3, 0.6, 0.3], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.applyManualTuning());
            
            % 滑块回调
            set(obj.controls.kp_slider, 'Callback', @(~,~) obj.onSliderChanged('kp'));
            set(obj.controls.ti_slider, 'Callback', @(~,~) obj.onSliderChanged('ti'));
            set(obj.controls.td_slider, 'Callback', @(~,~) obj.onSliderChanged('td'));
        end
        
        function createAxes(obj, parent)
            % 创建绘图坐标轴
            obj.axes_handles = gobjects(4, 1);
            
            positions = [
                0.05, 0.55, 0.40, 0.40;  % 左上
                0.55, 0.55, 0.40, 0.40;  % 右上
                0.05, 0.05, 0.40, 0.40;  % 左下
                0.55, 0.05, 0.40, 0.40;  % 右下
            ];
            
            titles = {'闭环响应', '开环Bode图', '根轨迹', '控制信号'};
            
            for i = 1:4
                obj.axes_handles(i) = axes('Parent', parent, ...
                    'Position', positions(i, :), ...
                    'Box', 'on');
                grid(obj.axes_handles(i), 'on');
                title(obj.axes_handles(i), titles{i});
            end
        end
        
        function onControllerTypeChanged(obj)
            % 控制器类型改变回调
            controller_idx = get(obj.controls.controller_type, 'Value');
            controller_name = obj.controller_types{controller_idx, 1};
            
            % 更新控制器对象
            switch controller_name
                case 'PID'
                    obj.controller = PIDController();
                    set(obj.controls.method_label, 'Visible', 'on');
                    set(obj.controls.method, 'Visible', 'on');
                    set(obj.controls.pid_type, 'Visible', 'on');
                    
                case 'Fuzzy'
                    % 模糊控制器（需要Fuzzy Logic Toolbox）
                    if exist('fis', 'file')
                        obj.controller = FuzzyController();
                    else
                        warndlg('需要Fuzzy Logic Toolbox，使用PID控制器替代', '工具箱缺失');
                        obj.controller = PIDController();
                        set(obj.controls.controller_type, 'Value', 1);
                    end
                    set(obj.controls.method_label, 'Visible', 'off');
                    set(obj.controls.method, 'Visible', 'off');
                    set(obj.controls.pid_type, 'Visible', 'off');
                    
                case 'MPC'
                    % 模型预测控制（需要MPC Toolbox）
                    if exist('mpc', 'file')
                        obj.controller = MPCController();
                    else
                        warndlg('需要MPC Toolbox，使用PID控制器替代', '工具箱缺失');
                        obj.controller = PIDController();
                        set(obj.controls.controller_type, 'Value', 1);
                    end
                    set(obj.controls.method_label, 'Visible', 'off');
                    set(obj.controls.method, 'Visible', 'off');
                    set(obj.controls.pid_type, 'Visible', 'off');
                    
                case 'LQR'
                    % LQR控制器
                    obj.controller = LQRController();
                    set(obj.controls.method_label, 'Visible', 'off');
                    set(obj.controls.method, 'Visible', 'off');
                    set(obj.controls.pid_type, 'Visible', 'off');
            end
            
            % 更新UI
            obj.updateUI();
        end
        
        function updateUI(obj)
            % 更新UI
            if ~isempty(obj.controller) && ~isempty(obj.controller.plant_model)
                % 如果有系统模型，更新信息
                [num, den] = tfdata(obj.controller.plant_model, 'v');
                sys_info = sprintf('系统模型: %d阶/%d阶', length(num)-1, length(den)-1);
                set(obj.controls.info_text, 'String', sys_info, 'ForegroundColor', 'green');
            else
                set(obj.controls.info_text, 'String', '请先设置系统模型', 'ForegroundColor', 'blue');
            end
            
            % 根据控制器类型显示/隐藏手动调节面板
            if isa(obj.controller, 'PIDController')
                method_idx = get(obj.controls.method, 'Value');
                methods = {'ziegler_nichols', 'cohen_coon', 'imc', 'itae', 'manual', 'auto_tune', 'frequency'};
                
                if strcmp(methods{method_idx}, 'manual')
                    set(obj.controls.tuning_panel, 'Visible', 'on');
                    % 更新手动调节参数
                    obj.updateManualTuningParams();
                else
                    set(obj.controls.tuning_panel, 'Visible', 'off');
                end
            else
                set(obj.controls.tuning_panel, 'Visible', 'off');
            end
        end
        
        function updateManualTuningParams(obj)
            % 更新手动调节参数
            if ~isempty(obj.controller) && isa(obj.controller, 'PIDController')
                % 设置滑块和编辑框的值
                set(obj.controls.kp_slider, 'Value', obj.controller.Kp);
                set(obj.controls.kp_value, 'String', sprintf('%.3f', obj.controller.Kp));
                
                set(obj.controls.ti_slider, 'Value', obj.controller.Ti);
                set(obj.controls.ti_value, 'String', sprintf('%.3f', obj.controller.Ti));
                
                set(obj.controls.td_slider, 'Value', obj.controller.Td);
                set(obj.controls.td_value, 'String', sprintf('%.3f', obj.controller.Td));
            end
        end
        
        function onSliderChanged(obj, param)
            % 滑块改变回调
            switch param
                case 'kp'
                    value = get(obj.controls.kp_slider, 'Value');
                    set(obj.controls.kp_value, 'String', sprintf('%.3f', value));
                case 'ti'
                    value = get(obj.controls.ti_slider, 'Value');
                    set(obj.controls.ti_value, 'String', sprintf('%.3f', value));
                case 'td'
                    value = get(obj.controls.td_slider, 'Value');
                    set(obj.controls.td_value, 'String', sprintf('%.3f', value));
            end
        end
        
        function onManualParamChanged(obj, param)
            % 手动参数改变回调
            switch param
                case 'kp'
                    value = str2double(get(obj.controls.kp_value, 'String'));
                    if ~isnan(value) && value >= 0
                        set(obj.controls.kp_slider, 'Value', value);
                    end
                case 'ti'
                    value = str2double(get(obj.controls.ti_value, 'String'));
                    if ~isnan(value) && value > 0
                        set(obj.controls.ti_slider, 'Value', value);
                    end
                case 'td'
                    value = str2double(get(obj.controls.td_value, 'String'));
                    if ~isnan(value) && value >= 0
                        set(obj.controls.td_slider, 'Value', value);
                    end
            end
        end
        
        function applyManualTuning(obj)
            % 应用手动调节
            if ~isa(obj.controller, 'PIDController')
                return;
            end
            
            try
                Kp = str2double(get(obj.controls.kp_value, 'String'));
                Ti = str2double(get(obj.controls.ti_value, 'String'));
                Td = str2double(get(obj.controls.td_value, 'String'));
                
                if isnan(Kp) || isnan(Ti) || isnan(Td)
                    error('参数必须是数值');
                end
                
                % 更新控制器
                obj.controller.Kp = Kp;
                obj.controller.Ti = Ti;
                obj.controller.Td = Td;
                obj.controller.design_method = 'manual';
                obj.controller.createController();
                obj.controller.validate();
                
                % 更新显示
                obj.controller.plotResults(obj.axes_handles);
                
                % 更新信息
                perf = obj.controller.performance;
                info_str = sprintf('手动调节: Kp=%.3f, Ti=%.3f, Td=%.3f\nTr=%.3fs, OS=%.1f%%', ...
                    Kp, Ti, Td, perf.rise_time, perf.overshoot);
                set(obj.controls.info_text, 'String', info_str, 'ForegroundColor', 'green');
                
            catch ME
                set(obj.controls.info_text, 'String', ...
                    sprintf('调节失败: %s', ME.message), 'ForegroundColor', 'red');
                errordlg(ME.message, '手动调节错误');
            end
        end
        
        function designController(obj)
            % 设计控制器
            if isempty(obj.controller.plant_model)
                errordlg('请先在系统辨识模块中获取系统模型', '设计错误');
                return;
            end
            
            try
                % 获取设计参数
                rise_time = str2double(get(obj.controls.rise_time, 'String'));
                overshoot = str2double(get(obj.controls.overshoot, 'String'));
                
                if isnan(rise_time) || isnan(overshoot)
                    error('请输入有效的性能指标');
                end
                
                % 设置设计参数
                design_params = struct();
                design_params.rise_time = rise_time;
                design_params.overshoot = overshoot;
                
                % 根据控制器类型设置额外参数
                if isa(obj.controller, 'PIDController')
                    method_idx = get(obj.controls.method, 'Value');
                    methods = {'ziegler_nichols', 'cohen_coon', 'imc', 'itae', 'manual', 'auto_tune', 'frequency'};
                    
                    design_params.design_method = methods{method_idx};
                    design_params.controller_type = get(obj.controls.pid_type, 'String');
                    
                    % 频域设计需要额外参数
                    if strcmp(methods{method_idx}, 'frequency')
                        design_params.target_pm = 45;  % 目标相位裕度
                        design_params.target_gm = 10;  % 目标增益裕度
                        design_params.target_wc = 1;   % 目标穿越频率
                    end
                end
                
                obj.controller.setDesignParams(design_params);
                
                % 执行设计
                set(obj.controls.info_text, 'String', '正在设计...', 'ForegroundColor', 'blue');
                set(obj.controls.design, 'Enable', 'off');
                drawnow;
                
                obj.controller.design();
                obj.results = obj.controller.getParameters();
                
                % 更新显示
                obj.controller.plotResults(obj.axes_handles);
                
                % 更新信息
                if isa(obj.controller, 'PIDController')
                    perf = obj.controller.performance;
                    info_str = sprintf('设计完成!\nKp=%.3f, Ti=%.3f, Td=%.3f\nTr=%.3fs, OS=%.1f%%', ...
                        obj.controller.Kp, obj.controller.Ti, obj.controller.Td, ...
                        perf.rise_time, perf.overshoot);
                else
                    info_str = sprintf('%s 设计完成!', obj.controller.name);
                end
                
                set(obj.controls.info_text, 'String', info_str, 'ForegroundColor', 'green');
                set(obj.controls.design, 'Enable', 'on');
                
                % 更新手动调节参数
                obj.updateManualTuningParams();
                
            catch ME
                set(obj.controls.info_text, 'String', ...
                    sprintf('设计失败: %s', ME.message), 'ForegroundColor', 'red');
                set(obj.controls.design, 'Enable', 'on');
                errordlg(ME.message, '控制器设计错误');
            end
        end
        
        function simulateControl(obj)
            % 仿真控制系统
            if isempty(obj.controller.closed_loop_sys)
                errordlg('请先设计控制器', '仿真错误');
                return;
            end
            
            try
                % 创建仿真对话框
                sim_dlg = dialog('Name', '仿真设置', 'Position', [300, 300, 400, 250]);
                
                uicontrol('Parent', sim_dlg, ...
                    'Style', 'text', 'String', '仿真时间:', ...
                    'Position', [20, 200, 80, 25]);
                
                sim_time = uicontrol('Parent', sim_dlg, ...
                    'Style', 'edit', 'String', '10', ...
                    'Position', [110, 200, 80, 25]);
                
                uicontrol('Parent', sim_dlg, ...
                    'Style', 'text', 'String', '参考输入类型:', ...
                    'Position', [20, 160, 100, 25]);
                
                ref_type = uicontrol('Parent', sim_dlg, ...
                    'Style', 'popupmenu', ...
                    'String', {'阶跃信号', '斜坡信号', '正弦信号', '方波信号'}, ...
                    'Position', [130, 160, 120, 25]);
                
                uicontrol('Parent', sim_dlg, ...
                    'Style', 'pushbutton', ...
                    'String', '开始仿真', ...
                    'Position', [150, 50, 100, 30], ...
                    'Callback', @(~,~) obj.runSimulation(sim_dlg, sim_time, ref_type));
                
                uicontrol('Parent', sim_dlg, ...
                    'Style', 'pushbutton', ...
                    'String', '取消', ...
                    'Position', [260, 50, 80, 30], ...
                    'Callback', @(~,~) delete(sim_dlg));
                
            catch ME
                errordlg(ME.message, '仿真错误');
            end
        end
        
        function runSimulation(obj, dlg, sim_time_edit, ref_type_popup)
            % 运行仿真
            try
                % 获取参数
                t_final = str2double(get(sim_time_edit, 'String'));
                ref_type_idx = get(ref_type_popup, 'Value');
                ref_types = {'step', 'ramp', 'sine', 'square'};
                ref_type = ref_types{ref_type_idx};
                
                if isnan(t_final) || t_final <= 0
                    error('请输入有效的仿真时间');
                end
                
                % 生成参考输入
                t = 0:0.01:t_final;
                
                switch ref_type
                    case 'step'
                        reference = ones(size(t));
                    case 'ramp'
                        reference = t / t_final;
                    case 'sine'
                        reference = 0.5 * sin(2*pi*t/t_final*2) + 0.5;
                    case 'square'
                        reference = 0.5 * square(2*pi*t/t_final*2) + 0.5;
                end
                
                % 运行仿真
                obj.controller.simulate(t_final, reference);
                
                % 绘制仿真结果
                figure('Name', '仿真结果', 'Position', [100, 100, 800, 600]);
                
                subplot(2,1,1);
                plot(t, reference, 'b--', 'LineWidth', 1.5, 'DisplayName', '参考输入');
                hold on;
                plot(obj.controller.simulation_results.t, ...
                     obj.controller.simulation_results.y, ...
                     'r-', 'LineWidth', 2, 'DisplayName', '系统输出');
                hold off;
                grid on;
                xlabel('时间 (s)');
                ylabel('幅值');
                title('跟踪性能');
                legend('Location', 'best');
                
                subplot(2,1,2);
                error = reference' - obj.controller.simulation_results.y;
                plot(t, error, 'g-', 'LineWidth', 1.5);
                grid on;
                xlabel('时间 (s)');
                ylabel('误差');
                title('跟踪误差');
                
                % 计算性能指标
                mse = mean(error.^2);
                max_error = max(abs(error));
                
                fprintf('\n=== 仿真结果 ===\n');
                fprintf('参考输入: %s\n', ref_type);
                fprintf('MSE: %.6f\n', mse);
                fprintf('最大误差: %.6f\n', max_error);
                fprintf('ISE: %.6f\n', obj.controller.performance.ise);
                fprintf('ITAE: %.6f\n', obj.controller.performance.itae);
                
                % 关闭对话框
                delete(dlg);
                
            catch ME
                errordlg(ME.message, '仿真运行错误');
            end
        end
        
        function exportController(obj)
            % 导出控制器
            if isempty(obj.controller) || isempty(obj.controller.controller)
                errordlg('请先设计控制器', '导出错误');
                return;
            end
            
            [filename, pathname] = uiputfile({'*.mat', 'MAT文件'; '*.slx', 'Simulink模型'}, ...
                '保存控制器');
            
            if filename ~= 0
                fullpath = fullfile(pathname, filename);
                
                if endsWith(filename, '.mat')
                    % 保存控制器数据
                    controller_data = struct();
                    controller_data.type = class(obj.controller);
                    controller_data.params = obj.controller.getParameters();
                    controller_data.plant_model = obj.controller.plant_model;
                    controller_data.performance = obj.controller.performance;
                    
                    save(fullpath, 'controller_data');
                    
                    % 保存到工作空间
                    assignin('base', 'designed_controller', obj.controller.controller);
                    assignin('base', 'controller_data', controller_data);
                    
                    msgbox(sprintf('控制器已导出到:\n%s\n并保存到工作空间', fullpath), '导出成功');
                    
                elseif endsWith(filename, '.slx')
                    % 创建Simulink模型
                    try
                        model_name = 'control_system';
                        new_system(model_name);
                        open_system(model_name);
                        
                        % 添加系统模型
                        add_block('simulink/Continuous/Transfer Fcn', ...
                            [model_name, '/Plant'], ...
                            'Position', [300, 100, 400, 150]);
                        
                        [num_plant, den_plant] = tfdata(obj.controller.plant_model, 'v');
                        set_param([model_name, '/Plant'], ...
                            'Numerator', mat2str(num_plant), ...
                            'Denominator', mat2str(den_plant));
                        
                        % 添加PID控制器
                        add_block('simulink/Continuous/PID Controller', ...
                            [model_name, '/PID Controller'], ...
                            'Position', [100, 100, 200, 150]);
                        
                        set_param([model_name, '/PID Controller'], ...
                            'P', num2str(obj.controller.Kp), ...
                            'I', num2str(obj.controller.Ki), ...
                            'D', num2str(obj.controller.Kd));
                        
                        % 添加其他模块
                        add_block('simulink/Sources/Step', [model_name, '/Reference']);
                        add_block('simulink/Math Operations/Sum', [model_name, '/Sum'], ...
                            'Position', [50, 125, 80, 175]);
                        add_block('simulink/Sinks/Scope', [model_name, '/Scope']);
                        
                        % 连接模块
                        add_line(model_name, 'Reference/1', 'Sum/1');
                        add_line(model_name, 'Sum/1', 'PID Controller/1');
                        add_line(model_name, 'PID Controller/1', 'Plant/1');
                        add_line(model_name, 'Plant/1', 'Scope/1');
                        add_line(model_name, 'Plant/1', 'Sum/2', ...
                            'autorouting', 'on');
                        
                        % 保存模型
                        save_system(model_name, fullpath);
                        close_system(model_name);
                        
                        msgbox(sprintf('Simulink模型已创建:\n%s', fullpath), '导出成功');
                        
                    catch ME
                        errordlg(sprintf('Simulink模型导出失败:\n%s', ME.message), '导出错误');
                    end
                end
            end
        end
        
        function setSystemModel(obj, sys_model)
            % 设置系统模型
            obj.controller.setPlantModel(sys_model);
            obj.updateUI();
        end
        
        function process(obj)
            % 处理数据
            obj.designController();
        end
    end
end