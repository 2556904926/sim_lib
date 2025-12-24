classdef SystemIdentifier < BaseSystem
    % SYSTEMIDENTIFIER 系统辨识器
    
    properties
        name = '系统辨识器'
        description = '基于输入输出数据的系统辨识'
        
        % 辨识参数
        num_order = 0
        den_order = 2
        estimation_method = 'tfest'
        
        % 辨识模型
        sys_est
        fitting_percent
        validation_metrics
    end
    
    methods
        function obj = SystemIdentifier(varargin)
            % 构造函数
            p = inputParser;
            addParameter(p, 'num_order', 0);
            addParameter(p, 'den_order', 2);
            addParameter(p, 'Ts', 0.01);
            parse(p, varargin{:});
            
            obj.num_order = p.Results.num_order;
            obj.den_order = p.Results.den_order;
            obj.Ts = p.Results.Ts;
        end
        
        function initialize(obj)
            % 初始化
            obj.data = struct();
            obj.results = struct();
        end
        
        function process(obj, t, u, y)
            % 执行系统辨识
            obj.validateData(t, u, y);
            
            % 存储数据
            obj.data.t = t;
            obj.data.u = u;
            obj.data.y = y;
            
            % 执行辨识
            obj.identifySystem();
            
            % 验证结果
            obj.validate();
        end
        
        function validateData(obj, t, u, y)
            % 数据验证
            if length(t) ~= length(u) || length(t) ~= length(y)
                error('数据长度不匹配');
            end
            
            if length(t) < 100
                warning('数据点数较少，可能影响辨识精度');
            end
        end
        
        function identifySystem(obj)
            % 执行辨识算法
            data_iddata = iddata(obj.data.y, obj.data.u, obj.Ts);
            
            % 根据选择的方法进行辨识
            switch obj.estimation_method
                case 'tfest'
                    opt = tfestOptions('Display', 'off', 'SearchMethod', 'lm');
                    obj.sys_est = tfest(data_iddata, obj.den_order, obj.num_order, opt);
                case 'ssest'
                    opt = ssestOptions('Display', 'off');
                    sys_ss = ssest(data_iddata, obj.den_order, opt);
                    obj.sys_est = tf(sys_ss);
                case 'procest'
                    % 过程模型辨识（适合一阶/二阶系统）
                    sys_p = procest(data_iddata, 'P1D');
                    obj.sys_est = tf(sys_p);
                otherwise
                    error('未知的辨识方法: %s', obj.estimation_method);
            end
            
            % 计算拟合度
            obj.calculateFitting();
        end
        
        function calculateFitting(obj)
            % 计算模型拟合度
            y_sim = lsim(obj.sys_est, obj.data.u, obj.data.t);
            y_meas = obj.data.y;
            
            residual = y_meas - y_sim;
            ss_res = sum(residual.^2);
            ss_tot = sum((y_meas - mean(y_meas)).^2);
            obj.fitting_percent = max(0, (1 - ss_res/ss_tot) * 100);
            
            % 存储验证指标
            obj.validation_metrics = struct();
            obj.validation_metrics.mse = mean(residual.^2);
            obj.validation_metrics.rmse = sqrt(obj.validation_metrics.mse);
            obj.validation_metrics.mae = mean(abs(residual));
        end
        
        function validate(obj)
            % 验证辨识结果
            obj.results.validation_passed = obj.fitting_percent > 70;
            obj.results.fitting_percent = obj.fitting_percent;
            obj.results.metrics = obj.validation_metrics;
        end
        
        function results = getResults(obj)
            % 获取结果
            results = struct();
            results.sys_tf = obj.sys_est;
            results.sys_zpk = zpk(obj.sys_est);
            [num, den] = tfdata(obj.sys_est, 'v');
            results.num = num;
            results.den = den;
            results.gain = dcgain(obj.sys_est);
            results.poles = pole(obj.sys_est);
            results.zeros = zero(obj.sys_est);
            results.fitting = obj.fitting_percent;
            results.metrics = obj.validation_metrics;
            results.Ts = obj.Ts;
            
            % 提取一阶/二阶系统参数
            results = obj.extractSystemParams(results);
        end
        
        function results = extractSystemParams(obj, results)
            % 提取系统参数
            if obj.den_order == 1 && obj.num_order == 0
                % 一阶系统: K/(τs+1)
                results.K = results.gain;
                results.tau = -1/real(results.poles(1));
                results.system_type = 'first_order';
                
            elseif obj.den_order == 2 && obj.num_order == 0
                % 二阶系统: K/(s^2 + 2ζωs + ω^2)
                results.K = results.gain;
                wn = sqrt(real(results.poles(1))^2 + imag(results.poles(1))^2);
                zeta = -real(results.poles(1))/wn;
                results.wn = wn;
                results.zeta = zeta;
                results.system_type = 'second_order';
                
            else
                results.system_type = 'higher_order';
            end
        end
        
        function plotResults(obj, ax)
            % 绘制辨识结果
            if nargin < 2
                figure;
                ax = subplot(2,2,1);
            end
            
            % 创建多个子图
            if isa(ax, 'matlab.graphics.axis.Axes')
                % 单个坐标轴，创建子图
                figure(ax.Parent);
                clf;
                
                % 时域对比
                ax1 = subplot(2,2,1);
                obj.plotTimeDomain(ax1);
                
                % 阶跃响应
                ax2 = subplot(2,2,2);
                obj.plotStepResponse(ax2);
                
                % 零极点图
                ax3 = subplot(2,2,3);
                obj.plotPoleZero(ax3);
                
                % Bode图
                ax4 = subplot(2,2,4);
                obj.plotBode(ax4);
                
            else
                % 已提供坐标轴数组
                obj.plotTimeDomain(ax(1));
                obj.plotStepResponse(ax(2));
                obj.plotPoleZero(ax(3));
                obj.plotBode(ax(4));
            end
        end
        
        function plotTimeDomain(obj, ax)
            % 绘制时域对比
            cla(ax);
            
            % 实际数据
            plot(ax, obj.data.t, obj.data.y, 'b-', 'LineWidth', 1.5, ...
                'DisplayName', '实际输出');
            hold(ax, 'on');
            
            % 模型输出
            y_sim = lsim(obj.sys_est, obj.data.u, obj.data.t);
            plot(ax, obj.data.t, y_sim, 'r--', 'LineWidth', 2, ...
                'DisplayName', '模型输出');
            
            % 残差
            residual = obj.data.y - y_sim;
            plot(ax, obj.data.t, residual, 'g:', 'LineWidth', 1, ...
                'DisplayName', '残差');
            
            hold(ax, 'off');
            
            grid(ax, 'on');
            xlabel(ax, '时间 (s)');
            ylabel(ax, '幅值');
            legend(ax, 'Location', 'best');
            title(ax, sprintf('时域对比 (拟合度: %.2f%%)', obj.fitting_percent));
        end
        
        function plotStepResponse(obj, ax)
            % 绘制阶跃响应
            cla(ax);
            
            [y_step, t_step] = step(obj.sys_est);
            plot(ax, t_step, y_step, 'm-', 'LineWidth', 2);
            
            % 标注稳态值
            ss_value = dcgain(obj.sys_est);
            if ~isnan(ss_value) && ~isinf(ss_value)
                hold(ax, 'on');
                plot(ax, [t_step(1), t_step(end)], [ss_value, ss_value], 'r--');
                text(ax, t_step(end), ss_value, sprintf('K=%.3f', ss_value), ...
                    'VerticalAlignment', 'bottom');
                hold(ax, 'off');
            end
            
            grid(ax, 'on');
            xlabel(ax, '时间 (s)');
            ylabel(ax, '幅值');
            title(ax, '阶跃响应');
        end
        
        function plotPoleZero(obj, ax)
            % 绘制零极点图
            cla(ax);
            
            pzmap(ax, obj.sys_est);
            grid(ax, 'on');
            title(ax, '零极点分布');
        end
        
        function plotBode(obj, ax)
            % 绘制Bode图
            cla(ax);
            
            w = logspace(-2, 2, 200);
            [mag, phase, wout] = bode(obj.sys_est, w);
            
            yyaxis(ax, 'left');
            semilogx(ax, wout, 20*log10(squeeze(mag)), 'b-', 'LineWidth', 2);
            ylabel(ax, '幅值 (dB)');
            
            yyaxis(ax, 'right');
            semilogx(ax, wout, squeeze(phase), 'r-', 'LineWidth', 2);
            ylabel(ax, '相位 (度)');
            
            xlabel(ax, '频率 (rad/s)');
            title(ax, 'Bode图');
            grid(ax, 'on');
        end
        
        function tf_str = getTransferFunctionString(obj)
            % 获取传递函数字符串
            [num, den] = tfdata(obj.sys_est, 'v');
            
            % 简化显示
            num_str = poly2str(num, 's');
            den_str = poly2str(den, 's');
            
            tf_str = sprintf('G(s) = %s / %s', num_str, den_str);
        end
    end
end

function str = poly2str(poly_coeffs, var)
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
            else
                term = sprintf('%.4f%s', coeff, var);
            end
        else
            if abs(coeff - 1) < 1e-10
                term = sprintf('%s^%d', var, power);
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
end