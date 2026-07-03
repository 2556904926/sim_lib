% BUILD_PID_PACKAGE 打包PID控制器为 Python 包
clear; clc;

fprintf('========== 打包 PIDController Python 包 ==========\n\n');

% 检查必要文件
if ~exist('PIDController.m', 'file')
    error('❌ 找不到 PIDController.m');
end
if ~exist('pid_controller.m', 'file')
    error('❌ 找不到 pid_controller.m');
end
fprintf('✓ 必要文件检查通过\n\n');

% 打包参数
package_name = 'pid_controller';
package_version = '1.0.0';
output_dir = './pid_python_package';

fprintf('包名: %s\n', package_name);
fprintf('版本: %s\n', package_version);
fprintf('输出目录: %s\n\n', output_dir);

% 执行打包
fprintf('开始打包...\n');
try
    compiler.package.PythonPackage('pid_controller', ...
        'PackageName', package_name, ...
        'Version', package_version, ...
        'OutputDir', output_dir, ...
        'Verbose', true);
    
    fprintf('\n✅ 打包完成！\n');
    fprintf('生成的文件在: %s\n', fullfile(pwd, output_dir));
    
    files = dir(fullfile(output_dir, '*.whl'));
    if ~isempty(files)
        fprintf('\n安装命令:\n');
        fprintf('  pip install %s\n', fullfile(output_dir, files(1).name));
    end
    
catch ME
    fprintf('\n❌ 打包失败: %s\n', ME.message);
    rethrow(ME);
end