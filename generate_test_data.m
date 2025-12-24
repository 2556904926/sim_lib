%% 运行这一整段代码就能生成 test_signal.mat
clear; clc;

% 生成数据
t = (0:0.001:10)';
u = zeros(size(t));
u(t >= 1.0) = 1.0;
u(t >= 5.0) = 0.5;

sys = tf(3, [1, 1]);
y_clean = lsim(sys, u, t);
y = y_clean + 0.02 * randn(size(y_clean));

% 保存文件
save('test_signal.mat', 't', 'u', 'y');

% 预览数据
figure('Name', '测试数据预览', 'Position', [100,100,800,300]);
subplot(1,2,1); plot(t,u,'b-','LineWidth',2); grid on; title('输入 u(t)'); xlabel('时间(s)');
subplot(1,2,2); plot(t,y,'r-','LineWidth',2); grid on; title('输出 y(t)'); xlabel('时间(s)');