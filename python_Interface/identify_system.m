function varargout = identify_system(cmd, varargin)
% IDENTIFY_SYSTEM 系统辨识器 Python 接口
% 
% Python 调用示例:
%   import identify_system as idsys
%   
%   obj = idsys.identify_system('create', num_order, den_order, Ts)
%   idsys.identify_system('process', obj, t, u, y)
%   results = idsys.identify_system('get_results', obj)
%   fit = idsys.identify_system('get_fitting', obj)
%   idsys.identify_system('plot', obj)
%   idsys.identify_system('destroy', obj)

persistent objects;

switch cmd
    case 'create'
        % 创建辨识器
        % 参数: num_order, den_order, Ts (可选)
        if nargin < 4
            num_order = 0;
            den_order = 2;
            Ts = 0.01;
        else
            num_order = varargin{1};
            den_order = varargin{2};
            if nargin >= 4
                Ts = varargin{3};
            else
                Ts = 0.01;
            end
        end
        
        obj = SystemIdentifier('num_order', num_order, 'den_order', den_order, 'Ts', Ts);
        obj.initialize();
        
        if isempty(objects)
            objects = {};
        end
        obj_id = length(objects) + 1;
        objects{obj_id} = obj;
        varargout{1} = obj_id;
        
    case 'process'
        % 执行辨识: process(obj_id, t, u, y)
        obj_id = varargin{1};
        t = varargin{2};
        u = varargin{3};
        y = varargin{4};
        
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.process(t, u, y);
        end
        
    case 'get_results'
        % 获取完整结果
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            results = objects{obj_id}.getResults();
            varargout{1} = results;
        else
            varargout{1} = struct('fitting', 0);
        end
        
    case 'get_fitting'
        % 获取拟合度
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.fitting_percent;
        else
            varargout{1} = 0;
        end
        
    case 'get_tf'
        % 获取传递函数字符串
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.getTransferFunctionString();
        else
            varargout{1} = '';
        end
        
    case 'get_num_den'
        % 获取分子分母系数
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            [num, den] = tfdata(objects{obj_id}.sys_est, 'v');
            varargout{1} = num;
            varargout{2} = den;
        else
            varargout{1} = [];
            varargout{2} = [];
        end
        
    case 'get_metrics'
        % 获取验证指标
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.validation_metrics;
        else
            varargout{1} = struct('mse', 0, 'rmse', 0, 'mae', 0);
        end
        
    case 'get_poles_zeros'
        % 获取零极点
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = pole(objects{obj_id}.sys_est);
            varargout{2} = zero(objects{obj_id}.sys_est);
        else
            varargout{1} = [];
            varargout{2} = [];
        end
        
    case 'plot'
        % 绘图
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.plotResults();
        end
        
    case 'destroy'
        % 销毁对象
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id} = [];
        end
        
    case 'list'
        % 列出所有对象
        varargout{1} = length(objects);
        
    otherwise
        error('未知命令: %s。可用命令: create, process, get_results, get_fitting, get_tf, get_num_den, get_metrics, get_poles_zeros, plot, destroy, list', cmd);
end
end