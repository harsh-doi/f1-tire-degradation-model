function dTdt = thermal_ode(t, T, Q_interp, t_s, params)
% THERMAL_ODE  3-layer tire heat transfer ODE for ode45
%
% State vector T = [T_surface; T_compound; T_inner]  (degrees C)
%
% Energy balance per layer:
%   rho * Cp * h * dT/dt = heat_in - heat_out
%
% Inputs:
%   t          — current time (s), used by ode45
%   T          — current temperature state [3x1]
%   Q_interp   — interpolant object for Q(t) friction heat
%   t_s        — time vector for clamping
%   params     — struct of thermal and geometric properties
%
% Output:
%   dTdt       — time derivatives [3x1]

    % ── Unpack state ──────────────────────────────────────────────────
    T_surf = T(1);      % surface layer temperature (C)
    T_comp = T(2);      % compound layer temperature (C)
    T_inn  = T(3);      % inner/carcass layer temperature (C)

    % ── Unpack parameters ─────────────────────────────────────────────
    % Thermal conductivity (W/m/K)
    k_sc   = params.k_sc;       % surface  ↔ compound
    k_ci   = params.k_ci;       % compound ↔ inner

    % Volumetric heat capacity rho*Cp (J/m^3/K)
    rCp_s  = params.rCp_s;      % surface
    rCp_c  = params.rCp_c;      % compound
    rCp_i  = params.rCp_i;      % inner

    % Layer thickness (m)
    h_s    = params.h_s;        % surface  layer thickness
    h_c    = params.h_c;        % compound layer thickness
    h_i    = params.h_i;        % inner    layer thickness

    % Convection coefficient (W/m^2/K)
    hconv  = params.hconv;      % surface to air

    % Hysteresis coefficient (fraction of Q_friction added as internal heat)
    alpha  = params.alpha;

    % Boundary conditions
    T_air  = params.T_air;
    T_rim  = params.T_rim;      % rim temperature (approx = T_air + 10)

    % ── Friction heat at current time ─────────────────────────────────
    % Clamp t to valid range to avoid extrapolation
    t_clamped = max(t_s(1), min(t, t_s(length(t_s))));
    Q_fric    = Q_interp(t_clamped);
    Q_fric    = max(Q_fric, 0);     % ensure non-negative

    % ── Hysteresis heat (internal rubber flexing) ─────────────────────
    % Distributed: 60% in compound, 40% in inner layer
    Q_hys_total = alpha * Q_fric;
    Q_hys_c     = 0.6 * Q_hys_total;
    Q_hys_i     = 0.4 * Q_hys_total;

    % ── Conduction between layers (Fourier's law) ─────────────────────
    % Q_cond = k * (T_hot - T_cold) / thickness   [W/m^2]
    Q_cond_sc = k_sc * (T_surf - T_comp) / ((h_s + h_c) / 2);
    Q_cond_ci = k_ci * (T_comp - T_inn)  / ((h_c + h_i) / 2);

    % ── Convection from surface to air ────────────────────────────────
    Q_conv = hconv * (T_surf - T_air);

    % ── Conduction from inner layer to rim ────────────────────────────
    Q_rim  = k_ci  * (T_inn  - T_rim)  / (h_i / 2);

    % ── Energy balance — dT/dt = net_heat / (rho*Cp*thickness) ───────
    % Surface: gains friction heat, loses to convection and conduction down
    dT_surf = (Q_fric - Q_conv - Q_cond_sc) / (rCp_s * h_s);

    % Compound: gains hysteresis heat, gains/loses conduction from surface
    dT_comp = (Q_hys_c + Q_cond_sc - Q_cond_ci) / (rCp_c * h_c);

    % Inner: gains hysteresis heat, gains conduction from compound, loses to rim
    dT_inn  = (Q_hys_i + Q_cond_ci - Q_rim) / (rCp_i * h_i);

    dTdt = [dT_surf; dT_comp; dT_inn];
end