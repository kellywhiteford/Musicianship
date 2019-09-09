% This function runs 1 block of 3000 trials for /da/ in multi-talker babble 
% (based on Parbery-Clark et al., 2009, JNeuro). Make sure to run this task 
% twice, so that two blocks of 3000 trials are collected (6000 trials 
% total).

function EEG_da_uwo_final(subjID, block, uniID)

% clc % Clears the command window

%% Reminds experimenter of checklist before experiment begins.
disp('Is the AD-Box switch turned to 7?')
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

%% Begins experiment
  fs = filesep;
  samplerate = 48000; % This should be changed at each cite to reflect the sampling rate of the stimulus presentation system.
 
% initializes psychtoolbox
  PsychDefaultSetup(2); 
  InitializePsychSound;
  
% calls to sound card; sets channels for independent control of sound files
  pamaster = PsychPortAudio('Open',ptb_findaudiodevice('ASIO Fireface'),1+8,3, samplerate, 3); % calls to sound card
  PsychPortAudio('Start', pamaster, 0, 0, 1); % create master slave; 
  pasound1 = PsychPortAudio('OpenSlave', pamaster, [],3);
  pasound2 = PsychPortAudio('OpenSlave', pamaster, [],3);
  pasound3 = PsychPortAudio('OpenSlave', pamaster, [],3);

  
% set stimulus parameters  
%   rms1level = 123.35; % dB level of a stimulus with an RMS=1
  rms1level = 93.45;
  level = 80; % dB level for da
  noiseLevel = level - 10; % level of noise in dB SPL
  duration = .170; %% ms
  ISI_s = 0.083;
  SOA= ISI_s + duration;
  nTrials = 3000; %THIS SHOULD BE 3000 FOR EXPERIMENT
  polarity = (randperm(nTrials) > round(nTrials/2));
 
 % load and modify da 
  stimulus = audioread('DA_resampled48kHz.wav'); % Loads /da/ stimulus
  stimulus = stimulus/rms(stimulus); % Forces stimuli to have rms=1
  StimScaler = 10^((level-rms1level)/20);  % Scaler relative to calibrated level.
  da = StimScaler*stimulus; % Scale stimulus
  
  waveData = [da da]; % /da/ should be in both ears
  waveDataR= waveData*-1; % reverses polarity
  
 % load and modify noise 
  TempNoise = audioread('babble_resampled48kHz.wav');
  NoiseScaler = 10^((noiseLevel-rms1level)/20);  % Scaler relative to calibrated level.
  NoiseRMSMod = TempNoise/rms(TempNoise); % VI changed so Babble truly has an rms=1 here.
  FinalNoise =  NoiseRMSMod*NoiseScaler;
  FinalNoise=[FinalNoise FinalNoise];
  FinalNoise(:,3)=0; % no trigger for noise

 % add trigger to da file
  waveData(:,3) = 0;
  waveData(1:(samplerate*0.001),3)=1; %Adds trigger to sound file*

 % same for polarity reversed sound
  waveDataR(:,3) = 0;
  waveDataR(1:(samplerate*0.001),3)=1;  %Adds trigger to sound file*

  waitduration = size(waveData,1)/samplerate; % updated TDT.fs to samplerate


% assigns sounds to these names
  sound1 = FinalNoise';
  sound2 = waveData';
  sound3 = waveDataR';

% set up independent channel info
  pabuffer1 = PsychPortAudio('CreateBuffer', [], sound1);
  pabuffer2 = PsychPortAudio('CreateBuffer', [], sound2);
  pabuffer3 = PsychPortAudio('CreateBuffer', [], sound3);

  PsychPortAudio('UseSchedule', pasound1, 1, 3);
  PsychPortAudio('UseSchedule', pasound2, 1, 3);
  PsychPortAudio('UseSchedule', pasound3, 1, 3);

  PsychPortAudio('AddToSchedule', pasound1, pabuffer1, 0, [], [], [], 1);
  PsychPortAudio('AddToSchedule', pasound2, pabuffer2, [], [], [], [], 1);
  PsychPortAudio('AddToSchedule', pasound3, pabuffer3, [], [], [], [], 1);

% starts playing noise
  tStart = PsychPortAudio('Start', pasound1, 0);

% gets ISI list for das
  currentTime = GetSecs;
  onsets = currentTime + 1 + (0:SOA: (nTrials)*SOA-SOA);
  endTime = GetSecs;   
% play das 
for ii = 1:nTrials
    
     if polarity(ii) == 0
		tStart2 = PsychPortAudio('Start', pasound2,1,onsets(ii),1);
        stamp(ii,:)= 1;
    elseif polarity(ii) == 1
        tStart2 = PsychPortAudio('Start', pasound3,1,onsets(ii),1);
        stamp(ii,:)= 2;
    end
    

    WaitSecs(waitduration);
    
    ActualISI = round(1000*(GetSecs - endTime));
    fprintf(1,'Trial Number: %d/%d  (ISI=%dms) \n',ii,nTrials,ActualISI);
    endTime = GetSecs;

       
end
    PsychPortAudio('Stop', pasound1);
    PsychPortAudio('Close', pamaster);
    
    events=[];
    events.polarity = stamp;
    save(['logs' fs 'da_' subjID '_' uniID '_b' num2str(block) '.mat'], '-struct','events');

end

