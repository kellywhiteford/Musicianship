% This function runs 1 block of 2400 trials for /mi3/ (based on Wong et
% al., 2007). Make sure to run this task twice, so that two blocks of 2400
% trials are collected (4800 trials total).

% modified by Sung-Joo Lim
% last edited June 5 2019


function EEG_mi3_RME_BU

clc % Clears the command window
clear all

%% SET UP

pauseEEG_Trigger = 14;
startEEG_Trigger = 15;


trigVals = bitshift(15,8)+ 255;
startEEG = trigVals/(2^31);

trigVals = bitshift(14,8)+ 255;
pauseEEG = trigVals/(2^31);


polarity1 = (bitshift(2,8)+255)/(2^31);
polarity2 = (bitshift(4,8)+255)/(2^31);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
filepath = 'C:\Users\Public\Documents\Experiments\NSF_Musicianship\Musicianship\12)EEG_mi3\';


%% RME audio set up

samplerate = 44100; % This should be changed at each cite to reflect the sampling rate of the stimulus presentation system.

% initialize RME
fs = samplerate;


% 1. Initialize RME sound card with playrec utility
fprintf('Initializing playrec...\n');
Devices=playrec('getDevices');
if isempty(Devices)
    error ('There are no devices available using the selected host APIs.');
else
    i=1;
    while ~strcmp(Devices(i).name,'ASIO Fireface USB') && i <= length(Devices)
        i=i+1;
    end
    fs = Devices(i).defaultSampleRate;
end
playrec('init',fs,i-1,-1,12,-1,100000)
fprintf('Success! Connected to %s.\n', Devices(i).name);
stimchanList=[1,2,12];




%% STIMULI and PARAM set up

% Priority(2); %MATLAB Process Priority: 0="Normal", 1="High", 2="Real-Time"

% Change rms1level to correspond to the level of a stimulus with an RMS=1
rms1level = 120.8; %107; % dB, RMS=1, MSP Booth 2, 0-dB TDT Gain Adjustment
level = 70; % level of mi3 stimulus in dB SPL -- keep it!!

duration = 278.5; %% ms
SampleLen = round(duration/1000*samplerate); % presentation length in samples
t = (0:SampleLen - 1)'/samplerate;

stimulus = audioread([filepath, 'mi3_resampled_44k.wav']); % If samplerate changes, da stimulus needs to be updated
stimulus = stimulus/rms(stimulus); % Forces stimuli to have rms=1
StimScaler = 10^((level-rms1level)/20);  % Scaler relative to calibrated level.
signal = StimScaler*stimulus; % Scale stimulus



%% TRIAL set up 

% 3. Set any additional parameters

nTrials = 2400; %THIS SHOULD BE 2400 FOR EXPERIMENT. 
polarity = repmat([0,1],1,nTrials/2)*2-1;
polarity = polarity(randperm(length(polarity)));

SignalLen = length(signal);
ISILen = ceil(0.083*fs);
TriggerLen=ceil(0.010*fs);
TrialLen = SignalLen + ISILen;
TrialTime = TrialLen/fs;

stim = cell(nTrials,1);
trig = cell(nTrials,1);
last_index=0;

for i = 1:nTrials
    stim{i} = [polarity(i)*signal;zeros(ISILen,1)];
    if(polarity(i) == 1)
        trig{i} = [polarity1*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)];
    else
        trig{i} = [polarity2*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)];
    end
    % trig{i} = [(polarity(i)+81)*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)]/1025;
    last_index=last_index+TrialLen;
end


% add zeros at the end 
stim{nTrials} = [stim{nTrials}; zeros(1*fs,1)];
trig{nTrials} = [trig{nTrials}; zeros(1*fs,1)];



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



%% PLAY



playrec('play',[zeros(0.5*fs,1),zeros(0.5*fs,1),[startEEG*ones(0.01*fs,1);zeros(0.49*fs,1)]],stimchanList);% sends "start" trigger to BioSemi (start)

pause(1);

for i = 1:nTrials
    playrec('play',[stim{i},stim{i},trig{i}],stimchanList);% adds next chunk to queue
end



for i = 10:10:nTrials-10
    while(playrec('isFinished', i) == 0); end
    fprintf('Playing /da/ %d of %d...\n',i,nTrials);
end

fprintf('Done!\n');


playrec('play',[zeros(0.1*fs,1),zeros(0.1*fs,1),[pauseEEG*ones(0.01*fs,1);zeros(0.09*fs,1)]],stimchanList);% sends "end" trigger to BioSemi (stop)




