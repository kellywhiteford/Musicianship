%tone(frequency,duration_ms,[phase[0..1]],[SAMPLERATE])
%Generates sinusoid with parameters as specified
%Default phase is 0.

function signal = tone(frequency,duration_ms,phase,SAMPLERATE)

if nargin < 2
   help tone
   return
elseif nargin < 3
   phase = 0; SAMPLERATE = 48000;
elseif nargin < 4
   SAMPLERATE = 48000;
end

dur_smp = duration_ms*SAMPLERATE/1000;
t_int_ms = 1000/SAMPLERATE;
phase_rads = 2*pi*phase;

x = [0:t_int_ms:(duration_ms-t_int_ms)];
signal = sin(2*pi*frequency*x/1000 + phase_rads);
