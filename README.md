system_toolkit/
├── core/                    # 核心算法库
│   ├── BaseSystem.m        # 系统基类
│   ├── SystemIdentifier.m  # 系统辨识类
│   ├── controllers/        # 控制器库
│   │   ├── BaseController.m
│   │   ├── PIDController.m
│   │   ├── FuzzyController.m
│   │   └── MPCController.m
│   └── utils/              # 工具函数
├── gui/                    # GUI界面
│   ├── BaseModule.m        # 模块基类
│   ├── SystemIDModule.m    # 辨识模块
│   ├── ControllerModule.m  # 控制器模块
│   ├── MainApp.m          # 主应用程序
│   └── NavigationPanel.m   # 导航面板
├── python_bridge/          # Python接口
└── examples/