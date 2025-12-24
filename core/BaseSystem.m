classdef BaseSystem < handle
    % BASESYSTEM 系统基类
    % 定义系统的基本接口
    
    properties (Abstract)
        name        % 系统名称
        description % 系统描述
    end
    
    properties
        Ts = 0.01   % 采样时间
        data        % 数据容器
        results     % 结果容器
    end
    
    methods (Abstract)
        initialize(obj)     % 初始化
        process(obj)        % 处理数据
        validate(obj)       % 验证结果
        getResults(obj)     % 获取结果
    end
    
    methods
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
        
        function exportResults(obj, filename)
            % 导出结果
            results = obj.getResults();
            save(filename, 'results');
            fprintf('结果已导出到: %s\n', filename);
        end
    end
end