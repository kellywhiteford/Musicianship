%
%   FILE NAME       : EEG_da_RME_CMU.m
%   DESCRIPTION     : This script runs 1 block of 3000 trials for /da/ in
%                     multi-talker babble (based on Parbery-Clark et al.,
%                     2009, JNeuro) on an RME Sound Card with the playrec
%                     utility. Make sure to run this task twice, so that
%                     two blocks of 3000 trials are collected (6000 trials
%                     total).
%
%RETURNED ITEMS
%
%   n/a             : ACQ computer should be recording (32+2ch and CMS/DRL,
%                     Speed Mode 7)
%
%(C) Timothy Nolan Jr., Auditory Neuroscience Lab, CMU
%    Inspired in part by Oxenham (UMN) and Perrachione (BU) Labs
%    Last Edit 06.21.2019
%

%% INITIALIZATION

close all;
clear all; %#ok<CLALL>
clc;

beep off;

fprintf('\nStarting Musicianship ''da'' protocol.\nDid you load ''Musicianship_pt2.tmws'' in Totalmix FX? ')
key_resp = input('[y/n]: ','s');
if strcmpi(key_resp,'y')
    fprintf('Great! Did you change the audio playback device?\nThe small speaker in the bottom right should read ''Analog (9+10) (RME UFX+ USB 3.0)''. ')
    key_resp = input('[y/n]: ','s');
    if strcmpi(key_resp,'y')
        fprintf('\nGreat! Initializing playrec...\n');
    else
        error('Please select the correct playback device, ''Analog (9+10) (RME UFX+ USB 3.0)''');
    end
else
    error('Please load the ''Musisicianship_pt2.tmws'' file in Totalmix FX.');
end

% 1. Initialize RME sound card with playrec utility

Devices=playrec('getDevices');
if isempty(Devices)
    error ('There are no devices available using the selected host APIs.');
else
    i=1;
    while ~strcmp(Devices(i).name,'ASIO MADIface USB') && i <= length(Devices)
        i=i+1;
    end
    fs = Devices(i).defaultSampleRate;
end
playrec('init',fs,i-1,-1,24,-1)
fprintf('Success! Connected to %s.\n', Devices(i).name);
stimchanList=[1,2,14];

% 2. Load stimuli and modify as needed for later code
signal = audioread('C:\Users\Lab User\Desktop\Experiments\TimN\Musicianship\11)EEG_da\DA_cmu.wav');
rms_sig = rms(signal);

%Calculate 72dB reference intensity
t=0:1/fs:length(signal)/fs-1/fs;
ref_signal = 0.2*sqrt(2)*db2mag(80-107.7)*sin(2*pi*1000*t)';
rms_ref = rms(ref_signal);

%Scale signal intensity - the RMS
signal = (rms_ref/rms_sig)*signal;

noise = audioread('C:\Users\Lab User\Desktop\Experiments\TimN\Musicianship\11)EEG_da\6-talkerbabble.wav');
rms_noise = rms(noise);
noise = ((rms_ref*db2mag(-10))/rms_noise)*noise;


% 3. Set any additional parameters
nTrials = 3000;
polarity = repmat([0,1],1,nTrials/2)*2-1;
polarity = polarity(randperm(length(polarity)));

SignalLen = length(signal);
ISILen = ceil(0.083*fs);
TriggerLen=ceil(0.010*fs);
TrialLen = SignalLen + ISILen;
TrialTime = TrialLen/fs;
NoiseLen = length(noise);
cont_noise = repmat(noise,ceil(nTrials/(NoiseLen/TrialLen)),1);

stim = cell(3000,1);
trig = cell(3000,1);
last_index=0;
for i = 1:nTrials
    stim{i} = [polarity(i)*signal;zeros(ISILen,1)] + cont_noise(last_index+1:last_index+TrialLen,1);
    trig{i} = [trignum2scalar(polarity(i)+3)*ones(TriggerLen,1);zeros(TrialLen-TriggerLen,1)];
    last_index=last_index+TrialLen;
end

% 4. Reminds experimenter of checklist before experiment begins.
disp('Is the AD-Box switch turned to 7?')
key_resp = input('[y/n]: ','s');
if strcmpi(key_resp,'y')
    disp('Great! Are you currently saving the data in BioSemi?')
else
    error('Set the AD-Box switch to 7 so the sample rate is correct (16 kHz)!')
end

key_resp = input('[y/n]: ','s');
if strcmpi(key_resp,'y')
    disp('Excellent! The experiment will begin now.')
else
    error('Make sure you start acquiring data before you present the stimuli!')
end

%% Play!

playrec('play',[zeros(0.1*fs,1),zeros(0.1*fs,1),[trignum2scalar(254)*ones(0.01*fs,1);zeros(0.09*fs,1)]],stimchanList);% sends "254" trigger to BioSemi (start)
buffer = zeros(length(stim{1}*nTrials),3);
for i = 1:nTrials
    playrec('play',[stim{i},stim{i},trig{i}],stimchanList);% adds next chunk to queue
end
playrec('play',[zeros(0.1*fs,1),zeros(0.1*fs,1),[ones(0.01*fs,1);zeros(0.09*fs,1)]],stimchanList);% sends "255" trigger to BioSemi (stop)
 for i = 10:10:nTrials-10
     while(playrec('isFinished', i) == 0); end
     fprintf('Playing /da/ %d of %d...\n',i,nTrials);
 end
fprintf('Done!\n');