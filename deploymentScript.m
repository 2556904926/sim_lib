projectRoot = "E:\matlab\simulate_module(1)\simulate_module\matlab_lib\toolkit\system_toolkit";

% 创建目标编译选项对象，设置编译属性并进行编译。
buildOpts = compiler.build.PythonPackageOptions([fullfile(projectRoot, "cyg_add.m"), fullfile(projectRoot, "generate_test_data.m"), fullfile(projectRoot, "system_toolkit.m")]);
buildOpts.AutoDetectDataFiles = true;
buildOpts.OutputDir = fullfile(projectRoot, "PythonPackage1", "output", "build");
buildOpts.ObfuscateArchive = false;
buildOpts.Verbose = true;
buildOpts.PackageName = "My Python Package";
buildResult = compiler.build.pythonPackage(buildOpts);


% 创建包选项对象，设置包属性并进行打包。
packageOpts = compiler.package.InstallerOptions(buildResult);
packageOpts.ApplicationName = "My Python Package";
packageOpts.AuthorName = "lao zhou";
packageOpts.OutputDir = fullfile(projectRoot, "PythonPackage1", "output", "package");
packageOpts.Verbose = true;
compiler.package.installer(buildResult, "Options", packageOpts);