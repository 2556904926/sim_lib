classdef PIDControllerUI < ControllerUIBase
    % PIDCONTROLLERUI PID控制器UI
    
    properties
        name = 'PID控制器'
        description = '比例-积分-微分控制器设计'
        controller_type = 'PID'
    end
    
    methods
        function obj = PIDControllerUI(parent_panel, app_handle)
            % 构造函数
            if nargin < 2
                error('PIDControllerUI需要两个参数：parent_panel和app_handle');
            end
            obj = obj@ControllerUIBase(parent_panel, app_handle);
            obj.controller = PIDController();
            obj.createUI();
        end
        
        function createUI(obj)
            % 创建PID控制器UI
            obj.controls.panel = uipanel('Parent', obj.parent_panel, ...
                'Title', 'PID控制器设计', ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.96, 0.96, 0.96], ...
                'Visible', 'off');
            
            % 设计参数面板
            design_panel = uipanel('Parent', obj.controls.panel, ...
                'Title', '设计参数', ...
                'Position', [0.01, 0.75, 0.98, 0.24], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 设计方法选择
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '设计方法:', ...
                'Position', [20, 80, 70, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92], ...
                'FontWeight', 'bold');
            
            obj.controls.method = uicontrol('Parent', design_panel, ...
                'Style', 'popupmenu', ...
                'String', {'Ziegler-Nichols', 'Cohen-Coon', 'IMC', 'ITAE最优', '手动调节', '时域设计', '频域设计'}, ...
                'Value', 1, ...
                'Position', [90, 75, 120, 25], ...
                'BackgroundColor', 'white', ...
                'Callback', @(~,~) obj.onMethodChanged());
            
            % PID类型选择
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', 'PID类型:', ...
                'Position', [230, 80, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.pid_type = uicontrol('Parent', design_panel, ...
                'Style', 'popupmenu', ...
                'String', {'PID', 'PI', 'P'}, ...
                'Value', 1, ...
                'Position', [290, 75, 60, 25], ...
                'BackgroundColor', 'white');
            
            % 性能指标
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '上升时间:', ...
                'Position', [20, 45, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.rise_time = uicontrol('Parent', design_panel, ...
                'Style', 'edit', ...
                'String', '1.0', ...
                'Position', [80, 40, 40, 25], ...  % 宽度从60改为40，与字体大小匹配
                'BackgroundColor', 'white');
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', 's', ...
                'Position', [125, 45, 20, 20], ...  % 位置调整
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '超调量:', ...
                'Position', [150, 45, 60, 20], ...  % 位置调整
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.overshoot = uicontrol('Parent', design_panel, ...
                'Style', 'edit', ...
                'String', '5.0', ...
                'Position', [210, 40, 40, 25], ...  % 宽度从60改为40，位置调整
                'BackgroundColor', 'white');
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '%', ...
                'Position', [255, 45, 20, 20], ...  % 位置调整
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '最小相位裕度:', ...
                'Position', [20, 10, 80, 20], ...  % 第二行，Y=10
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.target_pm = uicontrol('Parent', design_panel, ...
                'Style', 'edit', ...
                'String', '60.0', ...
                'Position', [100, 5, 40, 25], ...  % 第二行，Y=5
                'BackgroundColor', 'white');
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '°', ...
                'Position', [145, 10, 20, 20], ...  % 第二行，Y=10
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '参考值:', ...
                'Position', [170, 10, 50, 20], ...  % 第二行右侧
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.reference = uicontrol('Parent', design_panel, ...
                'Style', 'edit', ...
                'String', '1.0', ...
                'Position', [220, 5, 40, 25], ...  % 第二行右侧
                'BackgroundColor', 'white');
            
            obj.controls.design = uicontrol('Parent', design_panel, ...
                'Style', 'pushbutton', ...
                'String', '设计控制器', ...
                'Position', [360, 40, 100, 35], ...
                'BackgroundColor', [0.2, 0.5, 0.8], ...
                'ForegroundColor', 'white', ...
                'FontWeight', 'bold', ...
                'Callback', @(~,~) obj.designController());
            
            obj.controls.simulate = uicontrol('Parent', design_panel, ...
                'Style', 'pushbutton', ...
                'String', '仿真', ...
                'Position', [470, 40, 80, 35], ...
                'BackgroundColor', [0.3, 0.7, 0.3], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.simulateControl());
            
            obj.controls.export = uicontrol('Parent', design_panel, ...
                'Style', 'pushbutton', ...
                'String', '导出', ...
                'Position', [560, 40, 80, 35], ...
                'BackgroundColor', [0.8, 0.5, 0.2], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.exportController());
            
            % 手动调节面板
            obj.createManualTuningPanel(design_panel);
            
            % 信息文本
            obj.controls.info_text = uicontrol('Parent', design_panel, ...
                'Style', 'text', ...
                'String', '', ...
                'Position', [650, 45, 200, 30], ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            results_panel = uipanel('Parent', obj.controls.panel, ...
                'Title', '设计结果', ...
                'Position', [0.01, 0.01, 0.98, 0.73], ...
                'BackgroundColor', 'white');
            
            obj.createAxes(results_panel);
        end
        
        function createManualTuningPanel(obj, parent)
            tuning_panel = uipanel('Parent', parent, ...
                'Title', '手动调节参数', ...
                'Position', [0.65, 0.01, 0.34, 0.98], ...  % 调整位置到右边
                'BackgroundColor', [0.95, 0.95, 0.95], ...
                'Visible', 'off');
            
            obj.controls.tuning_panel = tuning_panel;
            
            % 调整控件位置，适应新的面板尺寸
            panel_width = 300;  % 面板宽度
            panel_height = 80;  % 面板高度
            
            % Kp调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Kp:', ...
                'Position', [20, 70, 30, 20], ...  % Y从50改为70
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.kp_edit = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', ...
                'String', '1.0', ...
                'Position', [50, 70, 60, 25], ...  % Y从50改为70
                'BackgroundColor', 'white', ...
                'Callback', @(~,~) obj.updateControllerParams());
            
            obj.controls.kp_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 10, 'Value', 1.0, ...
                'Position', [120, 70, 150, 25], ...  % Y从50改为70
                'Callback', @(~,~) obj.onKpSliderChanged());
            
            % Ki调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Ki:', ...
                'Position', [20, 40, 30, 20], ...  % Y从20改为40
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.ki_edit = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', ...
                'String', '0.1', ...
                'Position', [50, 40, 60, 25], ...  % Y从20改为40
                'BackgroundColor', 'white', ...
                'Callback', @(~,~) obj.updateControllerParams());
            
            obj.controls.ki_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 5, 'Value', 0.1, ...
                'Position', [120, 40, 150, 25], ...  % Y从20改为40
                'Callback', @(~,~) obj.onKiSliderChanged());
            
            % Kd调节
            uicontrol('Parent', tuning_panel, ...
                'Style', 'text', 'String', 'Kd:', ...
                'Position', [20, 10, 30, 20], ...  % Y从-10改为10
                'BackgroundColor', [0.95, 0.95, 0.95]);
            
            obj.controls.kd_edit = uicontrol('Parent', tuning_panel, ...
                'Style', 'edit', ...
                'String', '0.01', ...
                'Position', [50, 10, 60, 25], ...  % Y从-10改为10
                'BackgroundColor', 'white', ...
                'Callback', @(~,~) obj.updateControllerParams());
            
            obj.controls.kd_slider = uicontrol('Parent', tuning_panel, ...
                'Style', 'slider', ...
                'Min', 0, 'Max', 1, 'Value', 0.01, ...
                'Position', [120, 10, 150, 25], ...  % Y从-10改为10
                'Callback', @(~,~) obj.onKdSliderChanged());
            
        end
        
        function createAxes(obj, parent)
            % 创建绘图坐标轴
            obj.controls.axes_handles = cell(2, 2);
            
            titles = {'时域响应', 'Bode图', '极点零点图', '系统阶跃响应'};
            
            for i = 1:2
                for j = 1:2
                    idx = (i-1)*2 + j;
                    obj.controls.axes_handles{i,j} = subplot(2,2,idx, 'Parent', parent);
                    title(obj.controls.axes_handles{i,j}, titles{idx});
                    grid(obj.controls.axes_handles{i,j}, 'on');
                end
            end
        end
        
        function onMethodChanged(obj)
            % 设计方法改变回调
            method_idx = get(obj.controls.method, 'Value');
            methods = {'ziegler_nichols', 'cohen_coon', 'imc', 'itae', 'manual', 'auto_tune', 'frequency'};
            
            if strcmp(methods{method_idx}, 'manual')
                set(obj.controls.tuning_panel, 'Visible', 'on');
                obj.updateManualTuningParams();
            else
                set(obj.controls.tuning_panel, 'Visible', 'off');
            end
        end
        
        function updateManualTuningParams(obj)
            % 更新手动调节参数显示
            if isempty(obj.controller) || isempty(obj.controller.design_params)
                return;
            end
            
            params = obj.controller.design_params;
            
            if isfield(params, 'Kp')
                set(obj.controls.kp_edit, 'String', num2str(params.Kp));
                set(obj.controls.kp_slider, 'Value', params.Kp);
            end
            
            if isfield(params, 'Ki')
                set(obj.controls.ki_edit, 'String', num2str(params.Ki));
                set(obj.controls.ki_slider, 'Value', params.Ki);
            end
            
            if isfield(params, 'Kd')
                set(obj.controls.kd_edit, 'String', num2str(params.Kd));
                set(obj.controls.kd_slider, 'Value', params.Kd);
            end
        end
        
        function onKpSliderChanged(obj)
            % Kp滑块改变回调
            value = get(obj.controls.kp_slider, 'Value');
            set(obj.controls.kp_edit, 'String', num2str(value));
            obj.updateControllerParams();
        end
        
        function onKiSliderChanged(obj)
            % Ki滑块改变回调
            value = get(obj.controls.ki_slider, 'Value');
            set(obj.controls.ki_edit, 'String', num2str(value));
            obj.updateControllerParams();
        end
        
        function onKdSliderChanged(obj)
            % Kd滑块改变回调
            value = get(obj.controls.kd_slider, 'Value');
            set(obj.controls.kd_edit, 'String', num2str(value));
            obj.updateControllerParams();
        end
        
        function updateControllerParams(obj)
            % 更新控制器参数
            try
                Kp = str2double(get(obj.controls.kp_edit, 'String'));
                Ki = str2double(get(obj.controls.ki_edit, 'String'));
                Kd = str2double(get(obj.controls.kd_edit, 'String'));
                
                if isnan(Kp) || isnan(Ki) || isnan(Kd)
                    return;
                end
                
                obj.controller.design_params.Kp = Kp;
                obj.controller.design_params.Ki = Ki;
                obj.controller.design_params.Kd = Kd;
                
                % 重新设计控制器
                obj.controller.design();
                
            catch ME
                disp(['参数更新错误: ', ME.message]);
            end
        end
        
        function realTimeSimulate(obj)
            % 实时仿真
            obj.simulateControl();
        end
        
        function designController(obj)
            % 设计PID控制器
            if isempty(obj.controller.plant_model)
                errordlg('请先设置系统模型', '错误');
                return;
            end
            
            try
                % 获取设计参数
                method_idx = get(obj.controls.method, 'Value');
                methods = {'ziegler_nichols', 'cohen_coon', 'imc', 'itae', 'manual', 'timedesign', 'frequency'};
                method = methods{method_idx};
                
                pid_type_idx = get(obj.controls.pid_type, 'Value');
                pid_types = {'PID', 'PI', 'P'};
                pid_type = pid_types{pid_type_idx};
                
                rise_time = str2double(get(obj.controls.rise_time, 'String'));
                overshoot = str2double(get(obj.controls.overshoot, 'String'));
                target_pm = str2double(get(obj.controls.target_pm, 'String'));  % 新增目标相位裕度
                reference = str2double(get(obj.controls.reference, 'String'));
                
                if isnan(rise_time) || isnan(overshoot) || isnan(target_pm) || isnan(reference)
                    errordlg('请输入有效的性能指标和参考值', '错误');
                    return;
                end
                
                % 设置设计参数
                design_params = struct();
                design_params.design_method = method;
                design_params.pid_type = pid_type;
                design_params.rise_time = rise_time;
                design_params.overshoot = overshoot;
                design_params.target_pm = target_pm;  % 新增目标相位裕度
                design_params.reference = reference;
                
                % 调试输出
                fprintf('设计参数: method=%s, design_method=%s\n', method, design_params.design_method);
                
                if strcmp(method, 'manual')
                    design_params.Kp = str2double(get(obj.controls.kp_edit, 'String'));
                    design_params.Ki = str2double(get(obj.controls.ki_edit, 'String'));
                    design_params.Kd = str2double(get(obj.controls.kd_edit, 'String'));
                end
                
                obj.controller.setDesignParams(design_params);
                
                % 设计控制器
                obj.controller.design();
                
                % 绘制结果
                obj.plotResults();
                
                % 显示传递函数
                obj.displayTransferFunction();
                
                % 更新UI
                obj.updateUI();
                
                msgbox('PID控制器设计完成', '成功');
                
            catch ME
                errordlg(['设计失败: ', ME.message], '错误');
            end
        end
        
        function updateUI(obj)
            % 更新UI显示控制器参数和系统信息
            if ~isempty(obj.controller.plant_model)
                tf_str = obj.getTransferFunctionString(obj.controller.plant_model);
                sys_info = sprintf('G(s) = %s', tf_str);
                set(obj.controls.info_text, 'String', sys_info, 'ForegroundColor', 'green');
            else
                set(obj.controls.info_text, 'String', '请先加载系统模型', 'ForegroundColor', 'red');
            end
            
            if ~isempty(obj.controller.design_params)
                params = obj.controller.design_params;
                if isfield(params, 'Kp')
                    set(obj.controls.kp_edit, 'String', num2str(params.Kp));
                    set(obj.controls.kp_slider, 'Value', params.Kp);
                end
                if isfield(params, 'Ki')
                    set(obj.controls.ki_edit, 'String', num2str(params.Ki));
                    set(obj.controls.ki_slider, 'Value', params.Ki);
                end
                if isfield(params, 'Kd')
                    set(obj.controls.kd_edit, 'String', num2str(params.Kd));
                    set(obj.controls.kd_slider, 'Value', params.Kd);
                end
            end
        end
        
        function displayTransferFunction(obj)
            % 显示开环传递函数 G(s)*PID(s)
            if isempty(obj.controller) || isempty(obj.controller.controller) || isempty(obj.controller.plant_model)
                return;
            end
            
            % 计算开环传递函数
            open_loop = obj.controller.controller * obj.controller.plant_model;
            
            % 获取传递函数字符串
            tf_str = obj.getTransferFunctionString(open_loop);
            
            % 显示在信息文本中
            info_str = sprintf('开环传递函数: %s', tf_str);
            set(obj.controls.info_text, 'String', info_str, 'ForegroundColor', 'blue');
        end
        
        function tf_str = getTransferFunctionString(obj, sys)
            % 获取传递函数字符串
            [num, den] = tfdata(sys, 'v');
            
            % 简化显示
            num_str = obj.poly2str(num, 's');
            den_str = obj.poly2str(den, 's');
            
            tf_str = sprintf('%s / %s', num_str, den_str);
        end
        
        function plotResults(obj)
        
        ref = obj.controller.reference_value;
        
        open_loop = obj.controller.controller * obj.controller.plant_model;
        
        closed_loop = feedback(open_loop, 1);
        
        % 计算裕度
        [Gm, Pm, Wcg, Wcp] = margin(open_loop);

        ax1 = obj.controls.axes_handles{1,1};
        cla(ax1);
        [y_step, t_step] = step(closed_loop * ref);
        plot(ax1, t_step, y_step, 'b-', 'LineWidth', 2);
        
        % 绘制参考值线
        hold(ax1, 'on');
        plot(ax1, [t_step(1), t_step(end)], [ref, ref], 'r--', 'LineWidth', 1.5);
        text(ax1, t_step(end), ref, sprintf('参考值=%.2f', ref), ...
            'VerticalAlignment', 'bottom', 'Color', 'red');
        hold(ax1, 'off');
        
        grid(ax1, 'on');
        xlabel(ax1, '时间 (s)');
        ylabel(ax1, '幅值');
        title(ax1, '时域响应');
        
        % 计算时域响应参数
        step_info = stepinfo(y_step, t_step, ref);
        
        ax2 = obj.controls.axes_handles{1,2};
        cla(ax2);
        w = logspace(-2, 2, 200);
       
        [mag, phase, wout] = bode(open_loop, w);
        
        yyaxis(ax2, 'left');
        semilogx(ax2, wout, 20*log10(squeeze(mag)), 'b-', 'LineWidth', 2);
        ylabel(ax2, '幅值 (dB)');
        
        % 绘制相频特性
        yyaxis(ax2, 'right');
        semilogx(ax2, wout,squeeze(phase), 'r-', 'LineWidth', 2);
        ylabel(ax2, '相位 (度)');
        
        xlabel(ax2, '频率 (rad/s)');
        title(ax2, 'Bode图');
        grid(ax2, 'on');
        
        
        % 绘制极点零点图
        ax3 = obj.controls.axes_handles{2,1};
        cla(ax3);
        pzmap(ax3, open_loop);
        grid(ax3, 'on');
        title(ax3, '极点零点图');
        
        % 显示系统参数
        ax4 = obj.controls.axes_handles{2,2};
        cla(ax4);
        axis(ax4, 'off');  % 关闭坐标轴
        
        text(ax4, 0.1, 0.9, sprintf('PID参数:'), 'FontSize', 10, 'FontWeight', 'bold');
        text(ax4, 0.1, 0.8, sprintf('Kp = %.4f', obj.controller.Kp), 'FontSize', 9);
        text(ax4, 0.1, 0.7, sprintf('Ki = %.4f', obj.controller.Ki), 'FontSize', 9);
        text(ax4, 0.1, 0.6, sprintf('Kd = %.4f', obj.controller.Kd), 'FontSize', 9);
        
        text(ax4, 0.1, 0.5, sprintf('时域响应参数:'), 'FontSize', 10, 'FontWeight', 'bold');
        text(ax4, 0.1, 0.4, sprintf('上升时间 = %.4f s', obj.controller.rise_time), 'FontSize', 9);
        text(ax4, 0.1, 0.3, sprintf('超调量 = %.2f%%', obj.controller.overshoot), 'FontSize', 9);
        text(ax4, 0.1, 0.2, sprintf('调节时间 = %.4f s', obj.controller.settling_time), 'FontSize', 9);
        
        text(ax4, 0.1, 0.1, sprintf('稳定性裕度:'), 'FontSize', 10, 'FontWeight', 'bold');
        text(ax4, 0.1, 0.0, sprintf('增益裕度 = %.2f dB', obj.controller.gain_margin), 'FontSize', 9);
        text(ax4, 0.5, 0.9, sprintf('相位裕度 = %.2f°', obj.controller.phase_margin), 'FontSize', 9);
        
        title(ax4, '系统参数');
        end
        
        function str = poly2str(~, poly_coeffs, var)
            % 多项式系数转换为字符串
            n = length(poly_coeffs) - 1;
            terms = {};
            
            for i = 1:length(poly_coeffs)
                coeff = poly_coeffs(i);
                power = n - i + 1;
                
                if abs(coeff) < 1e-10
                    continue;
                end
                
                if power == 0
                    term = sprintf('%.4f', coeff);
                elseif power == 1
                    if abs(coeff - 1) < 1e-10
                        term = var;
                    elseif abs(coeff + 1) < 1e-10
                        term = ['-', var];
                    else
                        term = sprintf('%.4f%s', coeff, var);
                    end
                else
                    if abs(coeff - 1) < 1e-10
                        term = sprintf('%s^%d', var, power);
                    elseif abs(coeff + 1) < 1e-10
                        term = sprintf('-%s^%d', var, power);
                    else
                        term = sprintf('%.4f%s^%d', coeff, var, power);
                    end
                end
                
                terms{end+1} = term;
            end
            
            if isempty(terms)
                str = '0';
            else
                str = strjoin(terms, ' + ');
            end
        end    end
end