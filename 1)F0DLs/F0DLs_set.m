
% This function is called by afc_main
% 

function F0DLs_set

global work
global set

rms1level = 105.5; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1

set.max_level = rms1level; 
set.level = work.exppar2-set.max_level; % indicates the amount that the stimuli will be attenuated by so that the level matches value set in work.exppar2 (see "exppar2" in "F0DLs_cfg.m")
set.ramp_ms = 20; % ramp duration (ms)
set.freq = 100; % F0
set.dur_ms = 200; % Stimulus duration (ms) tone. Each interval contains a sequence of 4 tones.
