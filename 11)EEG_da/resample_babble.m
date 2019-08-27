% Resample multitalker babble from Parbery-Clark et al. (2009, JNeuro) so 
% that sampling rate matches the EEG stimulus delivery sampling rate.

fs_eeg = 24414; % EEG stimulus delivery sampling rate

[babble,fs_Parbery] = audioread('6-talker_2M-4F.wav'); % stimulus from Parbery-Clark et al. (2009, JNeuro)

babble_resampled = resample(babble,fs_eeg,fs_Parbery); % Resampled stimulus has a sampling rate of fs_eeg

babble_resampled = babble_resampled/max(abs(babble_resampled)); % makes max amplitude +/-1 so audiowrite doesn't chop it off

audiowrite('babble_resampled.wav',babble_resampled',fs_eeg);

figure
subplot(1,2,1)
Original = babble;
OriginalFFT = abs(fft(Original));
n = length(Original);
freq=fs_Parbery/n.*(1:n);
omi3=OriginalFFT(1:(n/2));
f=freq(1:(n/2));
plot(f,omi3); 
set(gca,'yscale','log')
set(gca,'xscale','log')
title('Babble from Parbery-Clark et al. (2009)')
ylabel('Magnitude')
xlabel('Frequency')
hold on

subplot(1,2,2)
[babble_new,fs_new] = audioread('babble_resampled.wav');
mFFT = abs(fft(babble_new));
n2 = length(mFFT);
freq_m = fs_new/n2.*(1:n2);
thebabble_new = mFFT(1:(n2/2));
fN=freq_m(1:(n2/2));
plot(fN,thebabble_new,'r');
set(gca,'yscale','log')
set(gca,'xscale','log')
title('Babble Resampled')
ylabel('Magnitude')
xlabel('Frequency')
hold off

figure
plot(fN,thebabble_new,'r');
hold on
plot(f,omi3);
% ylim([0 3000])
set(gca,'yscale','log')
set(gca,'xscale','log')
ylabel('Magnitude')
xlabel('Frequency')
legend('Resampled babble','Parbery-Clark et al.','Location','Best')