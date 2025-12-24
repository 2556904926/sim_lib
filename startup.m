%% startup.m - 系统辨识与控制器设计平台启动脚本
function startup()
    % 系统辨识与控制器设计平台
    % 启动主应用程序
    
    % 获取当前文件所在目录
    toolbox_root = fileparts(mfilename('fullpath'));
    
    fprintf('========================================\n');
    fprintf('  系统辨识与控制器设计平台 v1.0\n');
    fprintf('========================================\n\n');
    
    % 添加所有必要的路径
    addpath(toolbox_root);
    addpath(fullfile(toolbox_root, 'core'));
    addpath(fullfile(toolbox_root, 'gui'));
    addpath(fullfile(toolbox_root, 'core', 'controllers'));
    addpath(fullfile(toolbox_root, 'examples'));
    
    fprintf('工具箱路径已添加:\n');
    fprintf('  %s\n', toolbox_root);
    
    % 检查工具箱依赖
    fprintf('\n检查工具箱依赖...\n');
    check_dependencies();
    
    % 显示欢迎信息
    fprintf('\n欢迎使用系统辨识与控制器设计平台！\n');
    fprintf('主要功能:\n');
    fprintf('  1. 系统辨识 - 基于输入输出数据辨识系统模型\n');
    fprintf('  2. PID设计 - 多种PID整定方法\n');
    fprintf('  3. 控制器设计 - 支持多种控制器类型\n');
    fprintf('  4. 仿真验证 - 验证控制器性能\n\n');
    
    fprintf('使用方法:\n');
    fprintf('  1. 运行 main_app() 启动GUI界面\n');
    fprintf('  2. 或直接使用核心类进行编程\n');
    fprintf('  3. 运行 help_demo() 查看示例\n\n');
    
    fprintf('工具箱已成功初始化！\n');
end

function check_dependencies()
    % 检查必要的工具箱
    required_toolboxes = {
        'Control System Toolbox', 'control';
        'System Identification Toolbox', 'ident';
        'Signal Processing Toolbox', 'signal'
    };
    
    for i = 1:size(required_toolboxes, 1)
        toolbox_name = required_toolboxes{i, 1};
        toolbox_id = required_toolboxes{i, 2};
        
        if license('test', toolbox_id) && ~isempty(ver(toolbox_id))
            fprintf('  ✓ %s\n', toolbox_name);
        else
            fprintf('  ✗ %s (可能需要单独安装)\n', toolbox_name);
            warning('%s 可能未安装或未授权', toolbox_name);
        end
    end
end