classdef LQRController < BaseController
    % LQRCONTROLLER LQR最优控制器设计类
    
    properties
        name = 'LQR最优控制器'
        description = '线性二次型调节器(LQR)最优控制'
        controller_type = 'LQR'
        
        % LQR参数
        Q = eye(2)          % 状态权重矩阵
        R = 1               % 输入权重矩阵
        
        % 增益矩阵
        K                   % 反馈增益矩阵
        
        % 状态空间模型
        state_space_model
    end
    
    methods
        function obj = LQRController(plant_model)
            % 构造函数
            if nargin > 0
                obj.plant_model = plant_model;
            end
        end
        
        function design(obj)
            % 设计LQR控制器
            if isempty(obj.plant_model)
                error('请先设置被控对象模型');
            end
            
            try
                % 将传递函数转换为状态空间模型
                if isa(obj.plant_model, 'tf')
                    obj.state_space_model = ss(obj.plant_model);
                elseif isa(obj.plant_model, 'ss')
                    obj.state_space_model = obj.plant_model;
                else
                    error('不支持的模型类型');
                end
                
                % 确保是连续时间系统
                if obj.state_space_model.Ts > 0
                    obj.state_space_model = d2c(obj.state_space_model);
                end
                
                % 获取系统矩阵
                A = obj.state_space_model.A;
                B = obj.state_space_model.B;
                C = obj.state_space_model.C;
                D = obj.state_space_model.D;
                
                % 调整权重矩阵维度
                n_states = size(A, 1);
                n_inputs = size(B, 2);
                n_outputs = size(C, 1);
                
                if size(obj.Q, 1) ~= n_states || size(obj.Q, 2) ~= n_states
                    obj.Q = eye(n_states);
                end
                
                if size(obj.R, 1) ~= n_inputs || size(obj.R, 2) ~= n_inputs
                    obj.R = eye(n_inputs);
                end
                
                % 求解Riccati方程
                [K, S, P] = lqr(A, B, obj.Q, obj.R);
                obj.K = K;
                
                % 创建控制器传递函数
                controller_tf = tf(K, 1);
                
                % 创建闭环系统
                obj.controller = controller_tf;
                obj.closed_loop_sys = feedback(obj.plant_model * controller_tf, 1);
                
            catch ME
                error('LQR控制器设计失败: %s', ME.message);
            end
        end
        
        function tune(obj, params)
            % 调节LQR参数
            if isfield(params, 'Q')
                obj.Q = params.Q;
            end
            if isfield(params, 'R')
                obj.R = params.R;
            end
            
            % 重新设计控制器
            obj.design();
        end
        
        function validate(obj)
            % 验证LQR设计
            if isempty(obj.K)
                error('请先设计LQR控制器');
            end
            
            % 检查闭环稳定性
            poles = pole(obj.closed_loop_sys);
            if any(real(poles) > 0)
                warning('闭环系统不稳定');
            end
            
            % 计算性能指标
            obj.calculatePerformance();
        end
        
        function setWeights(obj, Q, R)
            % 设置权重矩阵
            obj.Q = Q;
            obj.R = R;
        end
    end
end