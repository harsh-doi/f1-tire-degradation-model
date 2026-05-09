function [mu, deg_index] = grip_model(T_surf, lap_num, params_grip)
% GRIP_MODEL  Compute grip coefficient from surface temperature

    % ── Unpack parameters ─────────────────────────────────────────────
    mu_max    = params_grip.mu_max;
    T_peak    = params_grip.T_peak;
    width_low = params_grip.width_low;
    width_hi  = params_grip.width_hi;
    mu_cold   = params_grip.mu_cold;
    wear_rate = params_grip.wear_rate;

    % ── Degradation ───────────────────────────────────────────────────
    deg_index  = min(1, (lap_num - 1) * wear_rate / mu_max);
    mu_max_now = mu_max * (1 - deg_index);

    % ── Bell curve ────────────────────────────────────────────────────
    mu = zeros(size(T_surf));

    for i = 1:length(T_surf)
        T = T_surf(i);

        if T <= T_peak
            % Rising side — grip builds from mu_cold to mu_max_now
            t_norm = (T - T_peak) / width_low;     % negative value
            mu(i)  = mu_cold + (mu_max_now - mu_cold) * exp(-t_norm^2);

        else
            % Falling side — grip drops from mu_max_now
            t_norm = (T - T_peak) / width_hi;      % positive value
            mu(i)  = mu_cold + (mu_max_now - mu_cold) * exp(-t_norm^2);
        end
    end

    % Hard floor — grip never below 40% of cold baseline
    mu = max(mu, mu_cold * 0.40);

    % Hard ceiling — grip never above current mu_max
    mu = min(mu, mu_max_now);
end