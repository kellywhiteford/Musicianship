% Power spectral density (PSD) estimates of /da/ stimulus

cd ../10)EEG_da % Folder with /da/ stimulus

[da, fs_da] = audioread('DAbase_resampled.wav');

cd ../2)F0DLs % Change back to F0DLs folder

N = length(da); % total number of samples of /da/ stimulus
N=2^nextpow2(N); % transform length of /da/ to be the next power of 2. fft will zero pad the end of the /da/ stimulus
xdft = fft(da,N); % discrete FFT of /da/
xdft = xdft(1:N/2+1); % take first half of fft output
psdx = (1/(fs_da*N)) * abs(xdft).^2;
psdx(2:end-1) = 2*psdx(2:end-1);
freq = 0:fs_da/N:fs_da/2; 

figure
plot(freq,10*log10(psdx))
grid on
title('Periodogram Using FFT')
xlabel('Frequency (Hz)')
ylabel('Power/Frequency (dB/Hz)')
set(gca,'xscale','log')

figure
subplot(1,2,1)
plot(da)
title('/da/')
hold on
subplot(1,2,2)
spec(da',80,fs_da);
title('/da/')

save('psd_da','psdx','freq', 'fs_da') % save variables to .mat file
