% This function runs 1 block of 2400 trials for /mi3/ (based on Wong et
% al., 2007). Make sure to run this task twice, so that two blocks of 2400
% trials are collected (4800 trials total).

function EEG_mi3_uwo_final(subjID, block, uniID)

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
 fs = filesep;
 samplerate = 48000; % This should be changed at each cite to reflect the sampling rate of the stimulus presentation system.

%Initializes Psychtoolbox
 PsychDefaultSetup(2); 
 InitializePsychSound;
%  pahandle = PsychPortAudio('Open',ptb_findaudiodevice('ASIO Fireface'),[],2,samplerate,3); % calls to souncard

  pamaster = PsychPortAudio('Open',ptb_findaudiodevice('ASIO Fireface'),1+8,3, samplerate, 3); % calls to sound card
  PsychPortAudio('Start', pamaster, 0, 0, 1); % create master slave; 
  pasound1 = PsychPortAudio('OpenSlave', pamaster, [],3);
  pasound2 = PsychPortAudio('OpenSlave', pamaster, [],3);
  



% set stimulus parameters  
%  rms1level = 123.35; % dB, RMS=1
 rms1level = 93.45; 
 level = 70; % level of mi3 stimulus in dB SPL 
%  duration = 275.8; %% ms
 duration = 278.5; 
 ISI_s = 0.083; % inter-stimulus interval (s)
 SOA= ISI_s + duration/1000;
 nTrials = 2400; %THIS SHOULD BE 2400 FOR EXPERIMENT. 
 polarity = (randperm(nTrials) > round(nTrials/2));
 
 
% load and modify da 
 stimulus = audioread('mi3_resampled_uwo.wav'); % If samplerate changes, da stimulus needs to be updated
 stimulus = stimulus/rms(stimulus); % Forces stimuli to have rms=1
 StimScaler = 10^((level-rms1level)/20);  % Scaler relative to calibrated level.
 mi3 = StimScaler*stimulus; % Scale stimulus
 waveData = [mi3 mi3]; % /mi3/ should be in both ears
 waveDataR= waveData*-1; % reverses polarity
 
 
% add trigger to da file
 waveData(:,3) = 0;
 waveData(1:(samplerate*0.001),3)=1; %Adds trigger to sound file*

% same for polarity reversed sound
 waveDataR(:,3) = 0;
 waveDataR(1:(samplerate*0.001),3)=1;  %Adds trigger to sound file*

% gets ISI list for mi3
 currentTime = GetSecs;
 onsets = currentTime + 1 + (0:SOA: (nTrials)*SOA-SOA);
 waitduration = size(waveData,1)/samplerate; % updated TDT.fs to samplerate
 endTime = GetSecs;   

  
  % set up independent channel info
 pabuffer1 = PsychPortAudio('CreateBuffer', [], waveData');
 pabuffer2 = PsychPortAudio('CreateBuffer', [], waveDataR');
  
 PsychPortAudio('UseSchedule', pasound1, 1, 3);
 PsychPortAudio('UseSchedule', pasound2, 1, 3);

 PsychPortAudio('AddToSchedule', pasound1, pabuffer1, [], [], [], [], 1);
 PsychPortAudio('AddToSchedule', pasound2, pabuffer2, [], [], [], [], 1);
 
  
% play mi3s   
for ii = 1:nTrials
    
    if polarity(ii) == 0
            tStart2 = PsychPortAudio('Start', pasound1,1,onsets(ii),1);
            stamp(ii,:)= 1;
    else
            tStart2 = PsychPortAudio('Start', pasound2,1,onsets(ii),1);
            stamp(ii,:)= 2;
    end

   
    
    WaitSecs(waitduration);
    

    ActualISI = round(1000*(GetSecs - endTime));
    fprintf(1,'Trial Number: %d/%d  (ISI=%dms) \n',ii,nTrials,ActualISI);
    endTime = GetSecs;
    
end

 
 PsychPortAudio('Close', pamaster);
 events=[];
 events.polarity = stamp;
 save(['logs' fs 'mi3_' subjID '_' uniID '_b' num2str(block) '.mat'], '-struct','events');
      
end
% cleanupError(TDT);
