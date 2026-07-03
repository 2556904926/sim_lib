"""
测试 PID 控制器 Python 包
"""

import PidTool
import numpy as np
import matplotlib.pyplot as plt
from scipy import signal

def test_pid_design():
    print("=" * 50)
    print("PID 控制器测试")
    print("=" * 50)
    
    pid = PidTool.initialize()

    # 1. 创建对象
    print("\n1. 创建 PID 控制器对象")
    obj = pid.pid_controller('create', 'design_method', 'ziegler_nichols')
    print(f"   ✓ 对象 ID: {obj}")
    
    # 2. 设置被控对象
    print("\n2. 设置被控对象 (二阶系统)")
    # G(s) = 1 / (s^2 + 0.8s + 1)
    num = [1.0]
    den = [1.0, 0.8, 1.0]
    pid.pid_controller('set_plant', obj, num, den)
    print(f"   ✓ 传递函数: {num} / {den}")
    
    # 3. 执行设计
    print("\n3. 执行 PID 设计")
    pid.pid_controller('design', obj)
    print("   ✓ 设计完成")
    
    # 4. 获取参数
    print("\n4. 获取控制器参数")
    kp = pid.pid_controller('get_kp', obj)
    ki = pid.pid_controller('get_ki', obj)
    kd = pid.pid_controller('get_kd', obj)
    print(f"   ✓ Kp = {kp:.4f}")
    print(f"   ✓ Ki = {ki:.4f}")
    print(f"   ✓ Kd = {kd:.4f}")
    
    # 5. 获取性能指标
    print("\n5. 获取性能指标")
    pm = pid.pid_controller('get_phase_margin', obj)
    gm = pid.pid_controller('get_gain_margin', obj)
    rt = pid.pid_controller('get_rise_time', obj)
    os = pid.pid_controller('get_overshoot', obj)
    st = pid.pid_controller('get_settling_time', obj)
    print(f"   ✓ 相位裕度: {pm:.2f}°")
    print(f"   ✓ 增益裕度: {gm:.2f}")
    print(f"   ✓ 上升时间: {rt:.3f}s")
    print(f"   ✓ 超调量: {os:.2f}%")
    print(f"   ✓ 调节时间: {st:.3f}s")
    
    # 6. 绘图
    print("\n6. 绘制结果 (弹出 MATLAB 图窗)")
    pid.pid_controller('plot', obj)
    print("   ✓ 绘图完成")
    
    # 7. 完整参数
    print("\n7. 获取完整参数")
    params = pid.pid_controller('get_params', obj)
    print(f"   ✓ 包含字段: {list(params.keys())}")
    
    # 8. 销毁
    print("\n8. 销毁对象")
    pid.pid_controller('destroy', obj)
    print("   ✓ 销毁完成")
    
    print("\n" + "=" * 50)
    print("测试完成！")
    print("=" * 50)

if __name__ == "__main__":
    test_pid_design()