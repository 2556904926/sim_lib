%% system_toolkit.m - 主函数文件（与文件夹同名）
function system_toolkit()

    startup();
    
    % 解析输入参数
    if nargin == 0
        % 默认启动GUI
        main_app();
    end
end

function main_app()
    % 启动主应用程序
    fprintf('\n正在启动系统辨识与控制器设计平台...\n');
    
    try
        % 创建应用程序实例
        app = MainApp();
        app.run();
        
        fprintf('\n应用程序已关闭。\n');
        
    catch ME
        fprintf('\n应用程序启动失败:\n');
        fprintf('  错误: %s\n', ME.message);
        
        % 显示详细错误信息
        fprintf('\n详细信息:\n');
        for i = 1:length(ME.stack)
            fprintf('  %s (%d)\n', ME.stack(i).name, ME.stack(i).line);
        end
        
        errordlg(sprintf('应用程序启动失败:\n%s', ME.message), '启动错误');
    end
end