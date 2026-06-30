"""
identify_system Python 包完整测试
"""

import identify_system
import numpy as np
import matplotlib.pyplot as plt


def test_all_interfaces():
    """测试所有接口"""
    
    print('='*60)
    print('identify_system 完整接口测试')
    print('='*60)
    print()
    
    # 初始化
    print('【初始化】')
    obj = identify_system.initialize()
    print('✓ MATLAB Runtime 初始化成功')
    print()
    
    # 1. 测试 create
    print('【1. create - 创建辨识器】')
    obj_id = obj.identify_system('create', 0, 2, 0.01)
    obj_id_int = int(obj_id)
    print(f'  对象 ID: {obj_id_int}')
    print('✓ create 测试通过')
    print()
    
    # 准备测试数据
    print('【准备测试数据】')
    t = np.arange(0, 10.01, 0.01)
    u = np.sin(t)
    y = 1.5 * np.sin(t - 0.2) + 0.05 * np.random.randn(len(t))
    print(f'  数据点数: {len(t)}')
    print('✓ 数据准备完成')
    print()
    
    # 2. 测试 process
    print('【2. process - 执行辨识】')
    obj.identify_system('process', obj_id, t, u, y)
    print('✓ process 测试通过')
    print()
    
    # 3. 测试 get_fitting
    print('【3. get_fitting - 获取拟合度】')
    fitting = obj.identify_system('get_fitting', obj_id)
    print(f'  拟合度: {float(fitting):.2f}%')
    print('✓ get_fitting 测试通过')
    print()
    
    # 4. 测试 get_tf
    print('【4. get_tf - 获取传递函数字符串】')
    tf_str = obj.identify_system('get_tf', obj_id)
    print(f'  传递函数: {tf_str}')
    print('✓ get_tf 测试通过')
    print()
    
    # 5. 测试 get_num_den
    print('【5. get_num_den - 获取分子分母系数】')
    num, den = obj.identify_system('get_num_den', obj_id,nargout=2)
    print(f'  分子系数: {num}')
    print(f'  分母系数: {den}')
    print('✓ get_num_den 测试通过')
    print()
    
    # 6. 测试 get_metrics
    print('【6. get_metrics - 获取验证指标】')
    metrics = obj.identify_system('get_metrics', obj_id)
    print(f'  MSE:  {metrics["mse"]:.6f}')
    print(f'  RMSE: {metrics["rmse"]:.6f}')
    print(f'  MAE:  {metrics["mae"]:.6f}')
    print('✓ get_metrics 测试通过')
    print()
    
    # 7. 测试 get_poles_zeros
    print('【7. get_poles_zeros - 获取零极点】')
    poles, zeros = obj.identify_system('get_poles_zeros', obj_id)
    print(f'  极点: {poles}')
    print(f'  零点: {zeros}')
    print('✓ get_poles_zeros 测试通过')
    print()
    
    # 8. 测试 get_results
    print('【8. get_results - 获取完整结果】')
    results = obj.identify_system('get_results', obj_id)
    print(f'  结果字段数: {len(results)}')
    for key, value in results.items():
        if isinstance(value, (int, float, str)):
            print(f'    {key}: {value}')
        elif isinstance(value, np.ndarray):
            print(f'    {key}: array, shape={value.shape}')
    print('✓ get_results 测试通过')
    print()
    
    # 9. 测试 list
    print('【9. list - 列出对象数量】')
    count = obj.identify_system('list')
    print(f'  当前对象数量: {int(count)}')
    print('✓ list 测试通过')
    print()
    
    # 10. 测试 plot
    print('【10. plot - 绘图】')
    obj.identify_system('plot', obj_id)
    print('  ✓ 绘图窗口已弹出')
    print('✓ plot 测试通过')
    print()
    
    # # 11. 测试 destroy
    # print('【11. destroy - 销毁对象】')
    # obj.identify_system('destroy', obj_id)
    # count = obj.identify_system('list')
    # print(f'  剩余对象数量: {int(count)}')
    # print('✓ destroy 测试通过')
    # print()

    
    print('='*60)
    print('✅ 所有接口测试完成！')
    print('='*60)
    
    # 保持图形窗口
    plt.show(block=True)


if __name__ == '__main__':
    test_all_interfaces()