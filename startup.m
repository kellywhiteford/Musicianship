cd C:\Users\Public\Musicianship

restoredefaultpath
matlabrc  
addpath(genpath('C:\Users\Public\Musicianship\afc'))
addpath('C:\Users\Public\Musicianship\TopOfPath')

format compact
close all
clear

home

fprintf('DO NOT PROCEED until:\n  1. Mix 1 has been confirmed (lit up and not flashing) in RME TOTALMIX.\n  2. The values above "Main" in the bottom row read -10.0 (all other values should be 0.0).\n\nThen Close TotalMix.\n\n')

fprintf('You can access TotalMix from the system tray icon in the lower right.\n\n')

% Call Psychtoolbox-3 specific startup function:
if exist('PsychStartup'), PsychStartup; end;

