% Save parameters for SpeechInformational here.

Fs = 44100;  % Sampling Frequency
rms1Level = 107.3; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
targ_lev = 65; % desired starting level of target in dB SPL
mask_lev = 52; % desired level of (individual) masker in dB SPL; this means the overall masker level is mask_lev+3 dB with two maskers
max_lev = 75; % maximum possible level of the target 
max_trials = 100; % maximum possible number of trials per run
steps_db = [6 3]; % intital step size and step size for the first three reversals (1), and step size for all following reversals (2)
rev_count = 0; % counts the total number of reversal points
trial_count = 1; % counts the trial number
trial_data = []; % stores responses for each trial (All correct: 1; Any incorrect: 0)
rev_level = [];
target_lev_data = [targ_lev]; % stores trial-by-trial value of target level
prev_trial = 'initial';
direction = prev_trial;

