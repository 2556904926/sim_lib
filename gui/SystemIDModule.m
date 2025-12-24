classdef SystemIDModule < BaseModule
    % SYSTEMIDMODULE 系统辨识模块
    
    properties
        name = '系统辨识'
        description = '基于输入输出数据的系统辨识'
        
        % 系统辨识器
        identifier
        
        % 绘图坐标轴
        axes_handles
    end
    
    methods
        function obj = SystemIDModule(parent, app_handle)
            % 构造函数
            obj = obj@BaseModule(parent, app_handle);
            obj.identifier = SystemIdentifier();
        end
        
        function createUI(obj)
            % 创建UI
            obj.panel = uipanel('Parent', obj.parent, ...
                'Title', '系统辨识', ...
                'Position', [0, 0, 1, 1], ...
                'BackgroundColor', [0.96, 0.96, 0.96], ...
                'Visible', 'off');
            
            % 创建控制区域
            control_panel = uipanel('Parent', obj.panel, ...
                'Title', '辨识参数', ...
                'Position', [0.01, 0.85, 0.98, 0.14], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            % 辨识参数设置
            y_pos = 30;
            
            % 分子阶次
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '分子阶次:', ...
                'Position', [20, y_pos, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.num_order = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', {'0', '1', '2', '3'}, ...
                'Value', 1, ...
                'Position', [80, y_pos, 60, 25], ...
                'BackgroundColor', 'white');
            
            % 分母阶次
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '分母阶次:', ...
                'Position', [150, y_pos, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.den_order = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', {'1', '2', '3', '4'}, ...
                'Value', 1, ...
                'Position', [210, y_pos, 60, 25], ...
                'BackgroundColor', 'white');
            
            % 辨识方法
            uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '辨识方法:', ...
                'Position', [280, y_pos, 60, 20], ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
            
            obj.controls.method = uicontrol('Parent', control_panel, ...
                'Style', 'popupmenu', ...
                'String', {'传递函数估计', '状态空间估计', '过程模型估计'}, ...
                'Value', 1, ...
                'Position', [340, y_pos, 100, 25], ...
                'BackgroundColor', 'white');
            
            % 数据加载按钮
            obj.controls.load_data = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '加载数据', ...
                'Position', [460, y_pos-5, 80, 30], ...
                'BackgroundColor', [0.3, 0.6, 0.9], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.loadData());
            
            % 辨识按钮
            obj.controls.identify = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '开始辨识', ...
                'Position', [550, y_pos-5, 80, 30], ...
                'BackgroundColor', [0.2, 0.7, 0.3], ...
                'ForegroundColor', 'white', ...
                'FontWeight', 'bold', ...
                'Callback', @(~,~) obj.identifySystem());
            
            % 导出按钮
            obj.controls.export = uicontrol('Parent', control_panel, ...
                'Style', 'pushbutton', ...
                'String', '导出模型', ...
                'Position', [640, y_pos-5, 80, 30], ...
                'BackgroundColor', [0.8, 0.5, 0.2], ...
                'ForegroundColor', 'white', ...
                'Callback', @(~,~) obj.exportModel());
            
            % 结果显示区域
            results_panel = uipanel('Parent', obj.panel, ...
                'Title', '辨识结果', ...
                'Position', [0.01, 0.01, 0.98, 0.83], ...
                'BackgroundColor', 'white');
            
            % 创建绘图坐标轴
            obj.createAxes(results_panel);
            
            % 信息文本
            obj.controls.info_text = uicontrol('Parent', control_panel, ...
                'Style', 'text', ...
                'String', '就绪', ...
                'Position', [730, y_pos, 200, 25], ...
                'HorizontalAlignment', 'left', ...
                'BackgroundColor', [0.92, 0.92, 0.92]);
        end
        
        function createAxes(obj, parent)
            % 创建绘图坐标轴
            obj.axes_handles = gobjects(4, 1);
            
            positions = [
                0.05, 0.55, 0.40, 0.40;  % 左上
                0.55, 0.55, 0.40, 0.40;  % 右上
                0.05, 0.05, 0.40, 0.40;  % 左下
                0.55, 0.05, 0.40, 0.40;  % 右下
            ];
            
            titles = {'时域对比', '阶跃响应', '零极点分布', 'Bode图'};
            
            for i = 1:4
                obj.axes_handles(i) = axes('Parent', parent, ...
                    'Position', positions(i, :), ...
                    'Box', 'on');
                grid(obj.axes_handles(i), 'on');
                title(obj.axes_handles(i), titles{i});
            end
        end
        
        function updateUI(obj)
            % 更新UI
            if ~isempty(obj.data)
                % 如果有数据，可以更新显示
                set(obj.controls.info_text, 'String', ...
                    sprintf('已加载数据: %d 个点', length(obj.data.t)));
            end
        end
        
        function loadData(obj)
            % 加载数据
            [filename, pathname] = uigetfile({'*.mat;*.csv;*.txt', '数据文件'}, ...
                '选择数据文件');
            
            if filename ~= 0
                try
                    fullpath = fullfile(pathname, filename);
                    [~, ~, ext] = fileparts(filename);
                    
                    if strcmpi(ext, '.mat')
                        % MAT文件
                        data = load(fullpath);
                        if isfield(data, 't') && isfield(data, 'u') && isfield(data, 'y')
                            obj.data.t = data.t(:);
                            obj.data.u = data.u(:);
                            obj.data.y = data.y(:);
                        else
                            error('MAT文件必须包含t, u, y变量');
                        end
                    else
                        % CSV/TXT文件
                        data = readmatrix(fullpath);
                        if size(data, 2) >= 3
                            obj.data.t = data(:, 1);
                            obj.data.u = data(:, 2);
                            obj.data.y = data(:, 3);
                        else
                            error('数据文件至少需要3列：时间、输入、输出');
                        end
                    end
                    
                    % 显示原始数据
                    obj.plotRawData();
                    
                    set(obj.controls.info_text, 'String', ...
                        sprintf('数据加载成功: %d 个点', length(obj.data.t)), ...
                        'ForegroundColor', 'green');
                    
                catch ME
                    set(obj.controls.info_text, 'String', ...
                        sprintf('加载失败: %s', ME.message), ...
                        'ForegroundColor', 'red');
                    errordlg(ME.message, '数据加载错误');
                end
            end
        end
        
        function plotRawData(obj)
            % 绘制原始数据
            if isempty(obj.data)
                return;
            end
            
            ax = obj.axes_handles(1);
            cla(ax);
            
            plot(ax, obj.data.t, obj.data.u, 'b-', 'LineWidth', 1.5, ...
                'DisplayName', '输入');
            hold(ax, 'on');
            plot(ax, obj.data.t, obj.data.y, 'r-', 'LineWidth', 1.5, ...
                'DisplayName', '输出');
            hold(ax, 'off');
            
            grid(ax, 'on');
            xlabel(ax, '时间 (s)');
            ylabel(ax, '幅值');
            legend(ax, 'Location', 'best');
            title(ax, '原始数据');
        end
        
        function identifySystem(obj)
            % 执行系统辨识
            if isempty(obj.data)
                set(obj.controls.info_text, 'String', '请先加载数据', ...
                    'ForegroundColor', 'red');
                return;
            end
            
            try
                % 获取参数
                num_order = get(obj.controls.num_order, 'Value') - 1;
                den_order = get(obj.controls.den_order, 'Value');
                method_idx = get(obj.controls.method, 'Value');
                
                methods = {'tfest', 'ssest', 'procest'};
                method = methods{method_idx};
                
                % 配置辨识器
                obj.identifier.num_order = num_order;
                obj.identifier.den_order = den_order;
                obj.identifier.estimation_method = method;
                obj.identifier.Ts = obj.data.t(2) - obj.data.t(1);
                
                % 执行辨识
                set(obj.controls.info_text, 'String', '正在辨识...', ...
                    'ForegroundColor', 'blue');
                set(obj.controls.identify, 'Enable', 'off');
                drawnow;
                
                obj.identifier.process(obj.data.t, obj.data.u, obj.data.y);
                obj.results = obj.identifier.getResults();
                
                % 更新显示
                obj.identifier.plotResults(obj.axes_handles);
                
                % 更新信息
                tf_str = obj.identifier.getTransferFunctionString();
                if startsWith(tf_str, 'G(s) = ')
                    tf_str = tf_str(8:end);
                end

                if length(tf_str) > 30
                    short_tf = [tf_str(1:30) '...'];
                    info_str = sprintf('%s\n         拟合度: %.1f%%', short_tf, obj.results.fitting);
                else
                    info_str = sprintf('%s          拟合度: %.1f%%', tf_str, obj.results.fitting);
                end

                set(obj.controls.info_text, 'String', info_str, 'ForegroundColor', 'black');
                set(obj.controls.identify, 'Enable', 'on');
                
                % 通知应用程序
                if ~isempty(obj.app_handle)
                    obj.app_handle.updateSystemModel(obj.results.sys_tf);
                end
                
            catch ME
                set(obj.controls.info_text, 'String', ...
                    sprintf('辨识失败: %s', ME.message), ...
                    'ForegroundColor', 'red');
                set(obj.controls.identify, 'Enable', 'on');
                errordlg(ME.message, '系统辨识错误');
            end
        end
        
        function exportModel(obj)
            % 导出模型
            if isempty(obj.results)
                errordlg('请先完成系统辨识', '导出错误');
                return;
            end
            
            [filename, pathname] = uiputfile({'*.mat', 'MAT文件'; '*.mdl', 'Simulink模型'}, ...
                '保存模型');
            
            if filename ~= 0
                fullpath = fullfile(pathname, filename);
                [~, ~, ext] = fileparts(filename);
                
                if strcmpi(ext, '.mat')
                    % 保存为MAT文件
                    sys_id_results = obj.results;
                    save(fullpath, 'sys_id_results');
                    
                    % 同时保存到工作空间
                    assignin('base', 'identified_system', obj.results.sys_tf);
                    assignin('base', 'sys_id_results', obj.results);
                    
                    msgbox(sprintf('模型已导出到:\n%s\n并保存到工作空间', fullpath), '导出成功');
                    
                elseif strcmpi(ext, '.mdl')
                    try
                        % 创建简单模型
                        model_name = 'exported_system';
                        new_system(model_name);
                        open_system(model_name);
                        
                        % 添加传递函数块
                        add_block('simulink/Continuous/Transfer Fcn', ...
                            [model_name, '/System'], ...
                            'Position', [100, 100, 200, 150]);
                        
                        % 设置参数
                        [num, den] = tfdata(obj.results.sys_tf, 'v');
                        num_str = mat2str(num);
                        den_str = mat2str(den);
                        set_param([model_name, '/System'], ...
                            'Numerator', num_str, ...
                            'Denominator', den_str);
                        
                        % 添加输入输出
                        add_block('simulink/Sources/Step', [model_name, '/Step']);
                        add_block('simulink/Sinks/Scope', [model_name, '/Scope']);
                        
                        % 连接模块
                        add_line(model_name, 'Step/1', 'System/1');
                        add_line(model_name, 'System/1', 'Scope/1');
                        
                        % 保存模型
                        save_system(model_name, fullpath);
                        close_system(model_name);
                        
                        msgbox(sprintf('Simulink模型已创建:\n%s', fullpath), '导出成功');
                        
                    catch ME
                        errordlg(sprintf('Simulink模型导出失败:\n%s', ME.message), '导出错误');
                    end
                end
            end
        end
        
        function process(obj)
            % 处理数据
            obj.identifySystem();
        end
    end
end