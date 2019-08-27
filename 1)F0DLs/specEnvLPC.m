% This script estimates the spectral envelope of the /da/ stimulus using
% Linear Predictive Coding and saves values to da_lpc.mat, which are called
% on in generate_ct.m.

cd ../10)EEG_da % Folder with /da/ stimulus

[da, fs_da] = audioread('DAbase_resampled.wav');

fs = 48000; % The sampleing rate for F0DLs task

da = resample(da,fs,fs_da); % Upsamples /da/ to match sampling rate of F0DLs
da = da/max(abs(da)); % makes max amplitude +/-1 

cd ../1)F0DLs % Change back to F0DLs folder

%% Calcualte spectral magnitude of /da/ stimulus
nfft = length(da); % for zero padding
dft = fft(da,nfft); 
dft = 2*abs(dft(1:nfft/2+1)); % Just keep the positive values, and multiply them by 2 to account for that we're taking half the fft data

freq = fs/2*linspace(0,1,nfft/2+1);  % frequency values for plotting;

%% Estimate spectral envelope using linear predictive coding
p=ceil(fs/1000) + 2; % parameters for lpc; this is one rule of thumb for formant estimation

a = lpc(da,p);  % filter coefficients

%% Plot spectral envelope vs. stimulus spectrum
if true
    lspec = freqz(1,a,freq,fs);
    figure 
    impz(1, a, [], fs)
    figure
    plot(freq, 20*log10(abs(lspec)),'k');
    hold on
    plot(freq,20*log10(dft * 10),'r') % factor of 10 gives similar gains for peaks
    ylabel('Magnitude (dB)') 
    xlabel('Frequency (Hz)')
    title(['/da/ Spectral Envelope from LPC: p = ' num2str(p)])
    set(gca,'xscale','log')
    xlim([0 7000])
    legend('Spectral Envelope','/da/ Spectrum','Location','Best')
end
%% Save variables
save('da_lpc','a','freq','fs_da') % save variables to .mat file
