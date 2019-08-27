function freqspec = spec_klw(stimulus,dynrange,SAMPLERATE,clr,xRange)
%Same as spec.m but the default color is red and unspecified limits for the
%range of the x-axis.

%spec_klw.m Plots normalized log power spectrum of stimulus
% and returns overall level (dB re: rms value of 1).
%Usage: level = spec(stimulus,[dynamic range (dB)],[SAMPLERATE])
%e.g. to show all spectral values 100dB or less below the peak:
%  spec(stimulus,100);
% Default values: Dyn Range: 80 dB, Samplerate: 32000 Hz, clr: 'r', xRange: [].

if nargin < 3
   SAMPLERATE = 32000;
   clr = 'r';
   xRange = [];
elseif nargin < 4
    clr = 'r';
    xRange = [];
elseif nargin < 5
    xRange = [];
end


if exist('dynrange')
else dynrange = 80;
end

linmin = 10.^(-dynrange/10);

xcomp = fft(stimulus);
xmag = ((real(xcomp)).^2) + ((imag(xcomp)).^2);
%level = 10 .* log10(mean(stimulus.^2));

xmag = xmag / max(xmag);
xmag = max(xmag,linmin);

logmag = 10 .* log10(xmag);

binfreq = [1:length(stimulus)];
binfreq = (binfreq - 1)*SAMPLERATE/length(stimulus);
freqscale = binfreq(1:length(stimulus)/2);
levelscale = logmag(1:length(freqscale));
%figure(1)
plot(freqscale,levelscale,clr);
set(gca,'xscale','log') % plots x-axis in log scale
if ~isempty(xRange)
    xlim(xRange)
end
freqspec = [freqscale;levelscale];