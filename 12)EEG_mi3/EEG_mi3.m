% This function runs 1 block of 2400 trials for /mi3/ (based on Wong et
% al., 2007). Make sure to run this task twice, so that two blocks of 2400
% trials are collected (4800 trials total).

function EEG_mi3

clc % Clears the command window

%% Reminds experimenter of checklist before experiment begins.
disp('Did you already complete two blocks of the "EEG_da" experiment?')
key_resp = input('Type yes or no: ','s');
if strcmpi(key_resp,'YES')
    disp('Great! Are you currently saving the data in BioSemi?')
else
    error('Two blocks of the "EEG_da" experiment must be run before you can begin the "EEG_mi3" experiment.')
end

key_resp = input('Type yes or no: ','s');
if strcmpi(key_resp,'YES')
    disp('Excellent! The experiment will begin now.')
else
    error('Make sure you start acquiring data before you present the stimuli!')
end

%% Begins experiment
Priority(2); %MATLAB Process Priority: 0="Normal", 1="High", 2="Real-Time"

samplerate = 24414; % This should be changed at each cite to reflect the sampling rate of the stimulus presentation system.

% Change rms1level to correspond to the level of a stimulus with an RMS=1
rms1level = 107; % dB, RMS=1, MSP Booth 2, 0-dB TDT Gain Adjustment

level = 70; % level of mi3 stimulus in dB SPL 

duration = 278.5; %% ms
SampleLen = round(duration/1000*samplerate); % presentation length in samples
t = (0:SampleLen - 1)'/samplerate;

nTrials = 2400; %THIS SHOULD BE 2400 FOR EXPERIMENT. 

polarity = (randperm(nTrials) > round(nTrials/2));
ISI_s = 0.083; % inter-stimulus interval (s)

stimulus = audioread('mi3_resampled.wav'); % If samplerate changes, da stimulus needs to be updated
stimulus = stimulus/rms(stimulus); % Forces stimuli to have rms=1
StimScaler = 10^((level-rms1level)/20);  % Scaler relative to calibrated level.
mi3 = StimScaler*stimulus; % Scale stimulus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
currentpath = cd;
% Now that stimuli and experiment parameters are loaded, let's get going
TDT.use_keyboard = true;
TDT.onsetdel = 0;
TDT.Type = 'RP2';
TDT.fs = samplerate;
TDT.circuit_dir = [cd '\'];

TDT.noiseAmp = 0; % 0 FOR NO BACKGROUND NOISE

% Initialize sound and display
TDT = AudioController('init', TDT); % populate TDT structure

nextPlayTime = GetSecs + 1;

waveData = [mi3 mi3]; % /mi3/ should be in both ears
waitduration = size(waveData,1)/TDT.fs;

endTime = GetSecs;
for trialNum = 1:nTrials
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Load sound stimuli into TDT  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if polarity(trialNum) == 0
        AudioController('loadBuffer', TDT, waveData);
        TDT.playbackStamp = 1;
    elseif polarity(trialNum) == 1
        AudioController('loadBuffer', TDT, -waveData);
        TDT.playbackStamp = 2;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Cue Frame and audio playback start  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    WaitSecs('UntilTime', nextPlayTime);
    
    presTimesActual = AudioController('start', TDT);
    ActualISI = round(1000*(GetSecs - endTime));
    fprintf(1,'Trial Number: %d/%d  (ISI=%dms) \n',trialNum,nTrials,ActualISI); % print trial number and ISI to command window
    
    WaitSecs(waitduration); % Wait while the sound plays
    endTime = GetSecs;
    nextPlayTime = presTimesActual + waitduration + ISI_s;
    pause(0.01);
    
    AudioController('stopReset', TDT); % Stop the sound and reset the cursor
end
cleanupError(TDT);
