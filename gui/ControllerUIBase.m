classdef ControllerUIBase < handle
    % CONTROLLERUIBASE 控制器UI基类
    % 定义控制器UI的基本接口
    
    properties (Abstract)
        name                % UI名称
        description         % UI描述
        controller_type     % 对应的控制器类型
    end
    
    properties
        parent_panel        % 父面板
        controls            % UI控件
        controller          % 控制器对象
        app_handle          % 应用程序句柄
    end
    
    methods (Abstract)
        createUI(obj)       % 创建UI
        designController(obj) % 设计控制器
    end
    
    methods
        function obj = ControllerUIBase(parent_panel, app_handle)
            % 构造函数
            obj.parent_panel = parent_panel;
            obj.app_handle = app_handle;
            obj.controls = struct();
        end
        
        function updateUI(obj)
            % 默认的UI更新方法 - 子类可以重写添加特定逻辑
            % 系统模型信息由 ControllerModule.updateInfo() 处理
        end
        
        function setController(obj, controller)
            % 设置控制器对象
            obj.controller = controller;
        end
        
        function show(obj)
            % 显示UI
            if isfield(obj.controls, 'panel') && ~isempty(obj.controls.panel)
                set(obj.controls.panel, 'Visible', 'on');
            end
        end
        
        function hide(obj)
            % 隐藏UI
            if isfield(obj.controls, 'panel') && ~isempty(obj.controls.panel)
                set(obj.controls.panel, 'Visible', 'off');
            end
        end
        
        function simulateControl(obj)
            % 仿真控制系统
            if isempty(obj.controller) || isempty(obj.controller.plant_model)
                errordlg('请先设置系统模型', '错误');
                return;
            end
            
            try
                % 执行仿真
                obj.controller.simulate();
                
                % 绘制结果
                obj.plotResults();
                
                msgbox('仿真完成', '成功');
            catch ME
                errordlg(['仿真失败: ', ME.message], '错误');
            end
        end
        
        function plotResults(obj)
            % 绘制仿真结果
            if isempty(obj.controller) || isempty(obj.controller.simulation_results)
                return;
            end
            
            results = obj.controller.simulation_results;
            
            % 清除之前的绘图
            if isfield(obj.controls, 'axes_handles')
                axes_handles = obj.controls.axes_handles;
                if iscell(axes_handles)
                    for i = 1:numel(axes_handles)
                        if ishandle(axes_handles{i})
                            cla(axes_handles{i});
                        end
                    end
                else
                    for i = 1:length(axes_handles)
                        if ishandle(axes_handles(i))
                            cla(axes_handles(i));
                        end
                    end
                end
            end
            
            % 绘制响应曲线
            if isfield(results, 'time') && isfield(results, 'output')
                subplot(2,2,1);
                plot(results.time, results.output, 'b-', 'LineWidth', 2);
                hold on;
                if isfield(results, 'reference')
                    plot(results.time, results.reference, 'r--', 'LineWidth', 1.5);
                end
                hold off;
                title('系统输出响应');
                xlabel('时间 (s)');
                ylabel('输出');
                legend('输出', '参考输入');
                grid on;
            end
            
            % 绘制控制信号
            if isfield(results, 'control_signal')
                subplot(2,2,2);
                plot(results.time, results.control_signal, 'g-', 'LineWidth', 2);
                title('控制信号');
                xlabel('时间 (s)');
                ylabel('控制信号');
                grid on;
            end
            
            % 绘制误差
            if isfield(results, 'error')
                subplot(2,2,3);
                plot(results.time, results.error, 'r-', 'LineWidth', 2);
                title('跟踪误差');
                xlabel('时间 (s)');
                ylabel('误差');
                grid on;
            end
            
            % 性能指标
            if isfield(obj.controller, 'performance') && ~isempty(obj.controller.performance)
                perf = obj.controller.performance;
                subplot(2,2,4);
                axis off;
                
                text(0.1, 0.9, '性能指标:', 'FontWeight', 'bold');
                if isfield(perf, 'rise_time')
                    text(0.1, 0.8, sprintf('上升时间: %.3f s', perf.rise_time));
                end
                if isfield(perf, 'settling_time')
                    text(0.1, 0.7, sprintf('调节时间: %.3f s', perf.settling_time));
                end
                if isfield(perf, 'overshoot')
                    text(0.1, 0.6, sprintf('超调量: %.1f %%', perf.overshoot));
                end
                if isfield(perf, 'steady_error')
                    text(0.1, 0.5, sprintf('稳态误差: %.4f', perf.steady_error));
                end
                if isfield(perf, 'iae')
                    text(0.1, 0.4, sprintf('IAE: %.4f', perf.iae));
                end
                if isfield(perf, 'ise')
                    text(0.1, 0.3, sprintf('ISE: %.4f', perf.ise));
                end
            end
        end
        
        function exportController(obj)
            % 导出控制器
            if isempty(obj.controller)
                errordlg('没有控制器可导出', '错误');
                return;
            end
            
            [filename, pathname] = uiputfile('*.mat', '保存控制器');
            if isequal(filename, 0)
                return;
            end
            
            try
                controller_data = struct();
                controller_data.controller = obj.controller;
                controller_data.type = obj.controller_type;
                controller_data.design_params = obj.controller.design_params;
                controller_data.performance = obj.controller.performance;
                
                save(fullfile(pathname, filename), 'controller_data');
                msgbox('控制器导出成功', '成功');
            catch ME
                errordlg(['导出失败: ', ME.message], '错误');
            end
        end
    end
end