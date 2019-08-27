% Resample /mi3/ stimulus from Wong et al. (2007) so that sampling rate
% matches the corresponding EEG system.

fs_eeg = 24414; % The sampleing rate of UMN's EEG system.

[mi3,fs_Wong] = audioread('mi3.wav'); % stimulus from Wong et al. (2007)

mi3_resampled = resample(mi3,fs_eeg,fs_Wong); % Resampled stimulus has a sampling rate of fs_eeg

mi3_resampled = mi3_resampled/max(abs(mi3_resampled)); % makes max amplitude +/-1 so audiowrite doesn't chop it off

%audiowrite('mi3_resampled.wav',mi3_resampled',fs_eeg);

figure
subplot(1,2,1)
Original = mi3;
OriginalFFT = abs(fft(Original));
n = length(Original);
freq=fs_Wong/n.*(1:n);
omi3=OriginalFFT(1:(n/2));
f=freq(1:(n/2));
plot(f,omi3); 
ylim([0 500]) 
set(gca,'yscale','log')
set(gca,'xscale','log')
title('mi3 from Wong et al. (2007)')
ylabel('Magnitude')
xlabel('Frequency')
hold on

subplot(1,2,2)
[mi3_new,fs_new] = audioread('mi3_resampled.wav');
mFFT = abs(fft(mi3_new));
n2 = length(mFFT);
freq_m = fs_new/n2.*(1:n2);
themi3_new = mFFT(1:(n2/2));
fN=freq_m(1:(n2/2));
plot(fN,themi3_new,'r');
ylim([0 500]) 
set(gca,'yscale','log')
set(gca,'xscale','log')
title('mi3 Resampled')
ylabel('Magnitude')
xlabel('Frequency')
hold off

figure
plot(fN,themi3_new,'r');
hold on
plot(f,omi3);
ylim([0 3000])
set(gca,'yscale','log')
set(gca,'xscale','log')
ylabel('Magnitude')
xlabel('Frequency')
legend('resampled mi3','Wong et al.','Location','Best')