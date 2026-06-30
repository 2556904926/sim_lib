%% 测试 identify_system 所有接口
clear; clc; close all;

fprintf('========== 测试 identify_system 接口 ==========\n\n');

%% 1. create - 创建对象
fprintf('1. create: ');
obj = identify_system('create', 0, 2, 0.01);
fprintf('obj_id = %d ✓\n', obj);

%% 2. 准备数据
t = (0:0.01:10)';
u = sin(t);
sys_true = tf(1.5, [1, 0.8, 1]);
y = lsim(sys_true, u, t) + 0.05 * randn(size(t));

%% 3. process - 执行辨识
fprintf('2. process: ');
identify_system('process', obj, t, u, y);
fprintf('✓\n');

%% 4. get_fitting - 获取拟合度
fprintf('3. get_fitting: ');
fit = identify_system('get_fitting', obj);
fprintf('%.2f%% ✓\n', fit);

%% 5. get_tf - 获取传递函数字符串
fprintf('4. get_tf: ');
tf_str = identify_system('get_tf', obj);
fprintf('%s ✓\n', tf_str);

%% 6. get_num_den - 获取分子分母
fprintf('5. get_num_den: ');
[num, den] = identify_system('get_num_den', obj);
fprintf('num=[%s], den=[%s] ✓\n', num2str(num), num2str(den));

%% 7. get_metrics - 获取验证指标
fprintf('6. get_metrics: ');
metrics = identify_system('get_metrics', obj);
fprintf('MSE=%.4f, RMSE=%.4f, MAE=%.4f ✓\n', metrics.mse, metrics.rmse, metrics.mae);

%% 8. get_poles_zeros - 获取零极点
fprintf('7. get_poles_zeros: ');
[poles, zeros] = identify_system('get_poles_zeros', obj);
fprintf('poles=%s, zeros=%s ✓\n', mat2str(poles,3), mat2str(zeros,3));

%% 9. get_results - 获取完整结果
fprintf('8. get_results: ');
results = identify_system('get_results', obj);
fprintf('包含 %d 个字段 ✓\n', numel(fieldnames(results)));

%% 10. plot - 绘图
fprintf('9. plot: ');
identify_system('plot', obj);
fprintf('✓ (图窗已弹出)\n');

%% 11. list - 列出对象
fprintf('10. list: ');
count = identify_system('list');
fprintf('当前对象数 = %d ✓\n', count);

%% 12. destroy - 销毁对象
fprintf('11. destroy: ');
identify_system('destroy', obj);
count = identify_system('list');
fprintf('剩余对象数 = %d ✓\n', count);

fprintf('\n========== 所有接口测试完成 ==========\n');