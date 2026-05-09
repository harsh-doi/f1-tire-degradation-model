function [t_s, Q] = heat_input(telem, meta)
% HEAT_INPUT  Compute friction heat Q(t) from telemetry
%
% Physics:
%   Q = (mu * Fz * v_slip) / A_contact    [W/m^2]

    % ── Car parameters (Mercedes W17 approximate) ─────────────────────
    m_car     = 800;        % kg
    g         = 9.81;       % m/s^2
    mu        = 1.6;        % friction coefficient
    A_contact = 0.04;       % contact patch area m^2
    slip_base = 0.0020;       % baseline rolling slip
    rho_air   = 1.2;        % kg/m^3
    Cl        = 3.5;        % downforce coefficient
    A_ref     = 1.5;        % reference area m^2

    % ── Extract Time as plain double ──────────────────────────────────
    t_s = telem.Time;
    if isduration(t_s)
        t_s = seconds(t_s);
    elseif iscell(t_s)
        t_s = cellfun(@str2double, t_s);
    end
    t_s = double(t_s(:));

    % ── Extract Speed as plain double ─────────────────────────────────
    v_kmh = telem.Speed;
    if iscell(v_kmh)
        v_kmh = cellfun(@str2double, v_kmh);
    end
    v_ms  = double(v_kmh(:)) / 3.6;

    % ── Extract Throttle as plain double ──────────────────────────────
    thr = telem.Throttle;
    if iscell(thr)
        thr = cellfun(@str2double, thr);
    end
    throttle = double(thr(:)) / 100;

    % ── Extract Brake as plain double ─────────────────────────────────
    br = telem.Brake;
    if iscell(br)
        % Handle 'True'/'False' strings or numeric strings
        br = cellfun(@(x) strcmpi(string(x), "True") || str2double(x) == 1, br);
    end
    brake = double(br(:));

    % ── Clean NaN values (replace with safe defaults) ─────────────────
    throttle(isnan(throttle)) = 0;
    brake(isnan(brake))       = 0;
    v_ms(isnan(v_ms))         = 0;

    % ── Vertical load per tyre ────────────────────────────────────────
    F_aero = 0.5 * rho_air * Cl * A_ref * v_ms.^2;
    Fz     = (m_car * g + F_aero) / 4;

    % ── Slip velocity ─────────────────────────────────────────────────
    slip   = slip_base + 0.008 * brake + 0.004 * throttle;
    v_slip = v_ms .* slip;

    % ── Friction heat ─────────────────────────────────────────────────
    Q = (mu * Fz .* v_slip) / A_contact;

    % ── Plot ──────────────────────────────────────────────────────────
    figure('Name', 'M1 — Heat Input Profile', 'Position', [100 100 900 600]);

    subplot(3,1,1)
    plot(t_s, v_ms * 3.6, 'Color', [0.22 0.62 0.85], 'LineWidth', 1.2)
    ylabel('Speed (km/h)')
    title(sprintf('Verstappen — Miami 2026 Stint %d (%s) — Fastest Lap', ...
                  meta.stint, meta.compound))
    grid on
    xlim([0 t_s(length(t_s))])

    subplot(3,1,2)
    plot(t_s, Fz / 1000, 'Color', [0.94 0.62 0.15], 'LineWidth', 1.2)
    ylabel('Fz per tyre (kN)')
    grid on
    xlim([0 t_s(length(t_s))])

    subplot(3,1,3)
    plot(t_s, Q / 1000, 'Color', [0.89 0.29 0.29], 'LineWidth', 1.2)
    ylabel('Q friction (kW/m^2)')
    xlabel('Time (s)')
    grid on
    xlim([0 t_s(length(t_s))])

    % ── Console summary ───────────────────────────────────────────────
    fprintf('\n-- Q(t) summary --\n')
    fprintf('  Peak Q : %.1f kW/m^2\n', max(Q)/1000)
    fprintf('  Mean Q : %.1f kW/m^2\n', mean(Q)/1000)
    fprintf('  Min  Q : %.1f kW/m^2\n', min(Q)/1000)
end