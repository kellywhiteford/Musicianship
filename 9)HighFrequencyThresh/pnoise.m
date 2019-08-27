% pnoise(duration_ms,l_co[Hz],h_co[Hz],[Level(dB)],[circular(0/1)],[SAMPLERATE])
%  Generates Pink noise in the spectral domain
% with specified duration, cut-off frequency
% filter cutoff slope
% and level (dB rms re 1. Default = -20).
%   If circular is selected (1), then the buffer is periodic.
% Otherwise (0) the fft is done on a power-of-2 vector and
% then truncated to the desired length (faster).

function noise = pnoise(duration_ms,lco,hco,level,circular,SAMPLERATE)

if nargin < 3
   help pnoise
   return
elseif nargin < 4
  level = -20; circular = 0; SAMPLERATE = 48000;
elseif nargin < 5
   circular = 0; SAMPLERATE = 48000;
elseif nargin < 6
   SAMPLERATE = 48000;
end

dur_smp = round(duration_ms * SAMPLERATE / 1000);
bandwidth = hco - lco;
max_bw = SAMPLERATE / 2;

if (circular==1)
   fftpts = dur_smp;
else
   fftpts = findnextpow2(dur_smp);
end

binfactor = fftpts / SAMPLERATE;
LPbin = round(lco*binfactor) + 1;
HPbin = round(hco*binfactor) + 1;

pink_weight = [1:fftpts] .* binfactor;

a = zeros(1,fftpts);
b = a;

a(LPbin:HPbin) = randn(1,HPbin-LPbin+1);
b(LPbin:HPbin) = randn(1,HPbin-LPbin+1);
fspec = a + 1i*b;

pspec = fspec ./ sqrt(pink_weight);

noise = ifft(pspec);
noise = real(noise(1:dur_smp));
%normalize level
noise = noise ./ rms(noise) .* 10^(level/20);
