% %% 完整可运行的优化代码
% clear; clc;

% sys = tf(3,[1,1]);  

% % 2. 直接在代码中定义目标函数（内联定义）
% problem.objective = @(K) my_cost_function(K, sys);

% % 3. 定义这个函数（就在这里写！）
% function cost = my_cost_function(K, sys)
%     % 提取PID参数
%     Kp = K(1);
%     Ki = K(2);
%     Kd = K(3);
    
%     % 创建PID控制器
%     C = pid(Kp, Ki, Kd);
    
%     % 闭环系统
%     sys_cl = feedback(C * sys, 1);
    
%     % 获取性能指标
%     try
%         info = stepinfo(sys_cl);
        
%         % 目标上升时间（示例：希望0.5秒）
%         target_rise = 0.5;
        
%         % 成本函数：惩罚与目标的偏差
%         cost = abs(info.RiseTime - target_rise) * 10 + ...  % 上升时间偏差
%                max(0, info.Overshoot - 5) * 2 + ...         % 超调惩罚（>5%时）
%                info.SettlingTime * 0.5;                     % 调节时间惩罚
%     catch
%         % 如果系统不稳定，给一个大惩罚值
%         cost = 1e6;
%     end
% end

% % 4. 优化问题设置
% problem.x0 = [1, 0.5, 0.1];    % 初始猜测 [Kp, Ki, Kd]
% problem.lb = [0, 0, 0];        % 下界
% problem.ub = [20, 10, 5];      % 上界
% problem.solver = 'fmincon';
% problem.options = optimoptions('fmincon', ...
%     'Display', 'iter', ...
%     'MaxIterations', 100);

% % 5. 运行优化
% [K_opt, fval] = fmincon(problem);

% % 6. 显示结果
% fprintf('\n=== 优化结果 ===\n');
% fprintf('最优参数: Kp = %.4f, Ki = %.4f, Kd = %.4f\n', K_opt(1), K_opt(2), K_opt(3));
% fprintf('最小成本值: %.4f\n', fval);

% % 7. 验证
% C_opt = pid(K_opt(1), K_opt(2), K_opt(3));
% sys_cl_opt = feedback(C_opt * sys, 1);
% step(sys_cl_opt);
% grid on;
% info_opt = stepinfo(sys_cl_opt);
% title(sprintf('上升时间=%.3fs, 超调=%.1f%%, 调节时间=%.3fs', ...
%     info_opt.RiseTime, info_opt.Overshoot, info_opt.SettlingTime));



% %% 使用pidtune进行PID参数优化
clear; clc;
sys = tf(3, [1, 1]);  % 示例系统
[C, info] = pidtune(sys, 'PID');  % 自动优化PID
fprintf('优化后的PID参数: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', C.Kp, C.Ki, C.Kd);
C_opt = pid(C.Kp, C.Ki, C.Kd);
sys_cl_opt = feedback(C_opt * sys, 1);
step(sys_cl_opt);
grid on;
info_opt = stepinfo(sys_cl_opt);

fprintf('性能指标: Tr=%.3fs, OS=%.1f%%, Ts=%.3fs\n', ...
    info_opt.RiseTime, info_opt.Overshoot, info_opt.SettlingTime);



opt = pidtuneOptions(...
    'DesignFocus', 'reference-tracking', ...  % 参考跟踪
    'PhaseMargin', 60);                  % 相位裕度;                   % 目标带宽
[C, info] = pidtune(sys, 'PID', opt);
fprintf('使用高级设置优化后的PID参数: Kp=%.4f, Ki=%.4f, Kd=%.4f\n', C.Kp, C.Ki, C.Kd);
C_opt = pid(C.Kp, C.Ki, C.Kd);
sys_cl_opt = feedback(C_opt * sys, 1);
step(sys_cl_opt);
grid on;
info_opt = stepinfo(sys_cl_opt);
title(sprintf('上升时间=%.3fs, 超调=%.1f%%, 调节时间=%.3fs', ...
    info_opt.RiseTime, info_opt.Overshoot, info_opt.SettlingTime));