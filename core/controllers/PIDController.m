classdef PIDController < BaseController
    % PIDCONTROLLER PID控制器设计类
    
    properties
        name = 'PID控制器'
        description = '比例-积分-微分控制器'
        controller_type = 'PID'
        
        % PID参数
        Kp = 0
        Ki = 0
        Kd = 0
        Ti = inf
        Td = 0
        
        % 设计方法
        design_method = 'ziegler_nichols'
        
        % 频域特性
        gain_margin = inf       % 增益裕度 (dB)
        phase_margin = inf      % 相位裕度 (°) 
        crossover_freq = 0      % 穿越频率 (Hz)
        
        % 性能指标
        rise_time = 0          % 上升时间 (s)
        overshoot = 0          % 超调量 (%)
        settling_time = 0      % 调节时间 (s)
        peak = 0               % 峰值
        peak_time = 0          % 峰值时间 (s)
        steady_state_error = 0 % 稳态误差
        
        % 参考值
        reference_value = 1    % 阶跃响应参考值
    end
    
    properties (Constant)
        % 设计方法列表
        DESIGN_METHODS = {
            'ziegler_nichols',   'Ziegler-Nichols';
            'cohen_coon',        'Cohen-Coon';
            'imc',               '内模控制(IMC)';
            'itae',              'ITAE最优';
            'manual',            '手动调节';
            'auto_tune',         '自动整定';
            'frequency',         '频域设计'
        };
    end
    
    methods
        function obj = PIDController(plant_model)
            % 构造函数
            if nargin > 0
                obj.plant_model = plant_model;
            end
            obj.performance = struct();
        end
        function setDesignParams(obj, params)
            % 设置设计参数
            if isfield(params, 'design_method')
                obj.design_method = params.design_method;
                fprintf('设置design_method: %s\n', obj.design_method);
            end
            
            if isfield(params, 'controller_type')
                obj.controller_type = params.controller_type;
            end
            
            % 其他参数
            if isfield(params, 'Kp')
                obj.Kp = params.Kp;
            end
            
            if isfield(params, 'Ki')
                obj.Ki = params.Ki;
            end
            
            if isfield(params, 'Kd')
                obj.Kd = params.Kd;
            end
            
            if isfield(params, 'Ti')
                obj.Ti = params.Ti;
            end
            
            if isfield(params, 'Td')
                obj.Td = params.Td;
            end

            if isfield(params, 'reference_value')
                obj.reference_value = params.reference_value;
            end
            
            % 保存设计参数
            obj.design_params = params;
        end
        
        function design(obj)
            % 设计PID控制器
            if isempty(obj.plant_model)
                error('请先设置被控对象模型');
            end
            
            if isempty(obj.design_params)
                error('请先设置设计参数');
            end
                                                                                  
            % 根据设计方法选择设计函数
            fprintf('开始设计，使用方法: %s\n', obj.design_method);
            switch obj.design_method
                case 'ziegler_nichols'
                    obj.designByZieglerNichols();
                case 'cohen_coon'
                    obj.designByCohenCoon();
                case 'imc'
                    obj.designByIMC();
                case 'itae'
                    obj.designByITAE();
                case 'manual'
                    obj.designManual();
                case 'auto_tune'
                    obj.autoTune();
                case 'frequency'
                    obj.designByFrequency();
                otherwise
                    error('未知的设计方法: %s', obj.design_method);
            end
            
            % 创建控制器
            obj.createController();
            
            % 验证设计
            obj.validate();
        end
        
        function designByZieglerNichols(obj)
            % Ziegler-Nichols方法
            
            sys_params = obj.analyzeSystem();
            
            if strcmp(sys_params.type, 'first_order')
                % 一阶系统
                K = sys_params.gain;
                tau = sys_params.tau;
                L = sys_params.delay;
                
                if L > 0
                    % 有延迟的一阶系统
                    Ku = 1.2 * tau / (K * L);
                    Tu = 2 * L;
                else
                    % 无延迟
                    Ku = 0.9 * tau / K;
                    Tu = 3 * tau;
                end
                
            elseif strcmp(sys_params.type, 'second_order')
                % 二阶系统
                K = sys_params.gain;
                zeta = sys_params.zeta;
                wn = sys_params.wn;
                
                if zeta < 0.7
                    Ku = 0.6 * K * wn^2;
                    Tu = pi / (wn * sqrt(1 - zeta^2));
                else
                    tau = 1 / (zeta * wn);
                    Ku = 0.9 * tau / K;
                    Tu = 3 * tau;
                end
            else
                [Ku, Tu] = obj.findUltimatePoint();
            end
            
            if isfield(obj.design_params, 'controller_type')
                if iscell(obj.design_params.controller_type)
                    ctype = obj.design_params.controller_type{1};
                else
                    ctype = obj.design_params.controller_type;
                end
            else
                ctype = 'PID';
            end
            
            switch ctype
                case 'P'
                    obj.Kp = 0.5 * Ku;
                    obj.Ti = inf;
                    obj.Td = 0;
                case 'PI'
                    obj.Kp = 0.45 * Ku;
                    obj.Ti = Tu / 1.2;
                    obj.Td = 0;
                case 'PID'
                    obj.Kp = 0.6 * Ku;
                    obj.Ti = Tu / 2;
                    obj.Td = Tu / 8;
                otherwise
                    error('未知的控制器类型: %s', ctype);
            end
            
            % 根据性能目标微调
            obj.adjustForPerformance();
        end
        
        function designByCohenCoon(obj)
            % Cohen-Coon方法（适合有延迟的一阶系统）
            
            sys_params = obj.analyzeSystem();
            
            if ~strcmp(sys_params.type, 'first_order') || sys_params.delay <= 0
                warning('Cohen-Coon方法更适合有延迟的一阶系统，自动切换为Z-N方法');
                obj.design_method = 'ziegler_nichols';
                obj.designByZieglerNichols();
                return;
            end
            
            K = sys_params.gain;
            tau = sys_params.tau;
            L = sys_params.delay;
            
            % 计算无量纲参数
            R = L / tau;
            
            % Cohen-Coon公式
            if isfield(obj.design_params, 'controller_type')
                if iscell(obj.design_params.controller_type)
                    ctype = obj.design_params.controller_type{1};
                else
                    ctype = obj.design_params.controller_type;
                end
            else
                ctype = 'PID';
            end
            
            switch ctype
                case 'P'
                    obj.Kp = (1/K) * (1 + 0.35*R/(1-R));
                case 'PI'
                    obj.Kp = (0.9/K) * (1 + 0.92*R/(1-R));
                    obj.Ti = tau * (3.3 - 2.2*R) / (1 + 1.2*R);
                case 'PID'
                    obj.Kp = (1.35/K) * (1 + 0.18*R/(1-R));
                    obj.Ti = tau * (2.5 - 2.0*R) / (1 - 0.39*R);
                    obj.Td = 0.37 * tau * R / (1 - 0.81*R);
            end
        end
        
        function designByIMC(obj)
            % 内模控制(Internal Model Control)方法
            
            sys_params = obj.analyzeSystem();
            
            if strcmp(sys_params.type, 'first_order')
                K = sys_params.gain;
                tau = sys_params.tau;
                L = sys_params.delay;
                
                % IMC滤波器时间常数
                if isfield(obj.design_params, 'lambda')
                    lambda = obj.design_params.lambda;
                else
                    lambda = max(0.1*tau, L);
                end
                
                % IMC-PID转换
                if L > 0
                    % 有延迟系统（使用近似）
                    obj.Kp = (2*tau + L) / (2*K*lambda);
                    obj.Ti = tau + L/2;
                    obj.Td = tau*L / (2*tau + L);
                else
                    % 无延迟系统
                    obj.Kp = tau / (K*lambda);
                    obj.Ti = tau;
                    obj.Td = 0;
                end
                
            else
                error('IMC方法目前只支持一阶系统');
            end
        end
        
        function designByITAE(obj)
            % ITAE最优整定
            
            sys_params = obj.analyzeSystem();
            
            if strcmp(sys_params.type, 'first_order')
                % 一阶系统ITAE最优
                K = sys_params.gain;
                tau = sys_params.tau;
                
                % 标准ITAE公式
                obj.Kp = 0.586 / (K * (tau)^0.916);
                obj.Ti = tau / 0.965;
                obj.Td = 0;
                
            elseif strcmp(sys_params.type, 'second_order')
                % 二阶系统ITAE最优
                K = sys_params.gain;
                zeta = sys_params.zeta;
                wn = sys_params.wn;
                
                if zeta < 0.9
                    % 欠阻尼系统
                    obj.Kp = 0.965 * zeta * wn / K;
                    obj.Ti = 0.796 / (zeta * wn);
                    obj.Td = 0.308 / (zeta * wn);
                else
                    % 过阻尼系统，近似处理
                    obj.Kp = 0.7 / K;
                    obj.Ti = 1.4 / wn;
                    obj.Td = 0;
                end
            end
        end
        
        function designManual(obj)
            % 手动设置参数
            if ~isfield(obj.design_params, 'Kp') || ...
               ~isfield(obj.design_params, 'Ti') || ...
               ~isfield(obj.design_params, 'Td')
                error('手动设计需要提供Kp, Ti, Td参数');
            end
            
            obj.Kp = obj.design_params.Kp;
            obj.Ti = obj.design_params.Ti;
            obj.Td = obj.design_params.Td;
        end
        
        function autoTune(obj)
            % 自动整定（简化版）
            
            % 获取系统频域特性
            [gm, pm, wcg, wcp] = margin(obj.plant_model);
            
            if isinf(gm) || isinf(pm)
                % 无法获取频域特性，使用阶跃响应法
                step_info = stepinfo(obj.plant_model);
                
                if step_info.Overshoot > 0
                    % 有超调系统
                    obj.Kp = 0.6 * dcgain(obj.plant_model) / step_info.Peak;
                    obj.Ti = step_info.PeakTime * 2;
                    obj.Td = step_info.PeakTime / 6;
                else
                    % 无超调系统
                    obj.Kp = 0.5 / dcgain(obj.plant_model);
                    obj.Ti = step_info.SettlingTime / 3;
                    obj.Td = 0;
                end
            else
                % 基于频域特性整定
                obj.Kp = 0.5 * gm;
                obj.Ti = 2 * pi / wcg;
                obj.Td = 0.125 * obj.Ti;
            end
        end
        
        function designByFrequency(obj)
            % 频域设计方法
            
            % 获取设计目标
            target_pm = obj.design_params.target_pm;  % 目标相位裕度
            target_gm = obj.design_params.target_gm;  % 目标增益裕度
            target_wc = obj.design_params.target_wc;  % 目标穿越频率
            
            % 分析被控对象频率特性
            [gm0, pm0, wcg0, wcp0] = margin(obj.plant_model);
            
            % 计算需要的补偿
            pm_needed = target_pm - pm0 + 5;  % 增加5度裕量
            
            % 设计相位超前/滞后补偿
            if pm_needed > 0
                % 需要相位超前
                alpha = (1 + sind(pm_needed)) / (1 - sind(pm_needed));
                obj.Td = 1 / (sqrt(alpha) * target_wc);
                obj.Kp = sqrt(alpha) / abs(freqresp(obj.plant_model, target_wc));
                obj.Ti = alpha * obj.Td;
            else
                % 需要相位滞后
                obj.Kp = target_gm / gm0;
                obj.Ti = 10 / target_wc;
                obj.Td = 0;
            end
        end
        
        function sys_params = analyzeSystem(obj)
            % 分析系统特性
            [num, den] = tfdata(obj.plant_model, 'v');
            order = length(den) - 1;
            
            sys_params = struct();
            sys_params.gain = dcgain(obj.plant_model);
            sys_params.poles = pole(obj.plant_model);
            sys_params.zeros = zero(obj.plant_model);
            
            if order == 1
                % 一阶系统
                sys_params.type = 'first_order';
                sys_params.tau = -1/real(sys_params.poles(1));
                
                % 估计延迟（如果可能）
                try
                    [~, ~, ~, tau] = getDelayInfo(obj.plant_model);
                    sys_params.delay = tau;
                catch
                    sys_params.delay = 0;
                end
                
            elseif order == 2
                % 二阶系统
                sys_params.type = 'second_order';
                wn = sqrt(real(sys_params.poles(1))^2 + imag(sys_params.poles(1))^2);
                zeta = -real(sys_params.poles(1))/wn;
                sys_params.wn = wn;
                sys_params.zeta = zeta;
                
            else
                % 高阶系统
                sys_params.type = 'higher_order';
                
                % 尝试近似为二阶系统
                try
                    sys_approx = reduce(obj.plant_model, 2);
                    [num2, den2] = tfdata(sys_approx, 'v');
                    if length(den2) == 3
                        wn = sqrt(den2(3)/den2(1));
                        zeta = den2(2)/(2*wn*den2(1));
                        sys_params.wn = wn;
                        sys_params.zeta = zeta;
                        sys_params.approximation = 'second_order';
                    end
                catch
                    sys_params.approximation = 'none';
                end
            end
        end
        
        function [Ku, Tu] = findUltimatePoint(obj)
            % 寻找临界增益和周期（简化版）
            
            % 扫描增益
            gains = logspace(-2, 2, 100);
            stability = zeros(size(gains));
            
            for i = 1:length(gains)
                sys_cl = feedback(gains(i) * obj.plant_model, 1);
                poles_cl = pole(sys_cl);
                
                % 检查稳定性
                if all(real(poles_cl) < 0)
                    stability(i) = 1;  % 稳定
                else
                    stability(i) = 0;  % 不稳定
                end
            end
            
            % 找到稳定边界
            idx = find(diff(stability) ~= 0, 1);
            
            if isempty(idx)
                % 无法找到临界点，使用默认值
                Ku = 1;
                Tu = 1;
            else
                Ku = gains(idx);
                
                % 估计临界周期
                sys_cl = feedback(Ku * obj.plant_model, 1);
                step_info = stepinfo(sys_cl);
                Tu = step_info.PeakTime * 4;
            end
        end
        
        function adjustForPerformance(obj)

        end
        
        function createController(obj)
            % 创建PID控制器模型
            
            % 计算Ki, Kd
            if obj.Ti > 0
                obj.Ki = obj.Kp / obj.Ti;
            else
                obj.Ki = 0;
            end
            
            if obj.Td > 0
                obj.Kd = obj.Kp * obj.Td;
            else
                obj.Kd = 0;
            end
            
            % 创建连续PID控制器
            obj.controller = pid(obj.Kp, obj.Ki, obj.Kd);
            
            % 计算闭环系统
            obj.closed_loop_sys = feedback(obj.controller * obj.plant_model, 1);
            
            poles_cl = pole(obj.closed_loop_sys);
            if any(real(poles_cl) >= 0)
                warning('闭环系统不稳定！');
                obj.performance.stable = false;
            else
                obj.performance.stable = true;
            end
            
            % 计算频域指标
            [gm, pm, wcg, wcp] = margin(obj.controller * obj.plant_model);
            obj.gain_margin = gm;
            obj.phase_margin = pm;
            obj.crossover_freq = wcp;

            [y, t] = step(obj.closed_loop_sys, obj.reference_value);
            obj.calculatePerformance(y, t);
            obj.rise_time = obj.performance.rise_time;
            obj.overshoot = obj.performance.overshoot;
            obj.settling_time = obj.performance.settling_time;
            obj.peak = obj.performance.peak;
            obj.peak_time = obj.performance.peak_time;
            obj.steady_state_error = obj.performance.steady_state_error;
        end
        
        function tune(obj, params)
            % 调节PID参数
            if isfield(params, 'Kp')
                obj.Kp = params.Kp;
            end
            if isfield(params, 'Ti')
                obj.Ti = params.Ti;
            end
            if isfield(params, 'Td')
                obj.Td = params.Td;
            end
            
            % 重新创建控制器
            obj.createController();
            obj.validate();
        end
        
        function validate(obj)
            
            % 打印控制器参数和性能信息
            fprintf('PID[%s]: Kp=%.3f, Ki=%.3f, Kd=%.3f | 性能: 上升时间=%.2fs, 超调量=%.1f%%, 调节时间=%.2fs | 裕度: PM=%.1f°, GM=%.2f\n', ...
                obj.design_method, obj.Kp, obj.Ki, obj.Kd, ...
                obj.rise_time, obj.overshoot, ...
                obj.settling_time, obj.phase_margin, obj.gain_margin);
        end
        
        function params = getParameters(obj)
            % 获取控制器参数
            params = struct();
            params.Kp = obj.Kp;
            params.Ki = obj.Ki;
            params.Kd = obj.Kd;
            params.Ti = obj.Ti;
            params.Td = obj.Td;
            params.design_method = obj.design_method;
            params.performance = obj.performance;
            params.stability = struct(...
                'gain_margin', obj.gain_margin, ...
                'phase_margin', obj.phase_margin, ...
                'crossover_freq', obj.crossover_freq);
        end
        
        function plotResults(obj, ax)
            % 绘制控制器结果
            if nargin < 2
                figure('Name', 'PID控制器设计结果', 'Position', [100, 100, 1200, 800]);
                ax = gobjects(4,1);
                for i = 1:4
                    ax(i) = subplot(2,2,i);
                end
            end
            
            % 阶跃响应
            obj.plotStepResponse(ax(1));
            
            % 开环Bode图
            obj.plotOpenLoopBode(ax(2));
            
            % 根轨迹
            obj.plotRootLocus(ax(3));
            
            % 控制信号
            obj.plotControlSignal(ax(4));
        end
        
        function plotStepResponse(obj, ax)
            % 绘制阶跃响应
            cla(ax);
            
            [y, t] = step(obj.closed_loop_sys, 10);
            plot(ax, t, y, 'b-', 'LineWidth', 2);
            hold(ax, 'on');
            
            % 标注性能指标
            plot(ax, [obj.performance.rise_time, obj.performance.rise_time], ...
                [0, 1], 'r--');
            plot(ax, obj.performance.rise_time, 1, 'ro', 'MarkerSize', 8);
            
            if obj.performance.overshoot > 0
                plot(ax, obj.performance.peak_time, obj.performance.peak, ...
                    'go', 'MarkerSize', 8);
                text(ax, obj.performance.peak_time, obj.performance.peak*1.05, ...
                    sprintf('OS=%.1f%%', obj.performance.overshoot), ...
                    'HorizontalAlignment', 'center');
            end
            
            plot(ax, [obj.performance.settling_time, obj.performance.settling_time], ...
                [0, 1.5], 'm--');
            
            hold(ax, 'off');
            
            grid(ax, 'on');
            xlabel(ax, '时间 (s)');
            ylabel(ax, '输出');
            title(ax, sprintf('闭环阶跃响应 (Tr=%.3fs, OS=%.1f%%)', ...
                obj.performance.rise_time, obj.performance.overshoot));
            ylim([0, max(1.2, max(y)*1.1)]);
        end
        
        function plotOpenLoopBode(obj, ax)
            % 绘制开环Bode图
            cla(ax);
            
            sys_open = obj.controller * obj.plant_model;
            [mag, phase, w] = bode(sys_open, {0.01, 100});
            
            yyaxis(ax, 'left');
            semilogx(ax, w, 20*log10(squeeze(mag)), 'b-', 'LineWidth', 2);
            ylabel(ax, '幅值 (dB)');
            
            % 标注穿越频率
            hold(ax, 'on');
            semilogx(ax, [obj.crossover_freq, obj.crossover_freq], ...
                [-100, 0], 'r--');
            semilogx(ax, obj.crossover_freq, 0, 'ro', 'MarkerSize', 8);
            text(ax, obj.crossover_freq, -5, sprintf('ωc=%.3f', obj.crossover_freq), ...
                'HorizontalAlignment', 'center');
            hold(ax, 'off');
            
            yyaxis(ax, 'right');
            semilogx(ax, w, squeeze(phase), 'r-', 'LineWidth', 2);
            ylabel(ax, '相位 (度)');
            
            xlabel(ax, '频率 (rad/s)');
            title(ax, sprintf('开环Bode图 (PM=%.1f°, GM=%.2f)', ...
                obj.phase_margin, obj.gain_margin));
            grid(ax, 'on');
        end
        
        function plotRootLocus(obj, ax)
            % 绘制根轨迹
            cla(ax);
            
            rlocus(ax, obj.plant_model * obj.controller);
            grid(ax, 'on');
            title(ax, '根轨迹图');
        end
        
        function plotControlSignal(obj, ax)
            % 绘制控制信号
            cla(ax);
            
            % 模拟阶跃响应的控制信号
            t = 0:0.01:10;
            y = step(obj.closed_loop_sys, t);
            
            % 计算控制信号（简化）
            u = obj.Kp * (1 - y) + obj.Ki * cumtrapz(t, 1 - y) + ...
                obj.Kd * gradient(1 - y, t);
            
            plot(ax, t, u, 'g-', 'LineWidth', 2);
            grid(ax, 'on');
            xlabel(ax, '时间 (s)');
            ylabel(ax, '控制信号 u(t)');
            title(ax, '控制信号');
            
            % 显示最大控制量
            u_max = max(abs(u));
            text(ax, 0.05, 0.95, sprintf('max|u|=%.3f', u_max), ...
                'Units', 'normalized', ...
                'VerticalAlignment', 'top', ...
                'BackgroundColor', 'white');
        end
    end
end