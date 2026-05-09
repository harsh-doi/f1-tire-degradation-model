%% ═══════════════════════════════════════════════════════════════════
%  F1 TIRE DEGRADATION MODEL
%  Driver : Max Verstappen
%  Race   : 2026 Miami Grand Prix, Miami
%
%  MILESTONE 1 — Load data and build heat input profile Q(t)
%% ═══════════════════════════════════════════════════════════════════

clc; clear; close all;

%% ── Configuration ────────────────────────────────────────────────────
STINT = 2;      % Hard compound, 51 laps

%% ── M1: Load data ────────────────────────────────────────────────────
fprintf('==============================\n')
fprintf(' M1: Loading FastF1 Data\n')
fprintf('==============================\n')

[lap, telem, weather, meta] = load_data(STINT);

%% ── M1: Compute heat input ───────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Computing Q(t)\n')
fprintf('==============================\n')

[t_s, Q] = heat_input(telem, meta);

%% ── M1: Sanity checks ────────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Sanity Checks\n')
fprintf('==============================\n')

n_pts = length(t_s);

fprintf('Telemetry lap duration : %.2f s\n', t_s(n_pts));
fprintf('Fastest lap time (CSV) : %.2f s\n', min(lap.LapTime_s));

if any(Q < 0)
    warning('Q contains negative values — check brake/throttle signals')
else
    fprintf('Q is positive throughout  : OK\n')
end

if max(Q)/1000 > 50 && max(Q)/1000 < 500
    fprintf('Peak Q = %.1f kW/m^2       : OK\n', max(Q)/1000)
else
    warning('Peak Q = %.1f kW/m^2 — outside expected range', max(Q)/1000)
end

fprintf('\nM1 complete — check the three-panel plot.\n')
fprintf('Q should peak at braking zones (speed drops sharply).\n')
fprintf('When satisfied, we move to M2.\n')
%
%  MILESTONE 2 — 3-layer thermal ODE
%% ═══════════════════════════════════════════════════════════════════

clc; clear; close all;

%% ── Configuration ────────────────────────────────────────────────────
STINT = 2;      % 1 = Medium, 2 = Hard

%% ── M1: Load data ────────────────────────────────────────────────────
fprintf('==============================\n')
fprintf(' M1: Loading FastF1 Data\n')
fprintf('==============================\n')

[lap, telem, weather, meta] = load_data(STINT);

%% ── M1: Compute heat input ───────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Computing Q(t)\n')
fprintf('==============================\n')

[t_s, Q] = heat_input(telem, meta);

%% ── M2: Solve thermal ODE ────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M2: Solving Thermal ODE\n')
fprintf('==============================\n')

[t_out, T_out] = run_thermal(t_s, Q, meta);

fprintf('\nM2 complete — check the temperature plot.\n')
fprintf('Surface should be hottest, inner coolest.\n')
fprintf('Surface should approach 85-110 C optimal window.\n')
fprintf('When satisfied, we move to M3.\n')
%
%  MILESTONE 3 — Grip model and lap time prediction
%% ═══════════════════════════════════════════════════════════════════

clc; clear; close all;

%% ── Configuration ────────────────────────────────────────────────────
STINT = 2;      % 1 = Medium, 2 = Hard

%% ── M1: Load data ────────────────────────────────────────────────────
fprintf('==============================\n')
fprintf(' M1: Loading FastF1 Data\n')
fprintf('==============================\n')

[lap, telem, weather, meta] = load_data(STINT);

%% ── M1: Compute heat input ───────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Computing Q(t)\n')
fprintf('==============================\n')

[t_s, Q] = heat_input(telem, meta);

%% ── M2: Solve thermal ODE ────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M2: Solving Thermal ODE\n')
fprintf('==============================\n')

[t_out, T_out] = run_thermal(t_s, Q, meta);

%% ── M3: Grip model ───────────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M3: Grip Model\n')
fprintf('==============================\n')

% Hard compound parameters — higher optimal temp, wider window, slower wear ──────────────────────────────
params_grip.mu_max    = 1.60;   % hard compound slightly less peak grip
params_grip.T_peak    = 100;    % hard peaks at higher temp
params_grip.width_low = 35;     % wider window — more forgiving
params_grip.width_hi  = 25;     % less aggressive drop-off
params_grip.mu_cold   = 0.85;   % slightly lower cold grip
params_grip.wear_rate = 0.006;  % slower wear than medium

% ── Compute grip for lap 1 ────────────────────────────────────────────
T_surface = T_out(:, 1);        % surface temperature from ODE
LAP_NUM   = 1;

[mu, deg_index] = grip_model(T_surface, LAP_NUM, params_grip);

fprintf('  Mean grip  : %.3f\n', mean(mu));
fprintf('  Min grip   : %.3f\n', min(mu));
fprintf('  Max grip   : %.3f\n', max(mu));
fprintf('  Deg index  : %.3f\n', deg_index);

% ── Lap time prediction ───────────────────────────────────────────────
lap_ref = min(lap.LapTime_s);   % fastest real lap = reference

[lap_time_pred, delta] = compute_laptime(mu, t_out, lap_ref);

fprintf('\n  Reference lap time  : %.2f s\n', lap_ref);
fprintf('  Predicted lap time  : %.2f s\n',  lap_time_pred);
fprintf('  Delta vs reference  : +%.2f s\n', delta);
fprintf('  Actual lap 1 time   : %.2f s\n',  lap.LapTime_s(1));

% ── Plot grip vs temperature ──────────────────────────────────────────
figure('Name', 'M3 — Grip vs Surface Temperature', ...
       'Position', [100 100 900 400]);

subplot(1,2,1)
    scatter(T_surface, mu, 8, t_out, 'filled')
    colorbar; colormap(hot)
    xlabel('Surface Temperature (C)')
    ylabel('Grip coefficient mu')
    title('Grip vs Temperature (coloured by time)')
    xline(params_grip.T_peak, '--g', 'T_{peak}', 'LineWidth', 1)
    xline(85,  '--', 'color', [0.12 0.62 0.47], 'LineWidth', 1)
    xline(110, '--', 'color', [0.12 0.62 0.47], 'LineWidth', 1)
    grid on

subplot(1,2,2)
    plot(t_out, mu, 'Color', [0.22 0.62 0.85], 'LineWidth', 1.5)
    xlabel('Time (s)')
    ylabel('Grip coefficient mu')
    title('Grip vs Time — Lap 1')
    yline(params_grip.mu_max, '--r', 'mu_{max}', 'LineWidth', 1)
    yline(params_grip.mu_cold, '--', 'color', [0.5 0.5 0.5], 'LineWidth', 1)
    grid on
    xlim([0 t_out(length(t_out))])

fprintf('\nM3 complete — check grip plots.\n')
fprintf('Grip should be low when surface is cold or overheating.\n')
fprintf('When satisfied, we move to M4 — full stint loop.\n')
%
%  MILESTONE 4 — Full stint loop
%% ═══════════════════════════════════════════════════════════════════

clc; clear; close all;

%% ── Configuration ────────────────────────────────────────────────────
STINT = 2;      % 1 = Medium, 2 = Hard

%% ── M1: Load data ────────────────────────────────────────────────────
fprintf('==============================\n')
fprintf(' M1: Loading FastF1 Data\n')
fprintf('==============================\n')

[lap, telem, weather, meta] = load_data(STINT);

%% ── M1: Compute heat input ───────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Computing Q(t)\n')
fprintf('==============================\n')

[t_s, Q] = heat_input(telem, meta);

%% ── M4: Grip parameters ──────────────────────────────────────────────
params_grip.mu_max    = 1.65;
params_grip.T_peak    = 95;
params_grip.width_low = 30;
params_grip.width_hi  = 20;
params_grip.mu_cold   = 0.90;
params_grip.wear_rate = 0.012;

%% ── M4: Run full stint simulation ────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M4: Full Stint Simulation\n')
fprintf('==============================\n')

results = stint_simulator(t_s, Q, meta, params_grip);

%% ── M4: Plot results ─────────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M4: Plotting Results\n')
fprintf('==============================\n')

plot_results(results, lap);

fprintf('\nM4 complete.\n')
fprintf('Check Plot 3 — predicted vs actual lap time.\n')
fprintf('If the curves match, M4 is done and we move to M5.\n')
%
%  MILESTONE 5 — Validation and tuning
%% ═══════════════════════════════════════════════════════════════════

clc; clear; close all;

% Create plots folder if it doesn't exist
if ~exist('../plots', 'dir')
    mkdir('../plots')
end

%% ── Configuration ────────────────────────────────────────────────────
STINT = 2;

%% ── M1: Load data ────────────────────────────────────────────────────
fprintf('==============================\n')
fprintf(' M1: Loading FastF1 Data\n')
fprintf('==============================\n')

[lap, telem, weather, meta] = load_data(STINT);

%% ── M1: Compute heat input ───────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M1: Computing Q(t)\n')
fprintf('==============================\n')

[t_s, Q] = heat_input(telem, meta);

%% ── M5: Parameter tuning ─────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M5: Tuning Parameters\n')
fprintf('==============================\n')

[best_params, best_error] = tune_model(t_s, Q, meta, lap);

%% ── M4: Run full stint with best parameters ──────────────────────────
fprintf('\n==============================\n')
fprintf(' M4: Running Tuned Stint\n')
fprintf('==============================\n')

results = stint_simulator(t_s, Q, meta, best_params);

%% ── M5: Validation plot ──────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M5: Validation Plot\n')
fprintf('==============================\n')

plot_validation(results, lap, best_error);

%% ── M5: Final summary ────────────────────────────────────────────────
fprintf('\n==============================\n')
fprintf(' M5: Final Summary\n')
fprintf('==============================\n')

% Reload lap data for comparison
[lap2, ~, ~, ~] = load_data(STINT);

actual_deg = max(lap2.LapTime_s) - min(lap2.LapTime_s);
model_deg  = max(results.lap_time_pred) - min(results.lap_time_pred);

fprintf('RMS lap time error    : %.3f s\n',  best_error)
fprintf('Actual degradation    : %.2f s\n',  actual_deg)
fprintf('Predicted degradation : %.2f s\n',  model_deg)
fprintf('Degradation error     : %.2f s\n',  abs(actual_deg - model_deg))
fprintf('\nBest parameters:\n')
fprintf('  mu_max      = %.3f\n', best_params.mu_max)
fprintf('  wear_rate   = %.4f\n', best_params.wear_rate)
fprintf('  corner_frac = %.3f\n', best_params.corner_frac)
fprintf('Validation plot saved to ../plots/\n')