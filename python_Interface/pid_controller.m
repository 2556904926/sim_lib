function varargout = pid_controller(cmd, varargin)
% PID_CONTROLLER PID控制器 Python 接口
%
% Python 调用示例:
%   import pid_controller as pid
%
%   obj = pid.pid_controller('create', 'design_method', 'ziegler_nichols')
%   pid.pid_controller('set_plant', obj, num, den)
%   pid.pid_controller('set_params', obj, 'Kp', 1.0, 'Ki', 0.5, 'Kd', 0.1)
%   pid.pid_controller('design', obj)
%   params = pid.pid_controller('get_params', obj)
%   pid.pid_controller('plot', obj)
%   pid.pid_controller('destroy', obj)

persistent objects;

switch cmd
    case 'create'
        % 创建PID控制器对象
        obj = PIDController();
        
        params = struct();
        for i = 1:2:length(varargin)
            params.(varargin{i}) = varargin{i+1};
        end
        obj.setDesignParams(params);
        
        if isempty(objects)
            objects = {};
        end
        obj_id = length(objects) + 1;
        objects{obj_id} = obj;
        varargout{1} = obj_id;
        
    case 'set_plant'
        obj_id = varargin{1};
        num = varargin{2};
        den = varargin{3};
        
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.plant_model = tf(num, den);
        end
        varargout{1} = [];  % 返回空
        
    case 'set_params'
        obj_id = varargin{1};
        params = struct();
        for i = 2:2:length(varargin)
            params.(varargin{i}) = varargin{i+1};
        end
        
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.setDesignParams(params);
        end
        varargout{1} = [];  % 返回空
        
    case 'design'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.design();
        end
        varargout{1} = [];  % 返回空
        
    case 'get_params'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            params = objects{obj_id}.getParameters();
            varargout{1} = params;
        else
            varargout{1} = struct();
        end
        
    case 'get_kp'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.Kp;
        else
            varargout{1} = 0;
        end
        
    case 'get_ki'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.Ki;
        else
            varargout{1} = 0;
        end
        
    case 'get_kd'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.Kd;
        else
            varargout{1} = 0;
        end
        
    case 'get_performance'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.performance;
        else
            varargout{1} = struct();
        end
        
    case 'get_phase_margin'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.phase_margin;
        else
            varargout{1} = 0;
        end
        
    case 'get_gain_margin'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.gain_margin;
        else
            varargout{1} = 0;
        end
        
    case 'get_rise_time'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.rise_time;
        else
            varargout{1} = 0;
        end
        
    case 'get_overshoot'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.overshoot;
        else
            varargout{1} = 0;
        end
        
    case 'get_settling_time'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            varargout{1} = objects{obj_id}.settling_time;
        else
            varargout{1} = 0;
        end
        
    case 'tune'
        obj_id = varargin{1};
        params = struct();
        for i = 2:2:length(varargin)
            params.(varargin{i}) = varargin{i+1};
        end
        
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.tune(params);
        end
        varargout{1} = [];  % 返回空
        
    case 'plot'
        obj_id = varargin{1};

        set(0, 'DefaultFigureVisible', 'on');

        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id}.plotResults();
        end
        varargout{1} = [];  % 返回空
        
    case 'list'
        varargout{1} = length(objects);
        
    case 'destroy'
        obj_id = varargin{1};
        if obj_id <= length(objects) && ~isempty(objects{obj_id})
            objects{obj_id} = [];
        end
        varargout{1} = [];  % 返回空
        
    otherwise
        error('未知命令: %s。可用命令: create, set_plant, set_params, design, get_params, get_kp, get_ki, get_kd, get_performance, get_phase_margin, get_gain_margin, get_rise_time, get_overshoot, get_settling_time, tune, plot, list, destroy', cmd);
end
end