%MBSMBD_set - setup function of experiment 'MBSMBD' -
%
% This function is called by afc_main when starting
% the experiment 'MBSMBD'. It defines elements
% of the structure 'setup'. The elements of 'setup' are used 
% by the function 'MBSMBD_user.m'.
 


function MBSMBD_set

global work
global set
global def

rms1level = 100; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
set.maxlevel = rms1level - 3; % level in dB SPL produced by a full-scale deflection sinusoid (peak amplitude of 1 in Matlab)
set.burst_dur = 60; %burst duration in ms
set.ramp_ms = 10;

FileName=['../4)Abs/Output/Abs_' work.vpname '_' work.condition '.dat'];
data = load(FileName); % absolute thresholds for signal-burst sequence
avgAbs = mean(data(2:3,2)); %average absolute thresholds for signal-burst sequence for runs 2 and 3 (first run is practice)

set.sigLevel = avgAbs + 20; % signal-burst sequence level fixed at 20 dB SL 

set.sigLevelAtten = set.sigLevel - set.maxlevel;

max_maskerLevel = 80 + 10*log10(8); % maximum allowable overall masker level in dB SPL 
def.minvar = set.sigLevel - max_maskerLevel; % minimum SNR possible based on the masker level never exceeding max_maskerLevel; overrides the value assigned in MBSMBD_cfg.m

