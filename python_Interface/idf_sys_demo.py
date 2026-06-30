import system_identifier as si
import numpy as np

# 创建对象
obj = si.identify_system('create', 0, 2, 0.01)

# 准备数据
t = np.linspace(0, 10, 1000)
u = np.sin(t)
y = 1.5 * np.sin(t - 0.2) + 0.05 * np.random.randn(1000)

# 执行辨识
si.identify_system('process', obj, t.tolist(), u.tolist(), y.tolist())

# 获取结果
print(f"拟合度: {si.identify_system('get_fitting', obj):.2f}%")
print(f"传递函数: {si.identify_system('get_tf', obj)}")

# 绘图
si.identify_system('plot', obj)

# 销毁
si.identify_system('destroy', obj)