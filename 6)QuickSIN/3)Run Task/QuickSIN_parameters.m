% Parameters for QuickSIN

% filenames
parameters.listnamepre = '..\Audio\QuickSIN_'; % In your audio files, what comes before the list number?
parameters.listnamepost = '_'; % In your audio files, what comes between the list number and the sentence number?
parameters.fileending = '.wav'; % In your audio files, what comes after the sentence number?
parameters.textmat = 'QuickSIN_Text.mat'; % For auto-scoring -- where is sentence text located?
parameters.textcell = 'QuickSIN_Text'; % For auto-scoring -- what is name of the cell within the .mat file?

% Lists and sentences
parameters.NumListsAvailable = 12; % How many lists are there to choose from?  
parameters.NumSentencesAvailable = 6; % How many sentences are there to choose from (per list)?
parameters.SentencesPerList = 6; % How many sentences should be played from each list?

% Presentation level
rms1level = 104; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
parameters.MaxLevel =  rms1level; % Level (dB SPL) for a stimulus with an RMS=1
parameters.OverallLevel = 70; % Overall presentation level (dB SPL) 

% Conditions
parameters.NumConditions = length(parameters.OverallLevel); % How many conditions? 
parameters.NumRepetitions = 2; % How many lists per condition? e.g. 5 conditions X 2 repetitions needs 10 lists.
