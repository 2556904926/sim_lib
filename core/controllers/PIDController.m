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
        gain_margin = inf
        phase_margin = inf
        crossover_freq = 0
        
        % 性能指标
        rise_time = 0
        overshoot = 0
        settling_time = 0
        peak = 0
        peak_time = 0
        steady_state_error = 0
        
        % 参考值
        reference_value = 1
        target_pm = 60          % 目标相位裕度 (°)
        target_wc = 1000 * 2 * pi % 目标带宽 (rad/s)
        target_rise_time = 0.01  % 目标上升时间 (s)
        target_overshoot = 0.05  % 目标超调量 (0~1)
    end
    
    properties (Constant)
        DESIGN_METHODS = {
            'ziegler_nichols',   'Ziegler-Nichols'; % 适用于一阶+延迟或欠阻尼二阶
            'cohen_coon',        'Cohen-Coon';      % 适用于一阶+延迟
            'imc',               '内模控制(IMC)';   % 适用于一阶系统
            'itae',              'ITAE最优';        % 适用于一阶/二阶系统
            'manual',            '手动调节';
            'timedesign',        '时域设计';        % 使用autoTune (基于超调/上升时间)
            'frequency',         '频域设计'         % 使用designByFrequency (基于带宽/相位裕度)
        };
    end
    
    methods
        function obj = PIDController(plant_model)
            if nargin > 0
                obj.plant_model = plant_model;
            end
            obj.performance = struct();
        end
        
        function setDesignParams(obj, params)
            % 设置设计参数，支持字段：design_method, controller_type, Kp, Ki, Kd, Ti, Td,
            % reference_value, target_pm, target_wc, target_rise_time, target_overshoot
            if isfield(params, 'design_method')
                obj.design_method = params.design_method;
                fprintf('设置design_method: %s\n', obj.design_method);
            end
            if isfield(params, 'controller_type')
                obj.controller_type = params.controller_type;
            end
            if isfield(params, 'Kp'), obj.Kp = params.Kp; end
            if isfield(params, 'Ki'), obj.Ki = params.Ki; end
            if isfield(params, 'Kd'), obj.Kd = params.Kd; end
            if isfield(params, 'Ti'), obj.Ti = params.Ti; end
            if isfield(params, 'Td'), obj.Td = params.Td; end
            if isfield(params, 'reference_value'), obj.reference_value = params.reference_value; end
            if isfield(params, 'target_pm'), obj.target_pm = params.target_pm; end
            if isfield(params, 'target_wc'), obj.target_wc = params.target_wc; end
            if isfield(params, 'target_rise_time'), obj.target_rise_time = params.target_rise_time; end
            if isfield(params, 'target_overshoot'), obj.target_overshoot = params.target_overshoot; end
            obj.design_params = params;
        end
        
        function design(obj)
            % 主设计入口，根据 design_method 调用相应子函数
            if isempty(obj.plant_model)
                error('请先设置被控对象模型');
            end
            if isempty(obj.design_params)
                error('请先设置设计参数');
            end
            
            fprintf('开始设计，使用方法: %s\n', obj.design_method);
            switch obj.design_method
                case 'ziegler_nichols', obj.designByZieglerNichols();
                case 'cohen_coon',      obj.designByCohenCoon();
                case 'imc',             obj.designByIMC();
                case 'itae',            obj.designByITAE();
                case 'manual',          obj.designManual();
                case 'timedesign',      obj.autoTune();
                case 'frequency',       obj.designByFrequency();
                otherwise, error('未知的设计方法: %s', obj.design_method);
            end
            
            obj.createController();
            obj.validate();
        end
        
        % ------------------------------------------------------------------
        % 具体设计方法（保留原逻辑，未作改动）
        % ------------------------------------------------------------------
        function designByZieglerNichols(obj)
            % 适用：一阶惯性+延迟 (FOPDT) 或欠阻尼二阶 (ζ<0.707)
            % 参数：controller_type (P/PI/PID)
            sys_params = obj.analyzeSystem();
            K = sys_params.gain;
            L = sys_params.delay;
            found_ultimate = false;
            Ku = 0; Tu = 0;
            
            if strcmp(sys_params.type, 'first_order')
                tau = sys_params.tau;
                if L > 0
                    Ku = 1.2 * tau / (K * L);
                    Tu = 2 * L;
                    found_ultimate = true;
                    fprintf('使用 FOPDT 切线法: Ku = %.4f, Tu = %.4f\n', Ku, Tu);
                else
                    warning('纯一阶系统无临界增益，改用极点配置后备方案 (PI)');
                    obj.Kp = 1 / K;
                    obj.Ti = tau;
                    obj.Td = 0;
                    obj.TitoKi(obj.Ti, obj.Td);
                    return;
                end
            elseif strcmp(sys_params.type, 'second_order')
                zeta = sys_params.zeta;
                wn = sys_params.wn;
                if zeta < 0.707
                    Ku = 2 * zeta / K;
                    Tu = 2 * pi / wn;
                    found_ultimate = true;
                    fprintf('使用二阶欠阻尼精确解: Ku = %.4f, Tu = %.4f\n', Ku, Tu);
                else
                    warning('过阻尼二阶系统无临界增益，改用主导极点近似 (PI)');
                    poles = sys_params.poles;
                    [~, idx] = min(abs(real(poles)));
                    tau_dominant = 1 / abs(real(poles(idx)));
                    obj.Kp = 1 / K;
                    obj.Ti = tau_dominant * 1.5;
                    obj.Td = 0;
                    obj.TitoKi(obj.Ti, obj.Td);
                    return;
                end
            else
                [Ku, Tu] = obj.findUltimatePoint();
                if Ku > 0 && Tu > 0
                    found_ultimate = true;
                    fprintf('通过数值法找到临界点: Ku = %.4f, Tu = %.4f\n', Ku, Tu);
                else
                    error('高阶系统无法自动整定，请使用其他方法');
                end
            end
            
            if found_ultimate
                ctype = obj.getControllerType();
                switch ctype
                    case 'P',  obj.Kp = 0.5 * Ku; obj.Ti = 0; obj.Td = 0;
                    case 'PI', obj.Kp = 0.45 * Ku; obj.Ti = Tu / 1.2; obj.Td = 0;
                    case 'PID',obj.Kp = 0.6 * Ku; obj.Ti = Tu / 2; obj.Td = Tu / 8;
                    otherwise, error('未知控制器类型');
                end
                obj.TitoKi(obj.Ti, obj.Td);
                fprintf('Z-N 整定完成 [%s]: Kp=%.4f, Ti=%.4f, Td=%.4f\n', ctype, obj.Kp, obj.Ti, obj.Td);
            end
        end
        
        function designByCohenCoon(obj)
            % 适用：一阶惯性+延迟 (FOPDT)
            % 参数：controller_type (P/PI/PID)
            sys_params = obj.analyzeSystem();
            K = sys_params.gain; tau = sys_params.tau; L = sys_params.delay;
            R = L / tau;
            ctype = obj.getControllerType();
            switch ctype
                case 'P',  obj.Kp = (1/K) * (1 + 0.35*R/(1-R));
                case 'PI', obj.Kp = (0.9/K) * (1 + 0.92*R/(1-R));
                           obj.Ti = tau * (3.3 - 2.2*R) / (1 + 1.2*R);
                case 'PID',obj.Kp = (1.35/K) * (1 + 0.18*R/(1-R));
                           obj.Ti = tau * (2.5 - 2.0*R) / (1 - 0.39*R);
                           obj.Td = 0.37 * tau * R / (1 - 0.81*R);
            end
            obj.TitoKi(obj.Ti, obj.Td);
        end
        
        function designByIMC(obj)
            % 适用：一阶惯性（可带延迟）
            % 参数：lambda (可选，默认 max(0.1*tau, L))
            sys_params = obj.analyzeSystem();
            if ~strcmp(sys_params.type, 'first_order')
                error('IMC方法仅支持一阶系统');
            end
            K = sys_params.gain; tau = sys_params.tau; L = sys_params.delay;
            if isfield(obj.design_params, 'lambda')
                lambda = obj.design_params.lambda;
            else
                lambda = max(0.1*tau, L);
            end
            if L > 0
                obj.Kp = (2*tau + L) / (2*K*lambda);
                obj.Ti = tau + L/2;
                obj.Td = tau*L / (2*tau + L);
            else
                obj.Kp = tau / (K*lambda);
                obj.Ti = tau;
                obj.Td = 0;
            end
            obj.TitoKi(obj.Ti, obj.Td);
        end
        
        function designByITAE(obj)
            % 适用：一阶或二阶（欠阻尼/过阻尼）系统
            sys_params = obj.analyzeSystem();
            if strcmp(sys_params.type, 'first_order')
                K = sys_params.gain; tau = sys_params.tau;
                obj.Kp = 0.586 / (K * (tau)^0.916);
                obj.Ti = tau / 0.965;
                obj.Td = 0;
            elseif strcmp(sys_params.type, 'second_order')
                K = sys_params.gain; zeta = sys_params.zeta; wn = sys_params.wn;
                if zeta < 0.9
                    obj.Kp = 0.965 * zeta * wn / K;
                    obj.Ti = 0.796 / (zeta * wn);
                    obj.Td = 0.308 / (zeta * wn);
                else
                    obj.Kp = 0.7 / K;
                    obj.Ti = 1.4 / wn;
                    obj.Td = 0;
                end
            else
                error('ITAE方法仅支持一阶或二阶系统');
            end
            obj.TitoKi(obj.Ti, obj.Td);
        end
        
        function designManual(obj)
            % 手动设置：从 design_params 读取 Kp, Ki, Kd
            if isfield(obj.design_params, 'Kp'), obj.Kp = obj.design_params.Kp; end
            if isfield(obj.design_params, 'Ki'), obj.Ki = obj.design_params.Ki; end
            if isfield(obj.design_params, 'Kd'), obj.Kd = obj.design_params.Kd; end
        end
        
        % ------------------------------------------------------------------
        % autoTune 和 designByFrequency（支持 MCR 环境）
        % ------------------------------------------------------------------
        function autoTune(obj)
            % 时域整定：基于目标超调量和上升时间
            % 在 MATLAB 环境调用 pidtune，在 MCR 使用解析极点配置
            if isempty(obj.plant_model)
                error('请先设置被控对象模型');
            end
            
            if isdeployed   % MCR 环境
                [K, tau] = obj.extractFirstOrder();
                overshoot = obj.target_overshoot;
                rise_time = obj.target_rise_time;
                [Kp, Ki, Kd] = obj.tuneByOvershootRise(K, tau, overshoot, rise_time);
                obj.Kp = Kp; obj.Ki = Ki; obj.Kd = Kd;
                fprintf('MCR-时域整定完成: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', Kp, Ki, Kd);
                return;
            end
            
            % MATLAB 环境：使用 pidtune
            ctype = obj.getControllerType();
            try
                [C, ~] = pidtune(obj.plant_model, ctype);
                [obj.Kp, obj.Ki, obj.Kd] = piddata(C);
                fprintf('自动整定完成: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', obj.Kp, obj.Ki, obj.Kd);
            catch ME
                error('pidtune失败: %s', ME.message);
            end
        end
        
        function designByFrequency(obj)
            % 频域设计：基于目标裕度和带宽
            % 在 MATLAB 环境调用 pidtune，在 MCR 使用解析频域整定
            if isempty(obj.design_params)
                error('请先设置设计参数');
            end
            
            if isdeployed
                % 1. 分析系统
                sys_params = obj.analyzeSystem();
                K = sys_params.gain;          % 静态增益
                wb = obj.target_wc;           % 目标带宽 (rad/s)
                
                % 2. 根据系统类型计算
                if strcmp(sys_params.type, 'first_order')
                    tau = sys_params.tau;
                    % PI 控制器
                    Ki = wb / K;
                    Kp = tau * wb / K;
                    Kd = 0;
                    fprintf('MCR-一阶零极点对消: Kp=%.4f, Ki=%.4f, Kd=%.4f (PM=90°)\n', Kp, Ki, Kd);
                    
                elseif strcmp(sys_params.type, 'second_order')
                    zeta = sys_params.zeta;
                    wn = sys_params.wn;
                    if zeta <= 0 || zeta >= 1
                        warning('阻尼比异常，改用保守PI');
                        % 降级处理：提取主导极点近似为一阶
                        p = sys_params.poles;
                        [~, idx] = min(abs(real(p)));
                        tau_dom = 1 / abs(real(p(idx)));
                        Ki = wb / K;
                        Kp = tau_dom * wb / K;
                        Kd = 0;
                    else
                        % PID 控制器（双零点对消）
                        Kd = wb / (K * wn^2);
                        Kp = 2 * zeta * wb / (K * wn);
                        Ki = wb / K;
                        fprintf('MCR-二阶零极点对消: Kp=%.4f, Ki=%.4f, Kd=%.4f (PM=90°)\n', Kp, Ki, Kd);
                    end
                    
                else
                    % 高阶系统：强行降阶为一阶（取主导极点）
                    warning('高阶系统自动降阶为主导极点一阶近似');
                    p = sys_params.poles;
                    [~, idx] = min(abs(real(p)));
                    tau_dom = 1 / abs(real(p(idx)));
                    Ki = wb / K;
                    Kp = tau_dom * wb / K;
                    Kd = 0;
                end
                
                % 赋值
                obj.Kp = Kp; obj.Ki = Ki; obj.Kd = Kd;
                return;
            end
            
            % MATLAB 环境：使用 pidtune 并应用相位裕度选项
            pm = obj.target_pm;
            opt = pidtuneOptions('PhaseMargin', pm, 'DesignFocus', 'reference-tracking');
            ctype = obj.getControllerType();
            try
                [C, ~] = pidtune(obj.plant_model, ctype, opt);
                [obj.Kp, obj.Ki, obj.Kd] = piddata(C);
                fprintf('频域设计完成: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', obj.Kp, obj.Ki, obj.Kd);
            catch ME
                error('频域设计失败: %s', ME.message);
            end
        end
        
        % ------------------------------------------------------------------
        % 辅助方法（公有）
        % ------------------------------------------------------------------
        function sys_params = analyzeSystem(obj)
            % 分析系统类型、增益、极点等
            [num, den] = tfdata(obj.plant_model, 'v');
            order = length(den) - 1;
            sys_params = struct();
            sys_params.gain = dcgain(obj.plant_model);
            sys_params.poles = pole(obj.plant_model);
            sys_params.zeros = zero(obj.plant_model);
            
            if order == 1
                sys_params.type = 'first_order';
                sys_params.tau = -1/real(sys_params.poles(1));
                try
                    [~, ~, ~, tau] = getDelayInfo(obj.plant_model);
                    sys_params.delay = tau;
                catch
                    sys_params.delay = 0;
                end
            elseif order == 2
                sys_params.type = 'second_order';
                wn = sqrt(real(sys_params.poles(1))^2 + imag(sys_params.poles(1))^2);
                zeta = -real(sys_params.poles(1))/wn;
                sys_params.wn = wn;
                sys_params.zeta = zeta;
                sys_params.delay = 0;
            else
                sys_params.type = 'higher_order';
                sys_params.delay = 0;
                try
                    sys_approx = reduce(obj.plant_model, 2);
                    [~, den2] = tfdata(sys_approx, 'v');
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
            % 搜索临界增益和周期（仅用于高阶系统）
            gains = logspace(-2, 2, 100);
            stability = zeros(size(gains));
            for i = 1:length(gains)
                sys_cl = feedback(gains(i) * obj.plant_model, 1);
                if all(real(pole(sys_cl)) < 0)
                    stability(i) = 1;
                end
            end
            idx = find(diff(stability) ~= 0, 1);
            if isempty(idx)
                Ku = 1; Tu = 1;
            else
                Ku = gains(idx);
                sys_cl = feedback(Ku * obj.plant_model, 1);
                step_info = stepinfo(sys_cl);
                Tu = step_info.PeakTime * 4;
            end
        end
        
        function TitoKi(obj, Ti, Td)
            % 将 Ti, Td 转换为 Ki, Kd (Ki = 1/Ti, Kd = Td)
            if Ti > 0, obj.Ki = 1 / Ti; else, obj.Ki = 0; end
            if Td > 0, obj.Kd = Td; else, obj.Kd = 0; end
        end
        
        function createController(obj)
            % 创建 pid 对象并计算闭环性能
            obj.controller = pid(obj.Kp, obj.Ki, obj.Kd);
            obj.closed_loop_sys = feedback(obj.controller * obj.plant_model, 1);
            poles_cl = pole(obj.closed_loop_sys);
            obj.performance.stable = all(real(poles_cl) < 0);
            [gm, pm, ~, wcp] = margin(obj.controller * obj.plant_model);
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
            % 在线调节 PID 参数并更新性能
            if isfield(params, 'Kp'), obj.Kp = params.Kp; end
            if isfield(params, 'Ti'), obj.Ti = params.Ti; end
            if isfield(params, 'Td'), obj.Td = params.Td; end
            obj.createController();
            obj.validate();
        end
        
        function validate(obj)
            % 打印当前参数和性能
            fprintf('PID[%s]: Kp=%.3f, Ki=%.3f, Kd=%.3f | 性能: Tr=%.2fs, OS=%.1f%%, Ts=%.2fs | PM=%.1f°, GM=%.2f\n', ...
                obj.design_method, obj.Kp, obj.Ki, obj.Kd, ...
                obj.rise_time, obj.overshoot, obj.settling_time, ...
                obj.phase_margin, obj.gain_margin);
        end
        
        function params = getParameters(obj)
            % 获取当前参数结构
            params = struct('Kp', obj.Kp, 'Ki', obj.Ki, 'Kd', obj.Kd, ...
                'Ti', obj.Ti, 'Td', obj.Td, 'design_method', obj.design_method, ...
                'performance', obj.performance, 'stability', ...
                struct('gain_margin', obj.gain_margin, 'phase_margin', obj.phase_margin, ...
                'crossover_freq', obj.crossover_freq));
        end
        
        % ------------------------------------------------------------------
        % 绘图方法（保留，略作精简）
        % ------------------------------------------------------------------
        function plotResults(obj, ax)
            if nargin < 2
                figure('Name', 'PID控制器设计结果', 'Position', [100, 100, 1200, 800]);
                ax = gobjects(4,1);
                for i = 1:4, ax(i) = subplot(2,2,i); end
            end
            obj.plotStepResponse(ax(1));
            obj.plotOpenLoopBode(ax(2));
            obj.plotRootLocus(ax(3));
            obj.plotControlSignal(ax(4));
        end
        
        function plotStepResponse(obj, ax)
            cla(ax);
            [y, t] = step(obj.closed_loop_sys, 10);
            plot(ax, t, y, 'b-', 'LineWidth', 2); hold(ax, 'on');
            plot(ax, [obj.performance.rise_time, obj.performance.rise_time], [0, 1], 'r--');
            plot(ax, obj.performance.rise_time, 1, 'ro', 'MarkerSize', 8);
            if obj.performance.overshoot > 0
                plot(ax, obj.performance.peak_time, obj.performance.peak, 'go', 'MarkerSize', 8);
                text(ax, obj.performance.peak_time, obj.performance.peak*1.05, ...
                    sprintf('OS=%.1f%%', obj.performance.overshoot), 'HorizontalAlignment', 'center');
            end
            plot(ax, [obj.performance.settling_time, obj.performance.settling_time], [0, 1.5], 'm--');
            hold(ax, 'off'); grid(ax, 'on');
            xlabel(ax, '时间 (s)'); ylabel(ax, '输出');
            title(ax, sprintf('闭环阶跃响应 (Tr=%.3fs, OS=%.1f%%)', obj.performance.rise_time, obj.performance.overshoot));
            ylim([0, max(1.2, max(y)*1.1)]);
        end
        
        function plotOpenLoopBode(obj, ax)
            cla(ax);
            sys_open = obj.controller * obj.plant_model;
            [mag, phase, w] = bode(sys_open, {0.01, 100});
            yyaxis(ax, 'left');
            semilogx(ax, w, 20*log10(squeeze(mag)), 'b-', 'LineWidth', 2);
            ylabel(ax, '幅值 (dB)');
            hold(ax, 'on');
            semilogx(ax, [obj.crossover_freq, obj.crossover_freq], [-100, 0], 'r--');
            semilogx(ax, obj.crossover_freq, 0, 'ro', 'MarkerSize', 8);
            text(ax, obj.crossover_freq, -5, sprintf('ωc=%.3f', obj.crossover_freq), 'HorizontalAlignment', 'center');
            hold(ax, 'off');
            yyaxis(ax, 'right');
            semilogx(ax, w, squeeze(phase), 'r-', 'LineWidth', 2);
            ylabel(ax, '相位 (度)');
            xlabel(ax, '频率 (rad/s)');
            title(ax, sprintf('开环Bode图 (PM=%.1f°, GM=%.2f)', obj.phase_margin, obj.gain_margin));
            grid(ax, 'on');
        end
        
        function plotRootLocus(obj, ax)
            cla(ax);
            rlocus(ax, obj.plant_model * obj.controller);
            grid(ax, 'on');
            title(ax, '根轨迹图');
        end
        
        function plotControlSignal(obj, ax)
            cla(ax);
            t = 0:0.01:10;
            y = step(obj.closed_loop_sys, t);
            u = obj.Kp * (1 - y) + obj.Ki * cumtrapz(t, 1 - y) + obj.Kd * gradient(1 - y, t);
            plot(ax, t, u, 'g-', 'LineWidth', 2);
            grid(ax, 'on');
            xlabel(ax, '时间 (s)'); ylabel(ax, '控制信号 u(t)');
            title(ax, '控制信号');
            u_max = max(abs(u));
            text(ax, 0.05, 0.95, sprintf('max|u|=%.3f', u_max), 'Units', 'normalized', ...
                'VerticalAlignment', 'top', 'BackgroundColor', 'white');
        end
    end
    
    % ------------------------------------------------------------------
    % 私有辅助方法（仅用于 MCR 解析整定）
    % ------------------------------------------------------------------
    methods (Access = private)
        function [K, tau] = extractFirstOrder(obj)
            % 从一阶传递函数提取增益和时间常数
            [num, den] = tfdata(obj.plant_model, 'v');
            K = num(end) / den(end);
            p = roots(den);
            p_real = p(imag(p) == 0 & real(p) < 0);
            if isempty(p_real)
                error('无法提取一阶模型参数');
            end
            tau = 1 / max(abs(p_real));
        end
        
        function [Kp, Ki, Kd] = tuneByOvershootRise(~, K, tau, overshoot, rise_time)
            % 基于超调和上升时间的 PI 整定（极点配置）
            if overshoot <= 0
                zeta = 1;
            else
                zeta = sqrt( (log(overshoot))^2 / (pi^2 + (log(overshoot))^2) );
            end
            if zeta < 0.7
                wn = 1.8 / (rise_time * zeta);
            else
                wn = 1.8 / rise_time;
            end
            Kp = (2*zeta*wn*tau - 1) / K;
            if Kp <= 0
                warning('期望极点无法用 PI 实现，采用保守参数');
                Kp = 0.5 / K;
                Ti = tau;
            else
                Ti = K * Kp / (tau * wn^2);
            end
            Ki = Kp / Ti;
            Kd = 0;
        end
        
        function ctype = getControllerType(obj)
            % 获取控制器类型（P/PI/PID）
            if isfield(obj.design_params, 'controller_type')
                if iscell(obj.design_params.controller_type)
                    ctype = obj.design_params.controller_type{1};
                else
                    ctype = obj.design_params.controller_type;
                end
            else
                ctype = 'PID';
            end
        end
    end
end