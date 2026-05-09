function [lap_times_pred] = run_stint_fast(t_s, Q, meta, params)
% RUN_STINT_FAST  Lightweight stint runner for parameter tuning
%
% Same as stint_simulator but returns only lap times
% and skips console printing for speed

    n_laps  = meta.n_laps;
    lap_ref = 94.47;

    % Initial temperatures
    T_start = [meta.T_track + 5; meta.T_track; meta.T_track - 5];

    lap_times_pred = zeros(n_laps, 1);

    for lap = 1:n_laps

        [t_out, T_out] = run_thermal_lap(t_s, Q, meta, T_start);
        T_surf         = T_out(:, 1);

        % Grip
        mu_max_now  = params.mu_max * (1 - min(1, (lap-1) * params.wear_rate / params.mu_max));
        p_lap       = params;
        p_lap.mu_max = mu_max_now;
        [mu, ~]     = grip_model(T_surf, lap, params);

        % Lap time with tunable corner fraction
        mu_ref      = 1.65;
        grip_ratio  = sqrt(mu_ref ./ max(mu, 0.5));
        mean_factor = (1 - params.corner_frac) + params.corner_frac * mean(grip_ratio);
        lap_times_pred(lap) = lap_ref * mean_factor;

        % Carry temperatures forward
        T_end      = T_out(length(t_out), :)';
        T_start(1) = T_end(1) * 0.85 + meta.T_track * 0.15;
        T_start(2) = T_end(2) * 0.92 + meta.T_track * 0.08;
        T_start(3) = T_end(3) * 0.96 + meta.T_track * 0.04;
    end
end