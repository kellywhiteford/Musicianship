% Parameters for SpeechEnergeticHINT

% filenames
parameters.listnamepre = '.\HINT_normal_Practice\HINT_'; % In your audio files, what comes before the list number?
parameters.listnamepost = '_'; % In your audio files, what comes between the list number and the sentence number?
parameters.fileending = '.wav'; % In your audio files, what comes after the sentence number?
parameters.textmat = 'HINT_Practice_Text.mat'; % For auto-scoring -- where is sentence text located?
parameters.textcell = 'HINT_Practice_Text'; % For auto-scoring -- what is name of the cell within the .mat file?

% Lists and sentences
parameters.NumListsAvailable = 1; % How many lists are there to choose from?
parameters.NumSentencesAvailable = 10; % How many sentences are there to choose from (per list)?
parameters.SentencesPerList = 10; % How many sentences should be played from each list?

% Presentation level
rms1level = 100; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
parameters.MaxLevel = rms1level; % Level (dB SPL) for a stimulus with an RMS=1
parameters.TargetLevel = 65; % Target presentation level (dB SPL)

% Signal-to-noise ratio
parameters.SNR = -3;

% Conditions
parameters.NumConditions = length(parameters.SNR); % How many conditions? 
parameters.NumRepetitions = 1; % How many lists per condition? e.g. 5 conditions X 2 repetitions needs 10 lists.
