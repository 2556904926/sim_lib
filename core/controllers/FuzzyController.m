classdef FuzzyController < BaseController
    % FUZZYCONTROLLER 模糊控制器设计类
    
    properties
        name = '模糊控制器'
        description = '基于模糊逻辑的智能控制器'
        controller_type = 'Fuzzy'
        
        % 简化的模糊控制参数
        kp_base = 1.0         % 基础比例增益
        ki_base = 0.1         % 基础积分增益
        kd_base = 0.01        % 基础微分增益
        
        % 模糊规则表 (简化的)
        rule_table              % 规则表
        
        % 归一化参数
        error_max = 1.0
        error_rate_max = 1.0
        output_max = 1.0
    end
    
    methods
        function obj = FuzzyController(plant_model)
            % 构造函数
            if nargin > 0
                obj.plant_model = plant_model;
            end
            
            % 初始化简化的模糊规则
            obj.initializeSimpleFuzzyRules();
        end
        
        function initializeSimpleFuzzyRules(obj)
            % 初始化简化的模糊控制规则
            % 使用查表法实现模糊控制，避免依赖工具箱
            
            % 规则表: [error_level, error_rate_level] -> [kp_factor, ki_factor, kd_factor]
            obj.rule_table = zeros(5, 5, 3);
            
            % NB: Negative Big, NS: Negative Small, Z: Zero, PS: Positive Small, PB: Positive Big
            
            % error = NB
            obj.rule_table(1, 1, :) = [2.0, 0.0, 0.5];   % NB, NB
            obj.rule_table(1, 2, :) = [1.8, 0.0, 0.4];   % NB, NS
            obj.rule_table(1, 3, :) = [1.5, 0.1, 0.3];   % NB, Z
            obj.rule_table(1, 4, :) = [1.2, 0.2, 0.2];   % NB, PS
            obj.rule_table(1, 5, :) = [1.0, 0.3, 0.1];   % NB, PB
            
            % error = NS
            obj.rule_table(2, 1, :) = [1.8, 0.0, 0.4];
            obj.rule_table(2, 2, :) = [1.5, 0.1, 0.3];
            obj.rule_table(2, 3, :) = [1.2, 0.2, 0.2];
            obj.rule_table(2, 4, :) = [1.0, 0.3, 0.1];
            obj.rule_table(2, 5, :) = [0.8, 0.4, 0.0];
            
            % error = Z
            obj.rule_table(3, 1, :) = [1.5, 0.1, 0.3];
            obj.rule_table(3, 2, :) = [1.2, 0.2, 0.2];
            obj.rule_table(3, 3, :) = [1.0, 0.3, 0.1];
            obj.rule_table(3, 4, :) = [0.8, 0.4, 0.0];
            obj.rule_table(3, 5, :) = [0.6, 0.5, 0.0];
            
            % error = PS
            obj.rule_table(4, 1, :) = [1.2, 0.2, 0.2];
            obj.rule_table(4, 2, :) = [1.0, 0.3, 0.1];
            obj.rule_table(4, 3, :) = [0.8, 0.4, 0.0];
            obj.rule_table(4, 4, :) = [0.6, 0.5, 0.0];
            obj.rule_table(4, 5, :) = [0.4, 0.6, 0.0];
            
            % error = PB
            obj.rule_table(5, 1, :) = [1.0, 0.3, 0.1];
            obj.rule_table(5, 2, :) = [0.8, 0.4, 0.0];
            obj.rule_table(5, 3, :) = [0.6, 0.5, 0.0];
            obj.rule_table(5, 4, :) = [0.4, 0.6, 0.0];
            obj.rule_table(5, 5, :) = [0.2, 0.8, 0.0];
        end
        
        function design(obj)
            % 设计模糊控制器
            % 使用简化的PID-like模糊控制
            
            % 创建一个基本的PID控制器作为近似
            obj.controller = pid(obj.kp_base, obj.ki_base, obj.kd_base);
            
            if ~isempty(obj.plant_model)
                obj.closed_loop_sys = feedback(obj.plant_model * obj.controller, 1);
            end
        end
        
        function tune(obj, params)
            % 调节模糊控制器参数
            if isfield(params, 'kp_base')
                obj.kp_base = params.kp_base;
            end
            if isfield(params, 'ki_base')
                obj.ki_base = params.ki_base;
            end
            if isfield(params, 'kd_base')
                obj.kd_base = params.kd_base;
            end
            
            % 重新设计
            obj.design();
        end
        
        function validate(obj)
            % 验证模糊控制器设计
            if isempty(obj.controller)
                error('请先设计模糊控制器');
            end
            
            if isempty(obj.closed_loop_sys)
                warning('闭环系统模型不可用，无法进行稳定性分析');
            else
                % 计算性能指标
                obj.calculatePerformance();
            end
        end
        
        function output = evaluate(obj, error, error_rate)
            % 评估模糊控制器输出
            % 归一化输入
            e_norm = min(max(error / obj.error_max, -1), 1);
            de_norm = min(max(error_rate / obj.error_rate_max, -1), 1);
            
            % 确定隶属度等级 (1-5)
            e_level = obj.getMembershipLevel(e_norm);
            de_level = obj.getMembershipLevel(de_norm);
            
            % 从规则表获取增益因子
            factors = squeeze(obj.rule_table(e_level, de_level, :));
            
            % 计算PID输出 (简化的PI控制)
            kp = obj.kp_base * factors(1);
            ki = obj.ki_base * factors(2);
            
            % 简单的PI控制（不使用积分状态）
            output = kp * error + ki * error_rate;
            
            % 限制输出
            output = min(max(output, -obj.output_max), obj.output_max);
        end
        
        function level = getMembershipLevel(obj, value)
            % 获取隶属度等级
            if value <= -0.6
                level = 1;      % NB
            elseif value <= -0.2
                level = 2;      % NS
            elseif value <= 0.2
                level = 3;      % Z
            elseif value <= 0.6
                level = 4;      % PS
            else
                level = 5;      % PB
            end
        end
    end
end
