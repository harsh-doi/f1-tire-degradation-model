function [lap, telem, weather, meta] = load_data(stint_num)
% LOAD_DATA  Load FastF1 CSV exports for a given stint
%
% Input:  stint_num — which stint to load (1 or 2)
% Output: lap       — lap-by-lap table
%         telem     — speed telemetry table
%         weather   — weather conditions table
%         meta      — struct with boundary condition scalars

    base = '../data/2026_Miami_VER/';

    % ── Read index manually (avoids MATLAB CSV parsing issues) ────────
    raw  = readlines([base 'index.csv']);
    raw  = raw(raw ~= "");
    rows = split(raw, ',');

    stint_col     = str2double(rows(2:end, 1));
    compound_col  = rows(2:end, 2);
    lapfile_col   = rows(2:end, 4);
    tracefile_col = rows(2:end, 5);

    idx = find(stint_col == stint_num);
    if isempty(idx)
        error('Stint %d not found in index.csv', stint_num);
    end

    compound   = char(compound_col(idx));
    lap_file   = char(lapfile_col(idx));
    trace_file = char(tracefile_col(idx));

    fprintf('Loading Stint %d — %s compound\n', stint_num, compound);

    % ── Lap data ──────────────────────────────────────────────────────
    lap = readtable([base lap_file]);

    lap = lap(~isnan(lap.LapTime_s) & ...
               lap.LapTime_s > 88   & ...
               lap.LapTime_s < 100, :);

    fprintf('  Valid laps   : %d\n',     height(lap));
    fprintf('  Lap time min : %.2f s\n', min(lap.LapTime_s));
    fprintf('  Lap time max : %.2f s\n', max(lap.LapTime_s));
    fprintf('  Degradation  : %.2f s over stint\n', ...
            max(lap.LapTime_s) - min(lap.LapTime_s));

    % ── Speed trace ───────────────────────────────────────────────────
    telem      = readtable([base trace_file]);
    telem.Time = (telem.Time - telem.Time(1)) / 1000;  % ms → seconds

    fprintf('  Telemetry pts: %d (%.1f s lap)\n', ...
            height(telem), telem.Time(end));
    fprintf('  Top speed    : %.1f km/h\n', max(telem.Speed));

    % ── Weather ───────────────────────────────────────────────────────
    weather = readtable([base 'weather.csv']);

    % ── Meta struct — boundary conditions for the ODE ─────────────────
    meta.T_air    = median(weather.AirTemp,   'omitnan');
    meta.T_track  = median(weather.TrackTemp, 'omitnan');
    meta.compound = compound;
    meta.stint    = stint_num;
    meta.n_laps   = height(lap);

    fprintf('  Air temp     : %.1f C\n', meta.T_air);
    fprintf('  Track temp   : %.1f C\n', meta.T_track);
end