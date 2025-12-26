%% PIDController 类完整测试 - 简单系统 1/(s+1)
clear; close all; clc;

%% 1. 创建被控对象模型
s = tf('s');
G = 3 / (s + 1);  % 一阶惯性系统

fprintf('========================================\n');
fprintf('PID控制器所有设计方法测试\n');
fprintf('========================================\n\n');
fprintf('被控对象: G(s) = 1/(s+1)\n\n');

%% 2. 测试所有设计方法 
methods = {
    'ziegler_nichols',   'Ziegler-Nichols方法';
    'cohen_coon',        'Cohen-Coon方法';
    'imc',               '内模控制(IMC)方法';
    'itae',              'ITAE最优整定';
    'auto_tune',         '自动整定方法';
    'frequency',         '频域设计方法';
    'manual',            '手动调节方法';
};

% 存储所有设计结果
all_results = struct();

for i = 1:size(methods, 1)
    method_name = methods{i, 1};
    method_desc = methods{i, 2};
    
    fprintf('\n----------------------------------------\n');
    fprintf('方法%d: %s\n', i, method_desc);
    fprintf('----------------------------------------\n');
    
    try
        % 创建控制器对象
        pid_ctrl = PIDController(G);
        pid_ctrl.design_method = method_name;
        
        % 设置设计参数
        design_params = struct();
        design_params.controller_type = 'PID';  % 控制器类型
        
        % 根据不同方法设置特定参数
        switch method_name
            case 'ziegler_nichols'
                design_params.rise_time = 0.5;
                design_params.overshoot = 5;
                
            case 'cohen_coon'
                % Cohen-Coon适用于有延迟系统，为演示添加延迟
                design_params.controller_type = 'PID';
                
            case 'imc'
                % IMC方法需要lambda参数
                design_params.lambda = 0.5;  % 滤波器时间常数
                
            case 'itae'
                design_params.rise_time = 0.5;
                design_params.overshoot = 5;
                
            case 'frequency'
                % 频域设计参数
                design_params.target_pm = 60;   % 目标相位裕度
                design_params.target_gm = 10;   % 目标增益裕度(分贝)
                design_params.target_wc = 100;    % 目标穿越频率
                
            case 'manual'
                % 手动调节参数
                design_params.Kp = 1.5;
                design_params.Ti = 1.0;
                design_params.Td = 0.2;
                
            case 'auto_tune'
                % 自动整定不需要特殊参数
                % 使用默认参数
        end
        
        pid_ctrl.design_params = design_params;
        
        % 执行设计
        pid_ctrl.design();
        
        % 获取参数
        all_results.(method_name) = pid_ctrl.getParameters();
        
        % 显示设计结果
        fprintf('设计成功！\n');
        fprintf('控制器参数: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', ...
            pid_ctrl.Kp, pid_ctrl.Ki, pid_ctrl.Kd);
        fprintf('性能指标: Tr=%.3fs, OS=%.1f%%, Ts=%.3fs\n', ...
            pid_ctrl.performance.rise_time, ...
            pid_ctrl.performance.overshoot, ...
            pid_ctrl.performance.settling_time);
        fprintf('稳定裕度: PM=%.1f°, GM=%.2f\n', ...
            pid_ctrl.phase_margin, pid_ctrl.gain_margin);
        
        % 绘制结果
        figure('Name', sprintf('%s 设计结果', method_desc), ...
            'Position', [100+i*30, 100+i*30, 1200, 800]);
        
        % 创建子图
        ax1 = subplot(2,2,1);
        ax2 = subplot(2,2,2);
        ax3 = subplot(2,2,3);
        ax4 = subplot(2,2,4);
        
        pid_ctrl.plotStepResponse(ax1);
        pid_ctrl.plotOpenLoopBode(ax2);
        pid_ctrl.plotRootLocus(ax3);
        pid_ctrl.plotControlSignal(ax4);
        
        % 添加方法标题
        sgtitle(sprintf('%s - PID控制器设计', method_desc), 'FontSize', 14);
        
    catch ME
        fprintf('设计失败: %s\n', ME.message);
        if ~strcmp(method_name, 'manual')
            % 对于非手动方法，尝试显示错误详情
            fprintf('错误详情:\n');
            fprintf('%s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
        end
    end
end


%% 4. 对比所有方法的阶跃响应
figure('Name', '所有方法阶跃响应对比', 'Position', [200, 200, 1000, 600]);
hold on;

colors = lines(length(methods));
legend_entries = cell(1, 0);

for i = 1:size(methods, 1)
    method_name = methods{i, 1};
    
    if isfield(all_results, method_name)
        % 获取该方法的控制器
        pid_ctrl = PIDController(G);
        pid_ctrl.design_method = method_name;
        
        % 恢复设计参数
        switch method_name
            case 'manual'
                design_params = struct();
                design_params.Kp = all_results.(method_name).Kp;
                design_params.Ti = all_results.(method_name).Ti;
                design_params.Td = all_results.(method_name).Td;
            case 'imc'
                design_params = struct();
                design_params.lambda = 0.5;
            case 'frequency'
                design_params = struct();
                design_params.target_pm = 60;
                design_params.target_gm = 10;
                design_params.target_wc = 2;
            otherwise
                design_params = struct();
                design_params.controller_type = 'PID';
        end
        
        pid_ctrl.design_params = design_params;
        pid_ctrl.design();
        
        % 绘制阶跃响应
        [y, t] = step(pid_ctrl.closed_loop_sys, 5);
        plot(t, y, 'LineWidth', 1.5, 'Color', colors(i,:));
        
        legend_entries{end+1} = methods{i, 2};
    end
end

% 添加参考线
plot([0, 5], [1, 1], 'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
plot([0, 5], [1.05, 1.05], 'k:', 'LineWidth', 0.5, 'HandleVisibility', 'off');
plot([0, 5], [0.95, 0.95], 'k:', 'LineWidth', 0.5, 'HandleVisibility', 'off');

grid on;
xlabel('时间 (s)');
ylabel('输出');
title('不同PID设计方法的阶跃响应对比');
legend(legend_entries, 'Location', 'best');
xlim([0, 5]);
ylim([0, 1.5]);