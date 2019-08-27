%hann(input_signal, ramp_duration [ms], [SAMPLERATE]) - Hanning windows stimulus
function output = hann(input,ramp_dur_ms,SAMPLERATE)

if nargin < 3
   SAMPLERATE = 48000;
end
   
stim_dur_smp = length(input);
ramp_dur_smp = floor(ramp_dur_ms * SAMPLERATE / 1000); %round changed to floor on 01.04.07
if (stim_dur_smp < 2*ramp_dur_smp)
 error('Ramps cannot be longer than the stimulus duration')
end

win = hanning(ramp_dur_smp*2)';

%First part of windowed stimulus
init_win = win(1:ramp_dur_smp) .* input(1:ramp_dur_smp);

%Middle part (steady state)
if (stim_dur_smp > ramp_dur_smp)
  steady_win = input(ramp_dur_smp+1:stim_dur_smp-ramp_dur_smp);
end

%Final part of windowed stimulus
end_win = win(ramp_dur_smp+1:ramp_dur_smp*2) .* input(stim_dur_smp-ramp_dur_smp+1:stim_dur_smp);

%Put the three parts together
output = [init_win steady_win end_win];

