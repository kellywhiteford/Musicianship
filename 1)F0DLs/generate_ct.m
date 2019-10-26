function [ct] = generate_ct(f0)
% Code created by Sara Madsen (Madsen, Whiteford, & Oxenham, 2017)
% Edited by KLW to filter complex tone for /da/ stimuli

global def 
global set

fs = def.samplerate; % sample rate (defined in F0DLs_cfg.m)
dur_ms = set.dur_ms; % duration of stimulus (defined in F0DLs_set.m)

np = ceil(6000/f0); % number of partials
dur = dur_ms/1000; % duration in seconds, plus a little extra (filtfilt wants a longer signal than 200 ms)

%% STIMULUS GENERATION
N = floor(dur*fs); % Number of samples. "floor" needed for nan function to treat N as an integer.
t = [0:N-1]./fs;    % time vector

tones = nan(np, N); % one partial per column
load('da_lpc.mat') % psd_da.mat created in "psd_da.m"

fp = (1:np) * f0; % the frequencies at which our harmonics will be
amp = abs(freqz(1, a, fp, fs)); % get the amplitudes at those frequencies
% a contains the LPC filter coefficients
for k = 1:np
    tones(k,:) = 0.1*amp(k)*sin(2*pi*(f0*k)*t); % phase of components is always zero
end

ct = sum(tones);
ct =ct';

%% plot some stuff
if false
    figure
    load('psd_da.mat') % psd_da.mat created in "psd_da.m"
    f_da = freq;
    [ha, f_a] = freqz(1, a, f_da, fs);
    f_ct = (0:length(ct) - 1) / length(ct) * fs;
    ct_fft = fft(ct);

    hold on
    plot(f_a, 20 * log10(ha) + 54)
    plot(f_da, 20 * log10(sqrt(psdx)) + 160)
    plot(f_ct(1:length(ct) / 2), 20 * log10(ct_fft(1:length(ct) / 2)))
    ylim([20, 140])
    xlim([0, 6000])
    hold off
end