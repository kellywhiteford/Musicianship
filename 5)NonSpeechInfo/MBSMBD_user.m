% MBSMBD_user - stimulus generation function of experiment 'MBSMBD' -
%
% This function is called by afc_main when starting
% the experiment 'MBSMBD'. It generates the stimuli which
% are presented during the experiment.

function MBSMBD_user

global def
global work
global set

maskLevel = set.sigLevelAtten - work.expvaract; % this is the overall level in SNR

%Oxenham et al. (2003): The frequencies of the masker tones are randomly
%drawn from a uniform distribution of frequencies (on a logrithmic scale)
%ranging from 200-5000 Hz excluding a protected region with a bandwidth of
%400 Hz, geometrically centered around 1000 Hz.

% Lower and upper frequency cutoffs of protection region. This region has a
% bandwidth of 400 Hz and is geometrically centered around 1000 Hz
lowerRegion = 1000 / sqrt(1 + 48.79215/100); 
upperRegion = 1000 * sqrt(1 + 48.79215/100);

% bw = upperRegion - lowerRegion % Checks that bandwidth is 400 Hz. 
% sqrt(upperRegion*lowerRegion) % Checks that geometric mean of cutoff frequencies is 400 Hz

npoints = 5000-200-400; %Number of points in uniform distribution, excluding protected region

freqDistLow = logspace(log10(200),log10(lowerRegion),npoints/2); %Frequency distribution below protected region
freqDistHigh = logspace(log10(upperRegion),log10(5000),npoints/2); %Frequency distribution above protected region

freqDist = [freqDistLow, freqDistHigh]; %Uniform distriubtion of frequencies (on a logrithmic scale) ranging from 200-5000 Hz, excluding the protected region

nComps = 8; %Number of components in complex tone
nBursts = 8; %Number of bursts in a sequence


% Rows: Bursts
% Cols: Component frequencies
freqsRef = zeros(8,8);
freqsTarg = zeros(8,8);

switch work.exppar2
    case 0 %MBS
        % Every multitone masker burst has the same frequency components
        % within a sequence, which are randomly selected (without
        % replacement) from trial to trial.
        freqsRef(:,:) = repmat(datasample(freqDist,nComps,'Replace',false),8,1);
        freqsTarg(:,:) = repmat(datasample(freqDist,nComps,'Replace',false),8,1);
    case 1 %MBD
        % Columns contain 8 unique frequency components for each multitone 
        % masker complex, which are randomly selected without replacement.
        for b=1:size(freqsRef,1)
            freqsRef(b,:) = datasample(freqDist,nComps,'Replace',false);
            freqsTarg(b,:) = datasample(freqDist,nComps,'Replace',false);
        end
end

a_burst = scale(tone(work.exppar1,set.burst_dur,0,def.samplerate),set.sigLevelAtten); % one tone burst with the level scaled to 20 dB SL
burst = hann(a_burst,set.ramp_ms,def.samplerate); % one tone burst with ramps
signal = [burst,burst,burst,burst,burst,burst,burst,burst]; % signal sequence of 8 tone bursts

% Rows: Frequency components
% Cols: Samples (time)
componentsRef = zeros(nComps,size(burst,2));
componentsTarg = zeros(nComps,size(burst,2));

% Rows: Burst
% Cols: Samples (time)
refBursts = zeros(nBursts,size(burst,2));
targBursts = zeros(nBursts,size(burst,2));
for b=1:nBursts
    for c=1:nComps
        componentsRef(c,:) = tone(freqsRef(b,c),set.burst_dur,0,def.samplerate);
        componentsTarg(c,:) = tone(freqsTarg(b,c),set.burst_dur,0,def.samplerate);
    end
    refBursts(b,:) = hann(scale(sum(componentsRef,1),maskLevel-(10*log10(nComps))),set.ramp_ms,def.samplerate); % sums across rows to create complex-tone burst and then scales burst; each row of refBursts is a different complex-tone burst
    targBursts(b,:) = hann(scale(sum(componentsTarg,1),maskLevel-(10*log10(nComps))),set.ramp_ms,def.samplerate); % sums across rows to create complex-tone burst and then scales burst; each row of targBursts is a different complex-tone burst
end

ref = reshape(refBursts',1,size(signal,2)); % masker sequence of 8 multitone bursts for reference
targ_masker = reshape(targBursts',1,size(signal,2)); % masker sequence of 8 multitone bursts for target

targ_masker_sig = targ_masker + signal;

% if work.presentationCounter == 1 % make plots on first trial (for debugging)
%     figure
%     subplot(1,2,1)
%     plot(targ_masker_sig)
%     title('Target (Masker+Signal)')
%     ylabel('Amplitude')
%     hold on
%     subplot(1,2,2)
%     spec(targ_masker_sig,80,def.samplerate);
%     title('Target (Masker+Signal)')
%     
%     figure
%     subplot(2,2,1)
%     plot(targ_masker)
%     title('Target: Masker Only')
%     ylabel('Amplitude')
%     hold on
%     subplot(2,2,2)
%     spec(targ_masker,80,def.samplerate);
%     title('Target: Masker Only')
%     subplot(2,2,3)
%     plot(signal)
%     title('Target: Signal Only')
%     ylabel('Amplitude')
%     subplot(2,2,4)
%     spec(signal,80,def.samplerate);
%     title('Target: Signal Only')
%     
%     figure
%     subplot(1,2,1)
%     plot(ref)
%     title('Reference')
%     hold on
%     subplot(1,2,2)
%     spec(ref,80,def.samplerate);
%     
%     N = length(ref); % total number of samples 
%     N=2^nextpow2(N); % transform length of ref to be the next power of 2. fft will zero pad the end of the ref stimulus
%     xdft = fft(ref,N); % discrete FFT of ref
%     xdft = xdft(1:N/2+1);
%     psdx = (1/(def.samplerate*N)) * abs(xdft).^2;
%     psdx(2:end-1) = 2*psdx(2:end-1);
%     freq = 0:def.samplerate/N:def.samplerate/2;
%     
%     figure
%     plot(freq,10*log10(psdx))
%     grid on
%     title('Periodogram Using FFT: Reference')
%     xlabel('Frequency (Hz)')
%     ylabel('Power/Frequency (dB/Hz)')
%     
% end

presig = zeros(def.presiglen,2);
postsig = zeros(def.postsiglen,2);
pausesig = zeros(def.pauselen,2);

% make required fields in work
work.signal = [targ_masker_sig' targ_masker_sig' ref' ref'];	% left = right (diotic) first two columns holds the test signal (left right)
work.presig = presig;											% must contain the presignal
work.postsig = postsig;											% must contain the postsignal
work.pausesig = pausesig;										% must contain the pausesignal

% eof
