% SPP Framework Demonstration
clear; clc;

% Define time vector
t = linspace(0, 2*pi, 100)';

% Define sinusoidal strain and strain rate
strain = sin(t);
strain_rate = cos(t);

% Define stress response (nonlinear)
stress = sin(t) + 0.2 * sin(3*t); % Includes higher harmonics

% Compute first and second derivative of stress
stress_derivative = gradient(stress, t);
stress_second_derivative = gradient(stress_derivative, t);

% Compute instantaneous moduli
G_prime_t = -strain ./ stress;  % Storage modulus approximation
G_double_prime_t = -strain_rate ./ stress; % Loss modulus approximation

% Compute phase angle and phase angle velocity
delta_t = atan2(G_double_prime_t, G_prime_t);
delta_t_velocity = gradient(delta_t, t);

% Plot Results
figure;

subplot(3,1,1)
plot(t, strain, 'b--', 'LineWidth', 1.5); hold on;
plot(t, strain_rate, 'g-.', 'LineWidth', 1.5);
plot(t, stress, 'r', 'LineWidth', 1.5);
legend('Strain (\gamma)', 'Strain Rate (\gamma-dot)', 'Stress (\sigma)');
title('Material Response in LAOS');
xlabel('Time (t)');
ylabel('Normalized Units');

subplot(3,1,2)
plot(t, G_prime_t, 'b', 'LineWidth', 1.5); hold on;
plot(t, G_double_prime_t, 'g', 'LineWidth', 1.5);
legend("G'_{t} (Storage Modulus)", "G''_{t} (Loss Modulus)");
title('Instantaneous Moduli (SPP Framework)');
xlabel('Time (t)');
ylabel('Modulus');

subplot(3,1,3)
plot(t, delta_t, 'm', 'LineWidth', 1.5); hold on;
plot(t, delta_t_velocity, 'c--', 'LineWidth', 1.5);
legend('Phase Angle (\delta_{t})', 'Phase Angle Velocity (\delta-dot_{t})');
title('Time-Resolved Yielding Dynamics');
xlabel('Time (t)');
ylabel('Radians or Rate');

sgtitle('Sequence of Physical Processes (SPP) Framework Visualization');
