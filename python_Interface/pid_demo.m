%% test_pid_controller.m
% 测试 PIDController 所有接口

clear; clc; close all;

fprintf('========== 测试 pid_controller 接口 ==========\n\n');

%% 1. create - 创建对象
fprintf('1. create: ');
obj = pid_controller('create', 'design_method', 'frequency','controller_type','pi');
fprintf('obj_id = %d ✓\n', obj);

%% 2. set_plant - 设置被控对象
fprintf('2. set_plant: ');
num = [0,104.0396];
den = [1.0,5524.211810636967];
pid_controller('set_plant', obj, num, den);
fprintf('G(s) = %s / [%s] ✓\n', num2str(num), num2str(den));

%% 3. set_params - 设置设计参数（可选）
fprintf('3. set_params: ');
pid_controller('set_params', obj,'target_wc', 1000, 'reference_value', 1, ...
    'controller_type','PI');

%% 4. design - 执行设计
fprintf('4. design: ');
pid_controller('design', obj);
fprintf('✓\n');

%% 5. get_kp / get_ki / get_kd - 获取PID参数
fprintf('5. get_kp/get_ki/get_kd: ');
kp = pid_controller('get_kp', obj);
ki = pid_controller('get_ki', obj);
kd = pid_controller('get_kd', obj);
fprintf('Kp=%.4f, Ki=%.4f, Kd=%.4f ✓\n', kp, ki, kd);

%% 6. get_phase_margin / get_gain_margin - 获取裕度
fprintf('6. get_phase_margin/get_gain_margin: ');
pm = pid_controller('get_phase_margin', obj);
gm = pid_controller('get_gain_margin', obj);
fprintf('PM=%.2f°, GM=%.2f ✓\n', pm, gm);

%% 7. get_rise_time / get_overshoot / get_settling_time - 获取性能
fprintf('7. get_rise_time/get_overshoot/get_settling_time: ');
rt = pid_controller('get_rise_time', obj);
os = pid_controller('get_overshoot', obj);
st = pid_controller('get_settling_time', obj);
fprintf('Tr=%.3fs, OS=%.2f%%, Ts=%.3fs ✓\n', rt, os, st);

%% 8. get_performance - 获取完整性能结构体
fprintf('8. get_performance: ');
perf = pid_controller('get_performance', obj);
fprintf('包含 %d 个字段 ✓\n', numel(fieldnames(perf)));

%% 9. get_params - 获取完整参数
fprintf('9. get_params: ');
params = pid_controller('get_params', obj);
fprintf('包含 %d 个字段 ✓\n', numel(fieldnames(params)));

%% 10. tune - 手动调节
fprintf('10. tune: ');
pid_controller('tune', obj, 'Kp', kp*1.2, 'Ki', ki*0.8, 'Kd', kd*1.5);
kp_new = pid_controller('get_kp', obj);
fprintf('Kp 从 %.4f 调整为 %.4f ✓\n', kp, kp_new);

%% 11. plot - 绘图
fprintf('11. plot: ');
pid_controller('plot', obj);
fprintf('✓ (图窗已弹出)\n');

%% 12. list - 列出对象
fprintf('12. list: ');
count = pid_controller('list');
fprintf('当前对象数 = %d ✓\n', count);

%% 13. destroy - 销毁对象
fprintf('13. destroy: ');
pid_controller('destroy', obj);
count = pid_controller('list');
fprintf('剩余对象数 = %d ✓\n', count);

fprintf('\n========== 所有接口测试通过 ==========\n');