%AbsProbe_set - setup function of experiment 'AbsProbe' -
%
% This function is called by afc_main when starting
% the experiment 'Abs'. It defines elements
% of the structure 'setup'. The elements of 'setup' are used 
% by the function 'Abs_user.m'.

function AbsProbe_set

global set

%SIGNAL IS ALWAYS PRESENTED TO THE RIGHT EAR ONLY (SEE USER FILE)

rms1level = 100; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
set.maxlevel = rms1level - 3; % level in dB SPL produced by a full-scale deflection sinusoid (peak amplitude of 1 in Matlab)

set.dur_ms = 500; % probe duration in ms
set.ramp_ms = 20;


