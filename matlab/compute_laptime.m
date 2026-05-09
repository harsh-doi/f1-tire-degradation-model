function [lap_time_pred, delta_vs_ref] = compute_laptime(mu, t_s, lap_ref)
% COMPUTE_LAPTIME  Convert grip coefficient to predicted lap time
%
% Physics basis:
%   In corners, cornering speed scales with sqrt(mu)
%   Time through corner scales with 1/sqrt(mu)
%   On straights, grip has minimal effect on lap time
%
% Inputs:
%   mu          — grip vector over the lap
%   t_s         — time vector (s)
%   lap_ref     — reference lap time (s) at peak grip conditions
%
% Outputs:
%   lap_time_pred   — predicted lap time (s)
%   delta_vs_ref    — time lost vs reference (s)

    % ── Reference grip ────────────────────────────────────────────────
    mu_ref = 1.65;          % peak grip, new medium, optimal temperature

    % ── Grip ratio per time step ──────────────────────────────────────
    % Cornering speed ~ sqrt(mu), so time ~ 1/sqrt(mu/mu_ref)
    grip_ratio = sqrt(mu_ref ./ max(mu, 0.5));  % 1/sqrt scaling, floor at 0.5

    % ── Suzuka corner fraction ────────────────────────────────────────
    % Only cornering sections are grip-limited
    % Straights are power-limited — grip irrelevant there
    % Suzuka: ~28% of lap time is genuinely grip-limited cornering
    corner_fraction = 0.17;

    % ── Mean time penalty from grip deficit ───────────────────────────
    mean_grip_ratio = mean(grip_ratio);

    % Blended factor: corners affected by grip, straights not
    time_factor = (1 - corner_fraction) + corner_fraction * mean_grip_ratio;

    % ── Predicted lap time ────────────────────────────────────────────
    lap_time_pred = lap_ref * time_factor;
    delta_vs_ref  = lap_time_pred - lap_ref;
end