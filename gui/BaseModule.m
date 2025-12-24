classdef BaseModule < handle
    % BASEMODULE GUI模块基类
    
    properties (Abstract)
        name                % 模块名称
        description         % 模块描述
    end
    
    properties
        parent              % 父容器
        panel               % 模块面板
        controls            % 控件容器
        data                % 数据
        results             % 结果
        app_handle          % 应用程序句柄
    end
    
    methods (Abstract)
        createUI(obj)       % 创建UI
        updateUI(obj)       % 更新UI
        process(obj)        % 处理数据
    end
    
    methods
        function obj = BaseModule(parent, app_handle)
            % 构造函数
            obj.parent = parent;
            obj.app_handle = app_handle;
            obj.controls = struct();
            obj.createUI();
        end
        
        function show(obj)
            % 显示模块
            set(obj.panel, 'Visible', 'on');
        end
        
        function hide(obj)
            % 隐藏模块
            set(obj.panel, 'Visible', 'off');
        end
        
        function enableControls(obj, state)
            % 启用/禁用控件
            fields = fieldnames(obj.controls);
            for i = 1:length(fields)
                if ishandle(obj.controls.(fields{i}))
                    set(obj.controls.(fields{i}), 'Enable', state);
                end
            end
        end
        
        function setData(obj, data)
            % 设置数据
            obj.data = data;
            obj.updateUI();
        end
        
        function plotResults(obj, ax)
            % 绘制结果（可重写）
            if nargin < 2
                figure;
                ax = gca;
            end
            cla(ax);
            text(ax, 0.5, 0.5, '未实现绘图功能', ...
                'HorizontalAlignment', 'center');
            axis(ax, 'off');
        end
    end
end