function [t_out, T_out] = run_thermal_lap(t_s, Q, meta, T0)
% RUN_THERMAL_LAP  Solve thermal ODE for one lap with given initial temps
%
% Same as run_thermal but accepts T0 as input so the stint
% loop can carry temperatures forward lap by lap
%
% Inputs:
%   t_s  — time vector (s)
%   Q    — friction heat (W/m^2)
%   meta — boundary conditions struct
%   T0   — initial temperatures [T_surface; T_compound; T_inner]

    % ── Compound properties (Medium — Farroni TRT 2014) ───────────────
    params.k_sc  = 0.30;
    params.k_ci  = 0.25;
    params.rCp_s = 1.65e6;
    params.rCp_c = 1.80e6;
    params.rCp_i = 2.00e6;
    params.h_s   = 0.008;
    params.h_c   = 0.020;
    params.h_i   = 0.015;
    params.hconv = 1100;
    params.alpha = 0.10;
    params.T_air = meta.T_air; % 27.3 C
    params.T_rim = meta.T_air + 10;

    % ── Build Q interpolant ───────────────────────────────────────────
    Q_interp = @(t) interp1(t_s, Q, ...
                    max(t_s(1), min(t, t_s(length(t_s)))), 'linear');

    % ── ODE options ───────────────────────────────────────────────────
    opts = odeset('RelTol', 1e-4, 'AbsTol', 1e-6, 'MaxStep', 0.5);

    % ── Solve ─────────────────────────────────────────────────────────
    [t_out, T_out] = ode45(@(t,T) thermal_ode(t, T, Q_interp, t_s, params), ...
                            [t_s(1) t_s(length(t_s))], T0, opts);
end