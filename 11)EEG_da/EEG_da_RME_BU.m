% This function runs 1 block of 3000 trials for /da/ in multi-talker babble 
% (based on Parbery-Clark et al., 2009, JNeuro). Make sure to run this task 
% twice, so that two blocks of 3000 trials are collected (6000 trials 
% total).


% modified by Sung-Joo Lim
% last edited June 5 2019

%%

function EEG_da_RME_BU

clear all
clc 


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
filepath = 'C:\Users\Public\Documents\Experiments\NSF_Musicianship\Musicianship\11)EEG_da\';


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
rms1level = 120.8; % dB, RMS=1, MSP Booth 2, 0-dB TDT Gain Adjustment

level = 80; % level of da stimulus in dB SPL 
noiseLevel = level - 10; % level of noise in dB SPL

duration = 170; %% ms
SampleLen = round(duration/1000*samplerate); % presentation length in samples
t = (0:SampleLen - 1)'/samplerate;

stimulus = audioread([filepath,'DAbase_44k.wav']); % SJ edited upsampled: Loads /da/ stimulus 
stimulus = stimulus/rms(stimulus); % Forces stimuli to have rms=1
StimScaler = 10^((level-rms1level)/20);  % Scaler relative to calibrated level.
signal = StimScaler*stimulus; % Scale stimulus

noise = audioread([filepath, '6-talker_2M-4F.wav']); % original sound file
NoiseScaler = 10^((noiseLevel-rms1level)/20);  % Scaler relative to calibrated level.
noise = NoiseScaler * noise;  


%% TRIAL set up 

% 3. Set any additional parameters

nTrials = 3000; % nTrials should be 3000 for EEG da
polarity = repmat([0,1],1,nTrials/2)*2-1;
polarity = polarity(randperm(length(polarity)));

SignalLen = length(signal);
ISILen = ceil(0.083*fs);
TriggerLen=ceil(0.010*fs);
TrialLen = SignalLen + ISILen;
TrialTime = TrialLen/fs;
NoiseLen = length(noise);
cont_noise = repmat(noise,ceil(nTrials/(NoiseLen/TrialLen)),1);

stim = cell(nTrials,1);
trig = cell(nTrials,1);
last_index=0;

for i = 1:nTrials
    stim{i} = [polarity(i)*signal;zeros(ISILen,1)] + cont_noise(last_index+1:last_index+TrialLen,1);
    if(polarity(i) == 1)
        trig{i} = [polarity1*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)];
    else
        trig{i} = [polarity2*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)];
    end
    % trig{i} = [(polarity(i)+4)*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)]/1025;
    last_index=last_index+TrialLen;
end


% add zeros at the end 
stim{nTrials} = [stim{nTrials}; zeros(1*fs,1)];
trig{nTrials} = [trig{nTrials}; zeros(1*fs,1)];




%% Reminds experimenter of checklist before experiment begins.

disp('Is the AD-Box SPEED-MODE switch turned to 7?')
key_resp = input('Type yes or no: ','s');
if strcmpi(key_resp,'YES')
    disp('Great! Are you currently saving the data in BioSemi?')
else
    error('Set the AD-Box switch to 7 so the sample rate is correct (16 kHz)!')
end


key_resp = input('Type yes or no: ','s');
if strcmpi(key_resp,'YES')
    disp('Excellent! The experiment will begin now.')
else
    error('Make sure you start acquiring data before you present the stimuli!')
end



%% PLAY

% START RECORDING
playrec('play',[zeros(0.5*fs,1),zeros(0.5*fs,1),[startEEG*ones(0.01*fs,1);zeros(0.49*fs,1)]],stimchanList);% sends "start" trigger to BioSemi (start)

pause(1);

% PLAY STIM
for i = 1:nTrials
    playrec('play',[stim{i},stim{i},trig{i}],stimchanList);% adds next chunk to queue
end



for i = 10:10:nTrials-10
    while(playrec('isFinished', i) == 0); end
    fprintf('Playing /da/ %d of %d...\n',i,nTrials);
end

fprintf('Done!\n');


% STOP RECORDING
playrec('play',[zeros(0.1*fs,1),zeros(0.1*fs,1),[pauseEEG*ones(0.01*fs,1);zeros(0.09*fs,1)]],stimchanList);% sends "end" trigger to BioSemi (stop)


