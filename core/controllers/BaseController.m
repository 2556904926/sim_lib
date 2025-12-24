classdef BaseController < handle
    % BASECONTROLLER 控制器基类
    % 定义控制器的基本接口
    
    properties (Abstract)
        name                % 控制器名称
        description         % 控制器描述
        controller_type     % 控制器类型
    end
    
    properties
        plant_model         % 被控对象模型
        design_params       % 设计参数
        controller          % 控制器模型
        closed_loop_sys     % 闭环系统
        performance         % 性能指标
        simulation_results  % 仿真结果
    end
    
    methods (Abstract)
        design(obj)         % 设计控制器
        tune(obj, params)   % 调节参数
        validate(obj)       % 验证设计
    end
    
    methods
        function obj = BaseController(plant_model)
            % 构造函数
            if nargin > 0
                obj.plant_model = plant_model;
            end
        end
        
        function setPlantModel(obj, plant_model)
            % 设置被控对象
            obj.plant_model = plant_model;
        end
        
        function setDesignParams(obj, params)
            % 设置设计参数
            obj.design_params = params;
        end
        
        function simulate(obj, t_final, reference, disturbance)
            % 仿真闭环系统
            if nargin < 3
                reference = 1;  % 单位阶跃
            end
            
            if nargin < 4
                disturbance = 0;
            end
            
            if isempty(obj.closed_loop_sys)
                error('请先设计控制器');
            end
            
            t = 0:0.01:t_final;
            
            if isnumeric(reference) && isscalar(reference)
                % 阶跃响应
                [y, t] = step(reference * obj.closed_loop_sys, t_final);
            else
                % 自定义参考输入
                y = lsim(obj.closed_loop_sys, reference, t);
            end
            
            obj.simulation_results.t = t;
            obj.simulation_results.y = y;
            
            % 计算性能指标
            obj.calculatePerformance(y, t);
        end
        
        function calculatePerformance(obj, y, t)
            % 计算性能指标
            if nargin < 2
                y = obj.simulation_results.y;
                t = obj.simulation_results.t;
            end
            
            % 阶跃响应特性
            step_info = stepinfo(y, t);
            
            obj.performance = struct();
            obj.performance.rise_time = step_info.RiseTime;
            obj.performance.overshoot = step_info.Overshoot;
            obj.performance.settling_time = step_info.SettlingTime;
            obj.performance.peak = step_info.Peak;
            obj.performance.peak_time = step_info.PeakTime;
            obj.performance.steady_state_error = abs(1 - y(end));
            
            % 计算误差积分指标
            error = 1 - y;
            obj.performance.ise = trapz(t, error.^2);
            obj.performance.itae = trapz(t, t .* abs(error));
            obj.performance.iae = trapz(t, abs(error));
        end
        
        function plotResults(obj, ax)
            % 绘制控制器结果
            if nargin < 2
                figure;
                ax = gca;
            end
            cla(ax);
            text(ax, 0.5, 0.5, '未实现绘图功能', ...
                'HorizontalAlignment', 'center');
            axis(ax, 'off');
        end
        
        function exportController(obj, filename)
            % 导出控制器
            controller_data = struct();
            controller_data.type = obj.controller_type;
            controller_data.params = obj.getParameters();
            controller_data.performance = obj.performance;
            
            save(filename, 'controller_data');
        end
        
        function params = getParameters(obj)
            % 获取控制器参数（子类重写）
            params = struct();
        end
    end
end