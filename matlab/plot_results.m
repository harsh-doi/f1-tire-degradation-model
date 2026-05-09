function plot_results(results, lap_actual)
% PLOT_RESULTS  Final 4-panel stint results plot
%
% Inputs:
%   results    — struct from stint_simulator
%   lap_actual — table with real lap times from FastF1

    lap_nums = results.lap_num;

    figure('Name', 'M4 — Full Stint Simulation', ...
           'Position', [50 50 1100 750]);

    % ── Plot 1: Layer temperatures vs lap ────────────────────────────
    subplot(2,2,1)
    plot(lap_nums, results.T_surf_mean,  'r-o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Surface')
    hold on
    plot(lap_nums, results.T_comp_mean,  'color', [0.94 0.62 0.15], ...
         'LineStyle', '-', 'Marker', 'o', 'LineWidth', 1.5, ...
         'MarkerSize', 4, 'DisplayName', 'Compound')
    plot(lap_nums, results.T_inner_mean, 'b-o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Inner')
    yline(85,  '--', 'color', [0.12 0.62 0.47], 'LineWidth', 1, ...
          'DisplayName', 'Optimal min')
    yline(110, '--', 'color', [0.12 0.62 0.47], 'LineWidth', 1, ...
          'DisplayName', 'Optimal max')
    xlabel('Lap number')
    ylabel('Mean temperature (C)')
    title('Layer temperatures vs lap')
    legend('Location', 'southeast', 'FontSize', 7)
    grid on
    xlim([1 lap_nums(length(lap_nums))])

    % ── Plot 2: Grip vs lap ───────────────────────────────────────────
    subplot(2,2,2)
    plot(lap_nums, results.mu_mean, 'g-o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Mean grip')
    hold on
    plot(lap_nums, results.mu_min, 'color', [0.5 0.8 0.5], ...
         'LineStyle', '--', 'Marker', 'o', 'LineWidth', 1.2, ...
         'MarkerSize', 4, 'DisplayName', 'Min grip')
    xlabel('Lap number')
    ylabel('Grip coefficient mu')
    title('Grip coefficient vs lap')
    legend('Location', 'southwest', 'FontSize', 7)
    grid on
    xlim([1 lap_nums(length(lap_nums))])

    % ── Plot 3: Predicted vs actual lap time ──────────────────────────
    subplot(2,2,3)
    plot(lap_nums, results.lap_time_pred, 'r-o', ...
         'LineWidth', 1.5, 'MarkerSize', 4, 'DisplayName', 'Model prediction')
    hold on
    plot(lap_actual.LapNumber, lap_actual.LapTime_s, 'w-s', ...
         'LineWidth', 1.5, 'MarkerSize', 5, 'DisplayName', 'Russell actual')
    xlabel('Lap number')
    ylabel('Lap time (s)')
    title('Predicted vs actual lap time')
    legend('Location', 'northwest', 'FontSize', 7)
    grid on
    xlim([1 lap_nums(length(lap_nums))])
    ylim([93 100])

    % ── Plot 4: Degradation index vs lap ─────────────────────────────
    subplot(2,2,4)
    plot(lap_nums, results.deg_index * 100, 'color', [0.94 0.62 0.15], ...
         'LineStyle', '-', 'Marker', 'o', ...
         'LineWidth', 1.5, 'MarkerSize', 4)
    xlabel('Lap number')
    ylabel('Degradation index (%)')
    title('Tyre degradation index vs lap')
    grid on
    xlim([1 lap_nums(length(lap_nums))])
    ylim([0 20])

    sgtitle('Russell — Japan 2026 Stint 1 (Medium) — Full Stint Simulation', ...
            'FontSize', 12, 'FontWeight', 'bold')
end