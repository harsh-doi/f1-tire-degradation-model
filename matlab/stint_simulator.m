function [results] = stint_simulator(t_s, Q, meta, params_grip)
% STINT_SIMULATOR  Run thermal ODE lap by lap for full stint
%
% Each lap:
%   1. Run thermal ODE using previous lap final temps as initial conditions
%   2. Compute grip from surface temperature
%   3. Compute predicted lap time
%   4. Accumulate wear — mu_max drops each lap
%   5. Store results
%
% Inputs:
%   t_s         — time vector for one lap (s)
%   Q           — friction heat for one lap (W/m^2)
%   meta        — struct with boundary conditions and stint info
%   params_grip — struct with grip curve parameters
%
% Output:
%   results     — struct with per-lap arrays

    n_laps = meta.n_laps;

    % ── Preallocate results ───────────────────────────────────────────
    results.lap_num       = (1:n_laps)';
    results.T_surf_mean   = zeros(n_laps, 1);
    results.T_surf_max    = zeros(n_laps, 1);
    results.T_comp_mean   = zeros(n_laps, 1);
    results.T_inner_mean  = zeros(n_laps, 1);
    results.mu_mean       = zeros(n_laps, 1);
    results.mu_min        = zeros(n_laps, 1);
    results.deg_index     = zeros(n_laps, 1);
    results.lap_time_pred = zeros(n_laps, 1);

    % ── Reference lap time — fastest real lap ─────────────────────────
    lap_ref = 93.11;    % Verstappen fastest lap Miami 2026 stint 2

    % ── Initial tire temperature — start of stint ─────────────────────
    T_init = [meta.T_track + 5; ...    % surface
              meta.T_track;     ...    % compound
              meta.T_track - 5];       % inner

    fprintf('  Running %d lap stint simulation...\n', n_laps)
    fprintf('  %-6s %-12s %-12s %-12s %-10s %-12s\n', ...
            'Lap', 'T_surf(C)', 'T_comp(C)', 'mu_mean', 'DegIndex', 'LapTime(s)')
    fprintf('  %s\n', repmat('-', 1, 65))

    % ── Lap by lap loop ───────────────────────────────────────────────
    T_start = T_init;

    for lap = 1:n_laps

        % ── Run thermal ODE for this lap ──────────────────────────────
        [t_out, T_out] = run_thermal_lap(t_s, Q, meta, T_start);

        T_surf = T_out(:, 1);
        T_comp = T_out(:, 2);
        T_inn  = T_out(:, 3);

        % ── Grip model ────────────────────────────────────────────────
        [mu, deg_index] = grip_model(T_surf, lap, params_grip);

        % ── Lap time prediction ───────────────────────────────────────
        [lap_time_pred, ~] = compute_laptime(mu, t_out, lap_ref);

        % ── Store results ─────────────────────────────────────────────
        results.T_surf_mean(lap)   = mean(T_surf);
        results.T_surf_max(lap)    = max(T_surf);
        results.T_comp_mean(lap)   = mean(T_comp);
        results.T_inner_mean(lap)  = mean(T_inn);
        results.mu_mean(lap)       = mean(mu);
        results.mu_min(lap)        = min(mu);
        results.deg_index(lap)     = deg_index;
        results.lap_time_pred(lap) = lap_time_pred;

        fprintf('  %-6d %-12.1f %-12.1f %-12.3f %-10.3f %-12.2f\n', ...
                lap, mean(T_surf), mean(T_comp), mean(mu), ...
                deg_index, lap_time_pred)

        % ── Carry forward — final temps become next lap initial temps ──
        % Add small heat soak between laps (tire doesn't fully cool)
        T_end      = T_out(length(t_out), :)';
        T_start(1) = T_end(1) * 0.85 + meta.T_track * 0.15;  % surface cools slightly
        T_start(2) = T_end(2) * 0.92 + meta.T_track * 0.08;  % compound slower to cool
        T_start(3) = T_end(3) * 0.96 + meta.T_track * 0.04;  % inner barely changes

    end

    fprintf('  %s\n', repmat('-', 1, 65))
    fprintf('  Stint complete.\n')
    fprintf('  Predicted lap time range: %.2f s — %.2f s\n', ...
            min(results.lap_time_pred), max(results.lap_time_pred))
    fprintf('  Total predicted degradation: %.2f s\n', ...
            max(results.lap_time_pred) - min(results.lap_time_pred))
end