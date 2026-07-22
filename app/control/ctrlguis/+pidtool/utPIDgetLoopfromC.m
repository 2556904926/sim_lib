function [olsys, r2y, r2u, id2y, od2y] = utPIDgetLoopfromC(C,G,wc)
% PID helper function

% This function computes open loop GC, closed loop GC/(1+GC), input
% disturbance model G/(1+GC) and output disturbance model 1/(1+GC)
% G and C have to be in the same time domain and have the same sample time

% Author(s): R. Chen
%   Copyright 2009-2012 The MathWorks, Inc.

hw = ctrlMsgUtils.SuspendWarnings; %#ok<NASGU>

if ~isfinite(G)
    olsys = tf(nan);
    r2y = tf(nan);
    r2u = tf(nan);
    id2y = tf(nan);
    od2y = tf(nan);
    return
end

% Split C: C1 (r->u), C2 (y->u)
if issiso(C) % 1-dof
    C1 = 1;
    C2 = -1;
    K = C;
else % assuming 2-DOF structure u = C*[r;y]. Cannot use getComponenets as C might not be @pid2
    C = tf(C);
    C1 = C(1);
    C2 = C(2);
    K = 1;
end

% Compute closed-loop transfers
if isa(G,'FRDModel')
    G = frd(G);
    X = feedback([0 0 C1 C2; K 0 0 0; 0 G 0 0],eye(3),[1;2;4],[1;2;3],+1);
    r2y = X(3,3);
    r2u = X(2,3);
    id2y = X(3,2);
    od2y = 1+X(3,4);
else
    % Use state-space representation
    G = ss(G);
    % Because descriptor state-space models with internal delays cannot be
    % simulated with current technology, avoid descriptor form when C has
    % a pure derivative term by transforming (G,C) -> ((s+wc)*G,C/(s+wc))
    Transform = false;
    if ~isproper(C)
        Ts = G.Ts;
        if nargin<3
            wc = 1;
        end
        if Ts==0
            r = wc;
        else
            r = -exp(-wc*abs(Ts));
        end
        [Gt,Transform] = ioderiv(G,r);
    end
    
    if Transform
        % C is improper and so is C2/(1+GC1)
        F = tf(1,[1 r],Ts,'TimeUnit',G.TimeUnit);
        
        if isnumeric(K)
            C1t = ss(F*C1,'explicit');
            C2t = ss(F*C2,'explicit');
            Kt = 1;
        else
            C1t = 1;
            C2t = -1;
            Kt = ss(F*K,'explicit');
        end
        
        X = feedback([0 0 C1t C2t; Kt 0 0 0; 0 Gt 0 0],eye(3),[1;2;4],[1;2;3],+1);
        r2y = X(3,3);
        r2u = C1*feedback(K,G*C2,+1);
        id2y = F*X(3,2);
        od2y = 1+X(3,4);

    else
        X = feedback([0 0 C1 C2; K 0 0 0; 0 G 0 0],eye(3),[1;2;4],[1;2;3],+1);
        r2y = X(3,3);
        r2u = X(2,3);
        id2y = X(3,2);
        od2y = 1+X(3,4);
    end
end

olsys = -G*C2*K;
