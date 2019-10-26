function errMsg = FrequencyTuning(subId, expSite)

%   Inputs:
%       - subId: participant ID number, entered as a string
%       - expSite: name of the experimental site where data is collected,
%       entered as a string
%
%   Outputs:
%       - errMsg: error message, in case the code crashes. Otherwise empty
%       vector
%
%   Description:
%       The function implements bekesy tracking procedure from Sek et al. (2005).
%       Pure tone pulses at fixed level are embeded in narrow-band noise that
%       slowly sweeps either up from a low center frequency or down from a high center frequency.
%
%       If spacebar is held down, noise level increases. Otherwise it decreases.
%       To exit the procedure prematurely, press the escape button or close
%       the GUI.
%
%       At the conclusion of the procedure, level of the noise sweep at
%       each tracking reversal point is plotted as a function of center
%       frequency of the noise band at that reversal. Additionally, points
%       where maximum or minumum allowed levels are reached are also plotted.
%
%       The function utilizes functions included in the Psychophysics Toolbox
%       (e.g. PsychPortAudio, GetSecs, etc). Psychtoolbox is therefore a
%       pre-requisite for this to work.
%
%       This version of the code has been customized for a multi-site
%       auditory study. As such, it requires additional data files w/
%       participant thresholds to work.
%
%   History:
%   3/27/2019 Initial version finished (by Juraj Mesik)
%   6/12/2019 A bunch of small bug fixes and tweaks [not very informative changelog entry :)] (by JM)


errMsg = [];
finished = 0; % track if code successfully reached the end
addPTB = 1; % if 1, then assume PTB isn't in the path and add it
removePTBatEnd = 1; % if 1, then remove PTB at the end of the session
rng('default'); % In case legacy rng algorithm was used before running this script, need to reset rng settings before being able to call rng('shuffle')
randState = rng('shuffle'); % re-seed rng so that start direction is random

ptbPath = 'C:\toolbox\Psychtoolbox';

if addPTB
    if ~exist(ptbPath,'dir')
        fprintf(['\n\nCouldn''t find the specified PsychToolBox directory: %s.\n'...
            'Please adjust the ptbPath variable in the %s function to point to your PTB directory.\n'], ptbPath, mfilename);
        return;
    end
    
    addpath(genpath(ptbPath));
    PsychtoolboxPostInstallRoutine(1); % run a slightly edited version of the PTB post-install routine
end

% Keyboard settings
KbName('UnifyKeyNames')
upKey = KbName('space'); % when this key pressed, level goes down. Otherwise it goes up.
quitKey =  KbName('escape');
ListenChar(1); % Prevent keystrokes from typing into code during the experiment

nRuns = 3;
generateNewSweep = 1;
debugMode = 0;

if ~exist('data','dir')
    mkdir('data')
end

datFile = ['.' filesep 'data' filesep subId '_' expSite '.mat'];
if exist(datFile,'file')
    load(datFile); % load existing data for this participant
    currRun = currRun+1;
    
    if currRun > nRuns
        fprintf('\nParticipant %s has already completed all %d runs.\n', subId, nRuns);
        ListenChar(0);
        error('Data collection for this task is already complete for this participant.')
    end
else
    allResults = {};
    currRun = 1;
    
    firstRun = randsample(2,1);
    runOrd = [firstRun mod((firstRun)+[1:nRuns-1],2)+1];
end

currDir = runOrd(currRun);

% Load subject threshold
whereThresh = ['..' filesep '2)AbsProbe' filesep 'Output']; % path to absolute threshold results
fp = [whereThresh filesep 'AbsProbe_'  subId '_' expSite '.dat'];

if ~exist(fp,'file')
    fprintf('\nData file for subject %s not found. Check if subject ID and site name were entered correctly\n',subId);
    error('Threshold file for the participant not found, see message above')
end

formatSpec = '%f%f%f%f%s%[^\n\r]';
delimiter = ' ';
startRow = 2;
fileID = fopen(fp ,'r'); % Open the text file for reading

dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n'); % Import the data
fclose(fileID);

allThresh = dataArray{3}; % extract just the thresholds
allStd = dataArray{4};  % extract standard deviations of reversals for each threshold

if length(allThresh) ~= 3
    fprintf('\nDetection threshold results for subject %s contain %d thresholds, rather than exactly 3. \nPlease double check if you are using correct subject ID or if you finished collecting threshold data\n',subId, length(allThresh));
    error('Not enough thresholds for the participant found, see message above')
end

if any((allThresh(2:end) == 0.1234567) & (allStd(2:end) == 0))
    fprintf('\nAt least one of the detection thresholds for subject %s is invalid -- the staircase did not converge. Make sure to finish collecting their data\n',subId, length(allThresh));
    error('Invalid threshold values, see message above')
end


thresh = mean(allThresh(2:end)); % compute mean detection thresholds from run 2 on

% Noise settings
loLevel = -10; % lowest allowed level of the nose sweep
hiLevel = 85; % highest allowed level of the noise sweep
startLevel = 50; % start tracking with this level
levRange = hiLevel-loLevel;
dBPerSec = 2;
rms1Level = 102.7; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
maxLevel = rms1Level - 3; % level in dB SPL produced by a full-scale deflection sinusoid (peak amplitude of 1 in Matlab)

bufferDur = 125; % msec, duration of each segment of noise

dBPerSegment = (dBPerSec*bufferDur./1000);
allRampStartdB = loLevel+ [0:dBPerSegment:levRange];
allRampEnddB = allRampStartdB+dBPerSegment;
totalRampSegments = length(allRampStartdB);
nLevels = totalRampSegments;

startIdx = find(allRampStartdB==startLevel); % index of the start level


% Noise generation
if generateNewSweep % if we want to generate a sweep from scratch...
    
    clipCheck = 1;
    
    while clipCheck
        [y,fs, startF, endF, noiseBWidth, freqSeq] = makeNoiseSweep(currDir);
        y_scaled = 10^((allRampStartdB(end)-rms1Level)/20).*(y./rms(y)); % %% scale the noise to the max allowed rms1Level
        nClipSamples = sum(abs(y_scaled)>1);
        
        if nClipSamples == 0 % no clipping? Great!
            clipCheck = 0; % exit the loop
            fprintf('\nNoise sweep successfully generated. No clipping even at the max noise level (%1.1fdB, maxVal = %1.2f)...\n',allRampStartdB(end), max(abs(y_scaled)));
        else
            fprintf('\nDetected %d clipped samples, generating a new sequence...',nClipSamples);
        end
        
    end
    
    y = [zeros(size(y))' y'];
    
else % if we want to load-pre-generated downward sweep...
    [y,fs] = audioread('SwNoise_1414.2_Hz_6062.9_Hz_Band=320_Hz_SR=48000_Hz_Dur=240s_REV_Ear=R_24B.wav'); % for starters, let's use Sek's noise; sweep down in right ear
    % For figuring out where in the sequence we are
    nsmp = length(y); %length(y)
    startF = 1414.2;
    endF = 6062.9;
    noiseBWidth = 320; % Hz
    totOct = log2(endF/startF);
    octSeq = linspace(0,totOct, nsmp);
    freqSeq = startF.*(2.^octSeq); % for each sample, this tells us what's the center frequency of the noise
    
    if currDir == 1 % currDir 1 is upward sweep, currDir 2 is downward sweep
        y = flipud(y);
    end
    
    if currDir == 2 % if downward sweep, then the center frequency sequence above needs to be flipped to go from high to low
        freqSeq = fliplr(freqSeq);
    end
    
end

y_right = y(:,2)./(rms(y(:,2))); % Forces noise to have an rms=1
y = [y(:,1), y_right]; % Left ear has silence, right ear is scaled to have rms=1

% Can uncomment these lines to plot spectrogram of the noise:
% freqBins = [50:50:6500];
% figure; spectrogram(y(:,2),fs.*0.05,[],freqBins,fs,'yaxis');
% hold on; plot(linspace(0,4,nsmp), fliplr(freqSeq)/1000, 'k')

bufferDur_smp = round(fs*(bufferDur./1000));

rampTemplate = linspace(0,dBPerSegment, bufferDur_smp)';
steadyTemplate = zeros(size(rampTemplate));

% Tone settings
nPulsesQuiet = 5; % number of tone pulses in quiet before the noise begins.
toneFreq = 4000; % Hz
toneDur = 500; % ms
rampDur = 20; % ms, raised cosine
ISI = 200; % ms, gap between tone pulses
totalDur = toneDur + ISI;
toneLevel_dB = thresh+20; % 20 dB above the detection threshold


toneLevel_lin = 10^((toneLevel_dB-maxLevel)/20);
toneDur_smp = (toneDur/1000)*fs; % duration in samples
ISI_smp     = (ISI/1000)*fs;
rampDur_smp = round(fs*(rampDur./1000));
flatDur_smp = toneDur_smp-2*rampDur_smp; % samples of the flat portion of sound
totalDur_smp = toneDur_smp + ISI_smp;

% Create the tone
taxis = toneFreq*2*pi/fs.*[1:toneDur_smp];
stim = toneLevel_lin*sin(taxis); % create the stimulus and scale to the right

fullStim = [hann(stim,rampDur,fs) zeros(1,ISI_smp)]; % full stimulus: ramped tone followed by silence
fullStim = [zeros(size(fullStim)); fullStim]; % left ear = quiet, right ear = sound

% Just for the very beginning, use raised cosine ramp for noise onset
onsetRamp = sin(linspace(0,pi./2,rampDur_smp)).^2; % squared sinusoidal ramp up
onsetRamp = [onsetRamp ones(1,bufferDur_smp-rampDur_smp)]';

% Apply the onset and offset ramp to the noise
y(1:bufferDur_smp,2) = y(1:bufferDur_smp,2).*onsetRamp;
y(end-bufferDur_smp+1:end,2) = y(end-bufferDur_smp+1:end,2).*flipud(onsetRamp);

% Crappy user interface (it's fake since none of the data is actually collected through it)
f = figure('Name', 'Frequency tuning dialog', 'Units', 'normalized', 'Position', [0.3 0.3 0.4 0.4]);
set(f,'MenuBar', 'none', 'ToolBar', 'none'); % remove toolbars that are normally on matlab figures
callBackFxn = @guiExitCallback;
f.DeleteFcn = callBackFxn; % set a callback function that aborts the experiment if GUI is closed

p = uipanel(f,'Position', [0.3 0.3 0.4 0.4]); % create a uipanel
c = uicontrol(p, 'Style', 'PushButton', 'Units', 'normalized','Position', [0.1 0.1 0.8 0.8]); % create a button

% For push buttons, one way to make the text multi-line is to use html
% formatting ( see http://undocumentedmatlab.com/blog/html-support-in-matlab-uicomponents/)
c.String = 'Press any key to begin';

uicontrol(c) % bring the button into focus
drawnow; % force updating of the figure graphics before moving on

proceed =0;

while ~proceed
    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
    drawnow;
    if keyIsDown
        proceed = 1;
    elseif proceed == -1
        removePTB;
        fprintf('\n\nTuning measurement aborted through closing the GUI\n\n');
        return;
    end
    
end

c.String = '<html>&nbsp;&nbsp;&nbsp;&nbsp;Press and hold the space<br>&nbsp;&nbsp;&nbsp;&nbsp;bar whenever you hear the<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pulsing tone';
% [outtext, newpos] = textwrap(t,{'Press and hold the space bar whenever you hear the pulsing tone'}); % wrap the text, if needed
% set(t,'String',outtext,'Position',newpos) % put the actual text up in location determined by textwrap
drawnow; % force updating of the figure graphics before moving on

try
    
    %% PsychPortAudio setup
    % Initialize Psychtoolbox Audio
    InitializePsychSound(1) % The "1" input tells PTB to push as hard is it can to get really low latency
    
    whichSoundDevice = []; % usually [] is good enough but sometimes need to specify non-default device
    % If you need to find the correct sound device to use, type the
    % following in the command window: 
    % devices = PsychPortAudio('GetDevices');
    % Then type: devices.DeviceName
    % Find the index of the device name you would like to use, and set
    % whichSoundDevice (line 275) to be equal to that index number.
    
    % Open a connection to the sound card
    pamaster = PsychPortAudio('Open',whichSoundDevice,...     % create a handle to the [default soundcard] This should default to the only ASIO card.
        9,...                                 % Sound Playback mode (1 = sound only, 2 = record only, 3 = duplex mode,  add 8 to the initial value -> master mode for using subordinate devices
        1,...                                 % Latency minimization (0 = none, 1 = try for low latency with reliable playback, 2 = full audio device control, 3 full controll with agressive settings, 4 full controll with agressive settings and fail if device won't meet requirements)
        fs,...                                % Sampling Frequency
        [2],...                               % Number of channels for [Out In]
        [],[],...                             % Default buffersize and suggested latency
        []);                                  % Specific track numbers for [Output; Input]
    
    paNoise = PsychPortAudio('OpenSlave', pamaster,1, 2);
    paTone = PsychPortAudio('OpenSlave', pamaster,1, 2);
    
    PsychPortAudio('UseSchedule', paNoise, 1);
    PsychPortAudio('UseSchedule', paTone, 1);
    
    idx = 1:bufferDur_smp;
    levelRamp = 10.^((allRampStartdB(startIdx)-rms1Level+rampTemplate)./20);
    bufferdata = [y(idx,1) y(idx,2).*levelRamp]';
    
    currBuffer = PsychPortAudio('CreateBuffer', paNoise, bufferdata);
    toneBuffer = PsychPortAudio('CreateBuffer', paTone, fullStim);
    
    [success, freeslots] = PsychPortAudio('AddToSchedule', paTone, toneBuffer);
    PsychPortAudio('Start', pamaster);
    PsychPortAudio('Start', paTone, 1, 0, 1);
    statusTone = PsychPortAudio('GetStatus', paTone);
    
    for pulse = 1:nPulsesQuiet-1
        WaitSecs(0.9*(totalDur./1000));
        statusTone = PsychPortAudio('GetStatus', paTone);
        %         fprintf('\nCurrent sample position: %d', statusTone.ElapsedOutSamples)
        [success_patone, freeslots_patone] = PsychPortAudio('AddToSchedule', paTone, toneBuffer);
    end
    %     totalDur_smp
    
    % Start the noise
    [success, freeslots] = PsychPortAudio('AddToSchedule', paNoise, currBuffer);
    PsychPortAudio('Start', paNoise,1,0,1); % wait for start since this is the first one
    statusNoise = PsychPortAudio('GetStatus', paNoise);
    
    % Set up some loop-related variables
    allResp = [freqSeq(1) allRampStartdB(startIdx)];
    saveRes = 1;
    keepGoing = 1;
    currDir = 1;
    [currLev, prevLev] = deal(startIdx);
    tStart = GetSecs;
    noiseScheduleCounter = 0;
    toneScheduleCounter = 0;
    loopCtr = 0;
    while keepGoing
        loopCtr = loopCtr + 1;
        
        bufferIdx = mod(loopCtr-1, 3)+1;
        
        if loopCtr > 2 % this is for deleting old buffers that finished playing already (assuming that buffer from 2 loops ago should be done by now)
            deleteIdx =  mod(bufferIdx, 3)+1;
            result = PsychPortAudio('DeleteBuffer', currBuffer(deleteIdx));
        end
        
        % Current position in the noise sweep
        idx = idx+bufferDur_smp;
        
        if ~ismember(currLev,[1, nLevels])
            
            levelRamp = 10.^((allRampStartdB(currLev)-rms1Level+(currDir.*rampTemplate))./20);
        else
            levelRamp =  10.^((allRampStartdB(currLev)-rms1Level+steadyTemplate)./20);
        end
        
        % Look out for the end of the sweep
        if idx(end) > size(y,1)
            idx = idx(idx<=size(y,1));

            levelRamp = levelRamp(1:length(idx)); % adjust which samples of the ramp are used to match the remaining # of samples in the noise, and apply offset ramp
            
            if isempty(idx)
                keepGoing = 0;
                break;
            end
        end
        
        bufferdata = [y(idx,1) y(idx,2).*levelRamp]'; % take the next chunk of noise and ramp it up/down in level

        
        currBuffer(bufferIdx) = PsychPortAudio('CreateBuffer', paNoise, bufferdata);
        
        if ~statusNoise.Active
            PsychPortAudio('UseSchedule', paNoise, 1);
        end
        
        [success, freeslots] = PsychPortAudio('AddToSchedule', paNoise, currBuffer(bufferIdx),1); % upward sweep
        
        if ~statusNoise.Active
            PsychPortAudio('Start', paNoise, 1, 0, 1);
            noiseScheduleCounter = noiseScheduleCounter + 1;
        end
        
        if mod(statusTone.ElapsedOutSamples,totalDur_smp) > (0.8*totalDur_smp)
            if ~statusTone.Active
                PsychPortAudio('UseSchedule', paTone, 1);
            end
            
            [success_patone, freeslots_patone] = PsychPortAudio('AddToSchedule', paTone, toneBuffer);
            
            if ~statusTone.Active
                PsychPortAudio('Start', paTone, 1, 0, 1);
                toneScheduleCounter = toneScheduleCounter + 1;
            end
        end
        
        
        [keyIsDown, secs, keyCode] = KbCheck;
        
        prevDir = currDir;
        prevLev = currLev;
        if keyIsDown && any([keyCode(upKey) keyCode(quitKey)])
            
            if keyCode(upKey)
                currDir = 1;
            elseif  keyCode(quitKey) % if want to quite, break out of the loop
                keepGoing = 0;
                saveRes = 0;
            end
        else
            currDir = -1;
        end
        
        if prevDir ~=currDir % if direction is reversing, we need to record the response
            currLev = currLev; % on reversal, we assure smooth waveform transition by playing the same level, just in reverse
            isMinMax = ismember(currLev,[1, nLevels]); % if we are just leaving max or min, then, in revLevel variable we need to correct for the fact that there is no level ramp
            freqIdx = idx(1) + round((idx(end)-idx(1))./2); % compute the index of the center of the current audio segment
            revLevel = allRampStartdB(currLev)+(~isMinMax*0.5*prevDir*dBPerSegment); % The level at reversal is the start level at previous plus half of an increment/decrement based on the previous sweep direction (half b/c we take the midpoint frequency index as the freq at reversal)
            
            allResp(end+1,:) = [freqSeq(freqIdx) revLevel]; 
        else % if the level direction is same as previous loop
            currLev = currLev + currDir; % and adjust level by 1
        end
        
        currLev = min(currLev, nLevels); % prevent going out of range
        currLev = max(currLev, 1);
        
        % Special-case scenario where max/min level is reached -> record as if it was a response
        if (prevDir ==currDir) && ~isempty(intersect(currLev, [1 nLevels])) && (diff([prevLev currLev]) ~= 0) % if max or min is hit/diverged from, also collect the data point
            freqIdx = idx(1) + round((idx(end)-idx(1))./2); % compute the index of the center of the current audio segment
            allResp(end+1,:) = [freqSeq(freqIdx) allRampStartdB(currLev)];
        end

        statusNoise = PsychPortAudio('GetStatus', paNoise);
        statusTone = PsychPortAudio('GetStatus', paTone);
        
        drawnow; % update the figure - this allows matlab to catch if it was closed and execute the callback
        
        %         fprintf('\n%1.4f', (GetSecs-tStart)./(loopCtr*bufferDur/1000 - 0.15*(bufferDur/1000)))
        %         fprintf('\n%1.4f', (GetSecs-tStart-(loopCtr-1)*bufferDur/1000)./(loopCtr*bufferDur/1000))
        while (GetSecs-tStart) < (loopCtr*bufferDur/1000 - 0.25*(bufferDur/1000))
            % Stall the code so that the loop runs roughly in sync w/
            % buffers being added into the schedule
        end
        
        if debugMode
            fprintf('\nFree slots noise = %d, Status = %d',freeslots, statusNoise.Active);
            fprintf('\nFree slots tone= %d, Status = %d',freeslots_patone, statusTone.Active);
        end
        
    end
    fprintf('\nDebug info:\nNoise schedule restarted %d times.\nTone schedule restarted %d times', noiseScheduleCounter, toneScheduleCounter)
    fprintf('\n')
    allResp(end+1,:) = [freqSeq(end) allRampStartdB(currLev)]; % record the end frequency + level
    
    if c.isvalid
        c.String = '<html>&nbsp;&nbsp;&nbsp;&nbsp;Finishing up...'; % one last update to the GUI
        drawnow; % force updating of the figure graphics before moving on
    end
    
    figure;
    plot(allResp(:,1), allResp(:,2),'k');
    hold on
    plot(allResp(:,1), allResp(:,2),'ro');
    set(gca,'XLim',[1000, 6100], 'XScale', 'log'); % 'XScale', 'log'
    xlabel('Noise center freq. (Hz)')
    ylabel('Level (dB SPL)')
    xlim([min([startF endF]) max([startF endF])])
    
    WaitSecs(bufferDur_smp./fs); % Stall the code for a bit so that we don't accidentally shut off the audio while some of the final samples are still playing
    ListenChar(0); % re-enable the keyboard
    PsychPortAudio('Close')
    
    % Save the behavioral data + a bunch of other experimental details
    allResults{currRun} = allResp; % behavioral data
    allNoiseStartF(currRun) = startF; % start frequency of noise
    allNoiseEndF(currRun) = endF; % end frequency of noise
    allNoiseDur(currRun) = length(freqSeq)./fs; % Duration of noise in seconds
    allNoiseBWidth(currRun) = noiseBWidth; % bandwidth of noise in Hz
    allSampleRate(currRun) = fs; % samplerate 
%     allNoiseFreqSeq{currRun} = freqSeq; % instantaneous center frequency of noise
    allNoiseMaxLev(currRun) = hiLevel; % max allowed level of noise in dB
    allProbeFreq(currRun) = toneFreq; % probe tone frequency
    allProbeSL(currRun) = toneLevel_dB-thresh; % probe tone level in dB SL
    allProbeSPL(currRun) = toneLevel_dB; % probe tone level in dB SL
    allRandState{currRun} = randState; % random number seed
    
    if saveRes
        save(datFile, 'currRun', 'runOrd', 'allResults', 'allRandState', 'allNoiseStartF', 'allNoiseEndF', 'allNoiseDur', 'allNoiseBWidth', 'allSampleRate', 'allNoiseMaxLev', 'allProbeFreq', 'allProbeSL', 'allProbeSPL')
    end
    
    finished = 1;
    if ishandle(f)
        close(f); % close the UI figure
    end
    
    removePTB
    
catch errMsg
    ListenChar(0);
    PsychPortAudio('Close')
    removePTB
    
end

    function guiExitCallback(~,~)
        
        if exist('loopCtr', 'var')
            if finished
                fprintf('\n\nRun %d out of %d succesfully finished! Please let the experimenter know.\n\n', currRun, nRuns)
            else
                keepGoing = 0;
                saveRes = 0;
                fprintf('\n\nTuning measurement aborted through closing the GUI\n\n')
            end
        else % if quiting out the gui before the sound actually starts
            proceed = -1;
        end
        
    end

    function removePTB
        
        if removePTBatEnd
            warning('off')
            rmpath(genpath(ptbPath));
            res = savepath;
            warning('on')
            
            if res
                warning('Could not save the paths after removing PTB! PTB may remain in path in future MATLAB sessions.')
            end
        end
        
    end

end

