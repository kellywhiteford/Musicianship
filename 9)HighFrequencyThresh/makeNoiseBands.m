function allNoiseBands = makeNoiseBands(noiseDur, silenceDur, rampDur, freqSeq, bandWidth, noiseScale, fs)
% Create an array of narrow band noise bursts
%
% Requires hann function to work.
%
% Inputs:
% - noiseDur - noise burst duration, in msec
% - silenceDur - silence after the noise, in msec
% - rampDur - duration of raised cosyne ramps added to the beginning and end of noise, in msec
% - freqSeq - vector of center frequencies of noise. in Hz
% - bandWidth - noise bandwidth, in Hz
% - noiseScale - scaling to be applied to the noise, in dB
% - fs - sampling rate of the noise bursts, in Hz

% addpath('M:\Experiments\scripts\');

if nargin < 1
    noiseDur = 500; % msec
end

if nargin < 2
    silenceDur = 200; % msec
end

if nargin < 3
   rampDur = 20 ;% msec
end

if nargin < 4
    lowF = 2000; % lowest noise band center frequency
    highF = 22000; % highest noise band center frequency
    stepSize = 1/12; % smallest frequency stepsize
    totOct = log2(highF/lowF); % number of octaves spanned from lowest to highest band
    nSteps = ceil(totOct./stepSize); % round up to the nearest step above the desired highest frequency
    octSeq =  [0:nSteps].*stepSize;
    freqSeq = lowF.*(2.^octSeq);
end

if nargin < 5
    bandWidth = 320; % hz
end

if nargin < 6
    noiseScale = -20;
end

if nargin < 7
    fs = 48000;
end

linScale = 10^(noiseScale./20); % convert the dB scaling to linear

nsmp_on = noiseDur.*fs./1000; %length(y)
nsmp_off = silenceDur.*fs./1000;

fftpts = nsmp_on;

allNoiseBands = zeros(length(freqSeq),nsmp_on+nsmp_off);

for centerF = 1:length(freqSeq)
    
    currCenterF = freqSeq(centerF);
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
    noiseBin = real(noiseBin(1:nsmp_on));
    noiseBin = hann(noiseBin, rampDur, fs);
    
    allNoiseBands(centerF,:) = [linScale.*(noiseBin./rms(noiseBin)) zeros(1,nsmp_off)]; % scale to desired level 
   
end
