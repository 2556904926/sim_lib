# PID Controller MATLAB 函数使用文档

## 命令列表

### 1. 创建控制器 - `'create'`
创建新的 PID 控制器对象。

**语法：**
```matlab
obj_id = pid_controller('create', 'design_method', method_name)
```

**参数：**
- `'design_method'`: 设计方法（可选），支持的值：
  - `'ziegler_nichols'` - Ziegler-Nichols 整定方法
  - `'cohen_coon'` - Cohen-Coon 整定方法
  - `'imc'` - 内模控制(IMC)方法
  - `'itae'` - ITAE 最优整定
  - `'manual'` - 手动调节
  - `'timedesign'` - 时域设计
  - `'frequency'` - 频域设计

**返回值：**
- `obj_id`: 控制器对象 ID（整数），用于后续操作

**示例：**
```matlab
obj = pid_controller('create', 'design_method', 'ziegler_nichols');
```

---

### 2. 设置被控对象 - `'set_plant'`
设置控制器的被控对象传递函数。

**语法：**
```matlab
pid_controller('set_plant', obj_id, num, den)
```

**参数：**
- `obj_id`: 控制器对象 ID
- `num`: 传递函数分子系数数组
- `den`: 传递函数分母系数数组

**示例：**
```matlab
pid_controller('set_plant', obj, [1], [1, 3, 2]);
% 传递函数 G(s) = 1/(s^2 + 3s + 2)
```

---

# 3. 设置设计参数 - `set_params`

在调用 `design` 之前必须调用此命令，用于传递设计方法和相关参数。

## 语法

```matlab
pid_controller('set_params', obj_id, 'design_method', method_name, param1, val1, ...)
% 或直接手动设定 PID 参数
pid_controller('set_params', obj_id, 'Kp', Kp, 'Ki', Ki, 'Kd', Kd)
```

## 通用参数表

| 参数名 | 类型 | 说明 | 适用方法 |
|---|---:|---|---|
| `design_method` | 字符串 | 设计方法名称 | 所有 |
| `controller_type` | 字符串 | `'P'` / `'PI'` / `'PID'` | `ziegler_nichols`, `cohen_coon` |
| `Kp`, `Ki`, `Kd` | 数值 | 比例、积分、微分增益 | `manual` |
| `Ti`, `Td` | 数值 | 积分、微分时间常数 | `manual` |
| `reference_value` | 数值 | 阶跃响应参考值 | 所有 |
| `target_pm` | 数值 | 目标相位裕度（度） | `frequency` |
| `target_rise_time` | 数值 | 目标上升时间（秒） | `timedesign` |
| `target_overshoot` | 数值 | 目标超调量（%） | `timedesign` |
| `lambda` | 数值 | IMC 滤波器时间常数 | `imc` |

## 各方法专用参数说明

| 设计方法 | 必需参数 | 可选参数 | 默认值 |
|---|---|---|---|
| `ziegler_nichols` | `controller_type` | — | `PID` |
| `cohen_coon` | `controller_type` | — | `PID` |
| `imc` | — | `lambda` | `max(0.1*tau, L)` |
| `itae` | — | — | — |
| `manual` | `Kp`, `Ki`, `Kd` | `Ti`, `Td` | — |
| `timedesign` | — | `target_rise_time`, `target_overshoot` | `overshoot = 0` |
| `frequency` | — | `target_pm` | `60°`
---

### 4. 设计控制器 - `'design'`
根据设定的设计方法自动整定 PID 参数。

**语法：**
```matlab
pid_controller('design', obj_id)
```

**示例：**
```matlab
pid_controller('design', obj);
```

---

### 5. 获取 PID 参数 - `'get_params'`
获取当前 PID 控制器的所有参数。

**语法：**
```matlab
params = pid_controller('get_params', obj_id)
```

**返回值：**
- `params`: 包含 Kp、Ki、Kd 的结构体

**示例：**
```matlab
params = pid_controller('get_params', obj);
disp(params.Kp);
```

---

### 6. 获取比例增益 - `'get_kp'`
获取当前比例增益 Kp。

**语法：**
```matlab
Kp = pid_controller('get_kp', obj_id)
```

---

### 7. 获取积分增益 - `'get_ki'`
获取当前积分增益 Ki。

**语法：**
```matlab
Ki = pid_controller('get_ki', obj_id)
```

---

### 8. 获取微分增益 - `'get_kd'`
获取当前微分增益 Kd。

**语法：**
```matlab
Kd = pid_controller('get_kd', obj_id)
```

---

### 9. 获取性能指标 - `'get_performance'`
获取控制器的性能指标。

**语法：**
```matlab
perf = pid_controller('get_performance', obj_id)
```

**返回值：**
- `perf`: 包含各项性能指标的结构体

---

### 10. 获取相位裕度 - `'get_phase_margin'`
获取当前控制系统的相位裕度。

**语法：**
```matlab
pm = pid_controller('get_phase_margin', obj_id)
```

---

### 11. 获取幅值裕度 - `'get_gain_margin'`
获取当前控制系统的幅值裕度。

**语法：**
```matlab
gm = pid_controller('get_gain_margin', obj_id)
```

---

### 12. 获取上升时间 - `'get_rise_time'`
获取闭环系统的上升时间。

**语法：**
```matlab
rt = pid_controller('get_rise_time', obj_id)
```

---

### 13. 获取超调量 - `'get_overshoot'`
获取闭环系统的超调量。

**语法：**
```matlab
os = pid_controller('get_overshoot', obj_id)
```

---

### 14. 获取调节时间 - `'get_settling_time'`
获取闭环系统的调节时间。

**语法：**
```matlab
st = pid_controller('get_settling_time', obj_id)
```

---

### 15. 调参 - `'tune'`
对 PID 参数进行微调。

**语法：**
```matlab
pid_controller('tune', obj_id, 'param', value, ...)
```

**参数：**
- `'Kp'`: 比例增益调整值
- `'Ki'`: 积分增益调整值
- `'Kd'`: 微分增益调整值

**示例：**
```matlab
pid_controller('tune', obj, 'Kp', 1.2, 'Ki', 0.6);
```

---

### 16. 绘图 - `'plot'`
绘制控制系统的响应曲线和性能分析图。

**语法：**
```matlab
pid_controller('plot', obj_id)
```

**示例：**
```matlab
pid_controller('plot', obj);
```

---

### 17. 列出对象 - `'list'`
获取当前存在的控制器对象数量。

**语法：**
```matlab
count = pid_controller('list')
```

**返回值：**
- `count`: 控制器对象总数

---

### 18. 销毁对象 - `'destroy'`
删除指定的控制器对象，释放内存。

**语法：**
```matlab
pid_controller('destroy', obj_id)
```

**示例：**
```matlab
pid_controller('destroy', obj);
```

---

## 完整使用示例

```matlab
% 1. 创建 PID 控制器对象
obj = pid_controller('create', 'design_method', 'ziegler_nichols');

% 2. 设置被控对象
pid_controller('set_plant', obj, [1], [1, 3, 2]);

% 3. 自动设计 PID 参数
pid_controller('design', obj);

% 4. 获取设计结果
params = pid_controller('get_params', obj);
fprintf('Kp = %.4f, Ki = %.4f, Kd = %.4f\n', params.Kp, params.Ki, params.Kd);

% 5. 获取性能指标
pm = pid_controller('get_phase_margin', obj);
gm = pid_controller('get_gain_margin', obj);
fprintf('Phase Margin = %.2f°, Gain Margin = %.2f dB\n', pm, gm);

% 6. 绘制响应曲线
pid_controller('plot', obj);

% 7. 微调参数
pid_controller('tune', obj, 'Kp', 1.5);

% 8. 销毁对象
pid_controller('destroy', obj);
```

---

## Python 调用示例

```python
import pid_controller as pid

# 创建对象
obj = pid.pid_controller('create', 'design_method', 'ziegler_nichols')

# 设置被控对象
pid.pid_controller('set_plant', obj, [1], [1, 3, 2])

# 设置 PID 参数
pid.pid_controller('set_params', obj, 'Kp', 1.0, 'Ki', 0.5, 'Kd', 0.1)

# 设计控制器
pid.pid_controller('design', obj)

# 获取参数
params = pid.pid_controller('get_params', obj)

# 绘制结果
pid.pid_controller('plot', obj)

# 销毁对象
pid.pid_controller('destroy', obj)
```

---

## 错误处理
当使用未知命令时，函数会返回错误信息，列出所有可用命令：
```
未知命令: xxx。可用命令: create, set_plant, set_params, design, get_params, get_kp, get_ki, get_kd, get_performance, get_phase_margin, get_gain_margin, get_rise_time, get_overshoot, get_settling_time, tune, plot, list, destroy
```

---

## 注意事项
1. 必须先使用 `'create'` 创建对象，获取 `obj_id` 后才能进行其他操作
2. 使用 `'design'` 前需要先通过 `'set_plant'` 设置被控对象
3. 对象使用完毕后建议调用 `'destroy'` 释放内存
4. `'plot'` 命令会创建新的 MATLAB 图形窗口