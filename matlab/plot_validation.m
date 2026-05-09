function plot_validation(results, lap_actual, best_error)
% PLOT_VALIDATION  Final validation plot — predicted vs actual
%
% Inputs:
%   results    — struct from stint_simulator
%   lap_actual — table with real lap times
%   best_error — RMS error (s)

    lap_nums     = results.lap_num;
    actual_times = lap_actual.LapTime_s;
    actual_laps  = lap_actual.LapNumber;

    figure('Name', 'M5 — Validation', 'Position', [50 50 1200 800]);

    % ── Plot 1: Predicted vs actual lap time (main validation) ────────
    subplot(2,2,[1 2])
    plot(lap_nums, results.lap_time_pred, 'r-o', ...
         'LineWidth', 2, 'MarkerSize', 5, 'DisplayName', 'Model prediction')
    hold on
    plot(actual_laps, actual_times, 'w-s', ...
         'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Russell actual')

    % Error band — ±1s acceptable range
    fill([lap_nums; flipud(lap_nums)], ...
         [results.lap_time_pred - 1; flipud(results.lap_time_pred + 1)], ...
         'r', 'FaceAlpha', 0.08, 'EdgeColor', 'none', ...
         'DisplayName', '±1s error band')

    xlabel('Lap number', 'FontSize', 11)
    ylabel('Lap time (s)', 'FontSize', 11)
    title(sprintf(['Predicted vs Actual Lap Time — Russell Japan 2026 Stint 1 (Medium)\n' ...
                   'RMS Error = %.3f s'], best_error), 'FontSize', 11)
    legend('Location', 'northwest', 'FontSize', 9)
    grid on
    xlim([1 lap_nums(length(lap_nums))])

    % ── Plot 2: Temperature layers vs lap ────────────────────────────
    subplot(2,2,3)
    plot(lap_nums, results.T_surf_mean,  'r-o',  'LineWidth', 1.5, ...
         'MarkerSize', 3, 'DisplayName', 'Surface')
    hold on
    plot(lap_nums, results.T_comp_mean,  '-o', 'Color', [0.94 0.62 0.15], ...
         'LineWidth', 1.5, 'MarkerSize', 3, 'DisplayName', 'Compound')
    plot(lap_nums, results.T_inner_mean, 'b-o',  'LineWidth', 1.5, ...
         'MarkerSize', 3, 'DisplayName', 'Inner')
    yline(85,  '--', 'Color', [0.12 0.62 0.47], 'LineWidth', 1)
    yline(110, '--', 'Color', [0.12 0.62 0.47], 'LineWidth', 1)
    xlabel('Lap number')
    ylabel('Mean temperature (C)')
    title('Layer temperatures vs lap')
    legend('Location', 'southeast', 'FontSize', 7)
    grid on
    xlim([1 lap_nums(length(lap_nums))])

    % ── Plot 3: Grip and degradation vs lap ───────────────────────────
    subplot(2,2,4)
    yyaxis left
    plot(lap_nums, results.mu_mean, 'g-o', 'LineWidth', 1.5, ...
         'MarkerSize', 3, 'DisplayName', 'Mean grip')
    ylabel('Grip coefficient mu')

    yyaxis right
    plot(lap_nums, results.deg_index * 100, '-o', ...
         'Color', [0.94 0.62 0.15], 'LineWidth', 1.5, ...
         'MarkerSize', 3, 'DisplayName', 'Deg index (%)')
    ylabel('Degradation index (%)')

    xlabel('Lap number')
    title('Grip and degradation vs lap')
    grid on
    xlim([1 lap_nums(length(lap_nums))])

    sgtitle('Russell — Japan 2026 Stint 1 (Medium) — Model Validation', ...
            'FontSize', 12, 'FontWeight', 'bold')

    % ── Save figure ───────────────────────────────────────────────────
    saveas(gcf, '../plots/validation_russell_japan2026.png')
    fprintf('  Validation plot saved to ../plots/\n')
end