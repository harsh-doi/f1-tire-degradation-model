function [best_params, best_error] = tune_model(t_s, Q, meta, lap_actual)
% TUNE_MODEL  Automated parameter tuning to match real lap times
%
% Uses a grid search over key parameters to minimise RMS error
% between predicted and actual lap times across the full stint
%
% Inputs:
%   t_s        — time vector (s)
%   Q          — friction heat (W/m^2)
%   meta       — boundary conditions
%   lap_actual — table with real lap times
%
% Output:
%   best_params — tuned grip parameter struct
%   best_error  — RMS error at best parameters (s)

    fprintf('  Starting parameter grid search...\n')
    fprintf('  This may take 1-2 minutes.\n\n')

    % ── Actual lap times to match ─────────────────────────────────────
    actual_times = lap_actual.LapTime_s;
    n_laps       = length(actual_times);

    % ── Parameter search grid ─────────────────────────────────────────
    % Vary the three most sensitive parameters
    wear_rates     = [0.002, 0.004, 0.006, 0.008, 0.010];
    corner_fracs   = [0.06, 0.08, 0.10, 0.12, 0.14];
    mu_max_vals    = [1.55, 1.60, 1.65, 1.70, 1.75];

    best_error  = inf;
    best_params = struct();
    n_total     = length(wear_rates) * length(corner_fracs) * length(mu_max_vals);
    n_done      = 0;

    for wr = wear_rates
        for cf = corner_fracs
            for mm = mu_max_vals

                % Build parameter struct
                p.mu_max    = mm;
                p.T_peak    = 95;
                p.width_low = 30;
                p.width_hi  = 20;
                p.mu_cold   = 0.90;
                p.wear_rate = wr;
                p.corner_frac = cf;

                % Run stint
                try
                    pred = run_stint_fast(t_s, Q, meta, p);
                    n    = min(length(pred), n_laps);
                    err  = sqrt(mean((pred(1:n) - actual_times(1:n)).^2));

                    if err < best_error
                        best_error  = err;
                        best_params = p;
                    end
                catch
                    % skip failed runs
                end

                n_done = n_done + 1;
            end
        end
    end

    fprintf('  Grid search complete — %d combinations tested\n', n_total)
    fprintf('  Best RMS error : %.3f s\n', best_error)
    fprintf('  Best params:\n')
    fprintf('    mu_max      = %.3f\n', best_params.mu_max)
    fprintf('    wear_rate   = %.4f\n', best_params.wear_rate)
    fprintf('    corner_frac = %.3f\n', best_params.corner_frac)
end