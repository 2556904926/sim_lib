function h = pidTuner(varargin)
%PIDTUNER  Interactive GUI tool for PID controller design.
%
%    PIDTUNER opens the PID Tuner for designing a 1-DOF or 2-DOF PID
%    controller. For tuning a 1-DOF PID controller, the control system
%    configuration used by the PID Tuner is
%
%             r --->O--->[ PID ]--->[ Plant ]---+---> y
%                 - |                           |
%                   +---------------------------+
%
%    For tuning a 2-DOF PID controller, the control system configuration
%    used by the PID Tuner is
%
%             r ------->[     ]
%                       | PID |---->[ Plant ]---+---> y
%                   +-->[     ]                 |
%                   |                           |
%                   +---------------------------+
%
%    PIDTUNER(SYS,TYPE) designs a PID controller for plant SYS. SYS is a
%    single-input-single-output LTI system such as TF, ZPK, SS, FRD or a
%    linear model produced by System Identification Toolbox such as IDTF,
%    IDFRD, IDGREY, IDPOLY, IDPROC and IDSS. TYPE defines controller type,
%    and can be one of the following strings:
%
%       'P'     Proportional only control
%       'I'     Integral only control
%       'PI'    PI control
%       'PD'    PD control
%       'PDF'   PD control with first order derivative filter
%       'PID'   PID control
%       'PIDF'  PID control with first order derivative filter
%       'PI2'   2-DOF PI control
%       'PD2'   2-DOF PD control
%       'PDF2'  2-DOF PD control with first order derivative filter
%       'PID2'  2-DOF PID control
%       'PIDF2' 2-DOF PID control with first order derivative filter
%       'I-PD'  2-DOF PID control with b = 0, c = 0
%       'I-PDF' 2-DOF PID control with first order derivative filter and b = 0, c = 0
%       'ID-P'  2-DOF PID control with b = 0, c = 1
%       'IDF-P' 2-DOF PID control with first order derivative filter and b = 0, c = 1
%       'PI-D'  2-DOF PID control with b = 1, c = 0
%       'PI-DF' 2-DOF PID control with first order derivative filter and b = 1, c = 0
%
%    For discrete-time SYS, the PID controller has the same sample time as
%    SYS.
%
%    PIDTUNER(SYS,C) takes a LTI system C as the baseline controller so
%    that you can compare performances between the designed PID and the
%    baseline controller.  IF C is a PID, PIDSTD, PID2 or PIDSTD2 object,
%    the designed controller has the same type, form, and discretization
%    methods as C. C can also be a SS, TF, or ZPK system.
%
%    When SYS is (1) a FRD system or (2) a SS system that has internal
%    delay and cannot be converted into a ZPK system, the PID tuner assumes
%    that the plant does not have unstable poles. If there are unstable
%    poles, you must open the Import Linear System dialog after PID Tuner
%    is launched and import SYS with the number of unstable poles specified
%    in the dialog.
%
%   See also PIDTUNE

% Copyright 2010-2011 The MathWorks, Inc.

varargin = controllib.internal.util.hString2Char(varargin);

ni = nargin;
if ni==0
    if nargout>0
        h = pidtool;
    else
        pidtool;
    end
else
    sysname = inputname(1);
    if isempty(sysname)
        sysname = 'Plant';
    end
    eval([sysname ' = varargin{1};']);
    if ni==1
        cmd = ['pidtool(' sysname ');'];
    elseif ni==2
        cmd = ['pidtool(' sysname ',varargin{2});'];
    else
        ctrlMsgUtils.error('Control:general:TwoOrMoreInputsRequired','pidtool','pidtool');
    end
    if nargout>0
        h = eval(cmd);
    else
        eval(cmd);
    end
end