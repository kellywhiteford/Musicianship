function [y,fs, startF, endF, bandWidth, freqSeq] = makeNoiseSweep(sweepDir)
% Create a narrowband noise stimulus with its center freqeuency slowly sweeping over time.
% Requires hann function to work.
% Inputs:
% - sweepDir: 1 = upward, 2 = downward

% Sek et al did this by synthsizing the noise using inverse FFT:
% They break up the whole time course of the sweep into a bunch of 64 ms "time
% frames" and for each time frame they define its frequency content using 2048
% discrete components between 0 and 16kHz. Each frame's passband frequency
% components are set to 1 (they say "unity") while the remaining
% components are set to 0. Phases are randomized. Resulting segments are
% windowed w/ a hanning window and the segments had 32 msec (i.e. 50%)
% overlap (so, for their 4 min stim, they used 7.5k segments/frames)


defaultDir = 2; % by default make downward sweep

if ~exist('sweepDir','var')
    sweepDir = defaultDir;
end

% clear;
sweepDur = 240; % seconds
fs = 48000;
nsmp = sweepDur.*fs; %length(y)
startF = 1414.2;
endF = 6062.9;
binSize = 64; % msec
% binSize_smp = binSize*fs/1000;
binSize_smp = 2048;
binOverlap = 32; % msec
% binOverlap_smp = binOverlap*fs/1000;
binOverlap_smp = 0.5*binSize_smp;


totOct = log2(endF/startF);
octSeq = linspace(0,totOct, nsmp);
freqSeq = startF.*(2.^octSeq); % for each sample, this tells us what's the center frequency of the noise

freqSeqBin = freqSeq(binOverlap_smp:binOverlap_smp:end);
nBins = length(freqSeqBin);

% wbandNoise = gnoise(sweepDur*1000,20,10000,-20,0,fs); % create wide-band noise b/w 20 and 10000 Hz

bandWidth = 320; % hz
max_bw = fs/2; % hz
nFreqBins = binSize_smp; %fs*binSize/1000;
freqRange = [0 fs/2]; % the upper frequency should be the nyquist limit for current samplerate, I think
freqSpace = round(linspace(freqRange(1),freqRange(2),nFreqBins));

fftpts = nFreqBins;

fullSweep = zeros(1,nsmp);
sweepIdx = 1:binSize_smp;
for bin = 1:nBins
    currCenterF = freqSeqBin(bin);
    currCutoffLo = currCenterF-0.5*bandWidth;
    currCutoffHi = currCenterF+0.5*bandWidth;
    
    % This is from gnoise:
    binfactor = fftpts / fs;
    fftIdxLo = round(currCutoffLo*binfactor) + 1;
    fftIdxHi = round(currCutoffHi*binfactor) + 1;
    
    % precreate amplitude and phase components
    a = zeros(1,fftpts);
    b = a;
    
    ang = 2*pi*rand(1,fftIdxHi-fftIdxLo+1); % phase for all components
    
    a(fftIdxLo:fftIdxHi) =  cos(ang);
    b(fftIdxLo:fftIdxHi) =  sin(ang); % randn(1,fftIdxHi-fftIdxLo+1)
    spec = a + 1i*b;
    
    noiseBin = ifft(spec);
    noiseBin = real(noiseBin(1:binSize_smp));
    noiseBin = hann(noiseBin, 1000*binOverlap_smp/fs, fs);
    
    if bin > 1
        sweepIdx = sweepIdx+binOverlap_smp;
    end
    
    if bin ~= nBins
        fullSweep(sweepIdx) = fullSweep(sweepIdx) + noiseBin;
    else % for the final bin, we can only use its first half
        sweepIdx = sweepIdx(sweepIdx<=length(fullSweep));
        fullSweep(sweepIdx) = fullSweep(sweepIdx) + noiseBin(1:length(sweepIdx));
    end
end
y = fullSweep./max(abs(fullSweep)); % normalize

if sweepDir == 2 % if downward sweep, need to flip a few variables around
    y = fliplr(y);  % flip the sweeep itself
    freqSeq = fliplr(freqSeq); % flip the vector of center frequencies
    
    %    freqEndPts = [startF endF]; % and flip the sta
    startF = freqSeq(1); %freqEndPts(2);
    endF = freqSeq(end); %freqEndPts(1);
end