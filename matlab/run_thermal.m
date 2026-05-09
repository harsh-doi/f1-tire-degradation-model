function [t_out, T_out] = run_thermal(t_s, Q, meta)
% RUN_THERMAL  Solve 3-layer thermal ODE for one lap using ode45
%
% Inputs:  t_s   — time vector from heat_input (seconds)
%          Q     — friction heat vector (W/m^2)
%          meta  — struct with boundary conditions
% Outputs: t_out — time vector (s)
%          T_out — temperature matrix [Nx3]: surface, compound, inner

    % ── Tire compound properties (Medium — from Farroni TRT 2014) ─────
    % Thermal conductivity k (W/m/K)
    params.k_sc  = 0.25;        % surface  ↔ compound
    params.k_ci  = 0.20;        % compound ↔ inner

    % Volumetric heat capacity rho*Cp (J/m^3/K)
    % rho ~1100 kg/m^3, Cp ~1500 J/kg/K → rho*Cp ~1.65e6
    params.rCp_s = 1.65e6;      % surface
    params.rCp_c = 1.80e6;      % compound (slightly denser)
    params.rCp_i = 2.00e6;      % inner/carcass

    % Layer thickness (m)
    params.h_s   = 0.008;       % 4  mm surface tread
    params.h_c   = 0.020;       % 12 mm compound bulk
    params.h_i   = 0.015;       % 8  mm inner carcass

    % Convection coefficient — surface to airflow (W/m^2/K)
    % F1 tire at speed: forced convection ~50-80 W/m^2/K
    params.hconv = 1200;

    % Hysteresis coefficient — fraction of friction heat
    % generated internally through rubber flexing
    params.alpha = 0.08;

    % Boundary conditions
    params.T_air = meta.T_air;
    params.T_rim = meta.T_air + 10;    % rim runs ~10 C above ambient

    % ── Initial conditions ────────────────────────────────────────────
    % Tire starts at track temperature (warmed slightly by outlap)
    T0 = [meta.T_track + 5; ...     % surface  (outlap warms surface first)
          meta.T_track + 2;     ...     % compound
          meta.T_track];        % inner    (slowest to warm)

    % ── Build Q interpolant ───────────────────────────────────────────
    % ode45 calls the ODE at arbitrary time points — need to interpolate Q
    Q_interp = @(t) interp1(t_s, Q, ...
                    max(t_s(1), min(t, t_s(length(t_s)))), 'linear');

    % ── ODE options ───────────────────────────────────────────────────
    opts = odeset('RelTol', 1e-4, 'AbsTol', 1e-6, ...
                  'MaxStep', 0.5);   % max 0.5s step for smooth output

    % ── Solve ─────────────────────────────────────────────────────────
    fprintf('  Running ode45 over %.1f seconds...\n', t_s(length(t_s)));

    [t_out, T_out] = ode45(@(t,T) thermal_ode(t, T, Q_interp, t_s, params), ...
                            [t_s(1) t_s(length(t_s))], T0, opts);

    fprintf('  ode45 complete — %d time steps\n', length(t_out));
    fprintf('  T_surface final : %.1f C\n', T_out(length(t_out), 1));
    fprintf('  T_compound final: %.1f C\n', T_out(length(t_out), 2));
    fprintf('  T_inner final   : %.1f C\n', T_out(length(t_out), 3));

    % ── Plot ──────────────────────────────────────────────────────────
    figure('Name', 'M2 — 3-Layer Tire Temperatures', ...
           'Position', [100 100 900 500]);

    plot(t_out, T_out(:,1), 'Color', [0.89 0.29 0.29], ...
         'LineWidth', 1.5, 'DisplayName', 'Surface')
    hold on
    plot(t_out, T_out(:,2), 'Color', [0.94 0.62 0.15], ...
         'LineWidth', 1.5, 'DisplayName', 'Compound')
    plot(t_out, T_out(:,3), 'Color', [0.22 0.62 0.85], ...
         'LineWidth', 1.5, 'DisplayName', 'Inner')

    % Optimal temperature window for Medium compound
    yline(85,  '--', 'color', [0.12 0.62 0.47], ...
          'LineWidth', 1, 'DisplayName', 'Optimal min (85C)')
    yline(110, '--', 'color', [0.12 0.62 0.47], ...
          'LineWidth', 1, 'DisplayName', 'Optimal max (110C)')

    xlabel('Time (s)')
    ylabel('Temperature (C)')
    title(sprintf('Verstappen — Miami 2026 Stint %d (%s) — Lap Thermal Model', ...
                  meta.stint, meta.compound))
    legend('Location', 'southeast')
    grid on
    xlim([0 t_out(length(t_out))])
end