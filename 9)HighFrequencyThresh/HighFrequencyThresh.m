function errMsg = HighFrequencyThresh(subId, expSite)
% errMsg = HighFrequencyThresh(subId, expSite)
%   Inputs:
%       - subId: participant ID number, entered as a string
%       - expSite: name of the experimental site where data is collected,
%       entered as a string
%
%   Outputs:
%       - errMsg: error message, in case the code crashes. Otherwise empty
%       vector
%{
  Description:
      The function implements bekesy-style tracking procedure based on
      Rieke et al. (2017) to estimate extended high frequency hearing
      thresholds.
      
      Narrow-band noise pulses on/off in one ear at a fixed level, while
      the other ear is presented with continuous wide-band pink noise 
      to prevent-cross talk.

      Participant presses space bar to indicate if they hear the pulsing noise,
      which leads to gradual, continuous upward shift in the noise-band center
      frequency (i.e. towards the upper limit of hearing). Once participant
      can no longer hear the pulsing noise, they release the spacebar, which
      reverses the center frequency drift direction (back towards the more
      audible range). This procedure continues for a pre-specified number of reversals.

      At the conclusion of the procedure, center frequency of the noise is
      plotted as a function of time. An average of last several (usually 6-8)
      reversals is used to estimate the high frequency hearing threshold,
      which is plotted on the graph as a dashed horizontal line.

      The function utilizes functions included in the Psychophysics Toolbox
      (e.g. PsychPortAudio, GetSecs, etc). Psychtoolbox is therefore a
      pre-requisite for this to work.


  History:
  6/7/2019 Initial version finished (by Juraj Mesik)

%}

errMsg = [];
finished = 0; % track if code successfully reached the end
addPTB = 1; % if 1, then assume PTB isn't in the path and add it
removePTBatEnd = 1; % if 1, then remove PTB at the end of the session
autoPilotMode = 1; % if 1, code keeps running to next run
autoPilotOnRun = 2; % only engage autopilot once this run is reached
makeFigsOnAutopilot = 0; % if 1, keep making figures during the autopilot portion of the experiment

timeOutTimeLimit = 60; % time out the experiment there is no reversal point in this many seconds (counter resets on each reversal)
timeOutThresh = 0.12345678; % if experiment times out, use this as the threshold placeholder
timeOutSD = 0; % if experiment times out, use this as the standard deviation placeholder

rng('default'); % In case legacy rng algorithm was used before running this script, need to reset rng settings before being able to call rng('shuffle')
randState = rng('shuffle'); % re-seed rng so that start direction is random

% ptbPath = 'C:\toolbox\Psychtoolbox';
ptbPath = 'C:\toolbox\Psychtoolbox-3-master\Psychtoolbox';

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
upKey = KbName('space'); % when this key pressed, center frequency goes up. Otherwise it goes up.
quitKey =  KbName('escape');
ListenChar(1); % Prevent keystrokes from typing into code during the experiment

nRuns = 4;
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
    
    %     firstRun = randsample(2,1);
    %     runOrd = [firstRun mod([1:nRuns-1],2)+1];
    runOrd = [];
    for rep = 1:nRuns/2
        runOrd = [runOrd randperm(2)];
    end
    
end


% Basics
rms1Level = 104; % Enter location-specific calibration level: The headphone output level of a stimulus with an RMS of 1
fs = 48000; % samplerate of the sound system

% Staircase settings
stepSizes = [2 1]; % these step sizes indicate by how much to change the noise band index on each step of the staircase
reversalsPerStepSize = [2 8]; % number or reversals per each step size in stepSizes
useReversals = 6; % last this many reversals are averaged for the figure at the end
maxRev = sum(reversalsPerStepSize); % maximum number of reversals

% Noise settings
targetEarLevel = 80; % noise level in target ear

% Target noise band settings
lowF = 2000; % lowest noise band center frequency
highF = 22000; % highest noise band center frequency
startFreq = 4000; % Hz. First noise band center is closest to this frequency
bandWidth = 320; % noise band bandwidth, in Hz
stepSize = 1/12; % smallest frequency stepsize
totOct = log2(highF/lowF); % number of octaves spanned from lowest to highest band
nSteps = ceil(totOct./stepSize); % round up to the nearest step above the desired highest frequency
octSeq =  [0:nSteps]'.*stepSize;
freqSeq = lowF.*(2.^octSeq); % for each band, this tells us what's the center frequency of the noise

nPulsesQuiet = 4; % number of noise pulses before the task begins (ideally should be a multiple of nPulsesPerStep)
nPulsesPerStep = 2; % number of pulses before staircase changes frequency
bandDur = 500; % noise burst duration, in msec
ISI = 200; % gap between tone pulses, in msec
rampDur = 20; % raised cosine, in msec
totalDur = bandDur + ISI; % total duration between adjacent noise bands steps, in msec
totalDur_smp = totalDur*fs./1000; % totalDur, but in samples

nFreqBands = length(freqSeq); % total number of frequency bands
startFreqIdx = abs(freqSeq-startFreq);
startFreqIdx = find(startFreqIdx == min(startFreqIdx)); % find the index of frequency closest to the

% % Can uncomment these lines to plot spectrogram of the noise:
% freqBins = [100:100:24000];
% concatNoise = allNoiseBands';
% concatNoise = concatNoise(:);
% figure; spectrogram(concatNoise,fs.*0.025,[],freqBins,fs,'yaxis');
% hold on; plot(linspace(0,4,nsmp), fliplr(freqSeq)/1000, 'k')


% Contralateral masking noise parameters
noiseDur = 120; % sec (this should be a guess of the upper limit of noise duration)
noiseBuffer_smp = nPulsesPerStep*totalDur_smp;

lowCutoff = 4000; % freqSeq(1)
highCutoff = freqSeq(end); % freqSeq(end)
totOct_noise = log2(highCutoff/lowCutoff);

contralatEarLevel = 50; % desired pink noise level per 1/3 octave band
contralatEarLevel = contralatEarLevel + 10*log10(totOct_noise*3); % level adjustment to actually make the above level for 1/3 octave bands; using 10log10 because we're in intensity units


% Crappy user interface (it's fake since none of the data is actually collected through it)
f = figure('Name', 'High frequency dialog', 'Units', 'normalized', 'Position', [0.3 0.3 0.4 0.4]);
set(f,'MenuBar', 'none', 'ToolBar', 'none'); % remove toolbars that are normally on matlab figures
callBackFxn = @guiExitCallback;
f.DeleteFcn = callBackFxn; % set a callback function that aborts the experiment if GUI is closed

p = uipanel(f,'Position', [0.3 0.3 0.4 0.4]); % create a uipanel
c = uicontrol(p, 'Style', 'PushButton', 'Units', 'normalized','Position', [0.1 0.1 0.8 0.8]); % create a button


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
    % whichSoundDevice (line 251) to be equal to that index number.
    
    % Open a connection to the sound card
    pamaster = PsychPortAudio('Open',whichSoundDevice,...     % create a handle to the [default soundcard] This should default to the only ASIO card.
        9,...                                 % Sound Playback mode (1 = sound only, 2 = record only, 3 = duplex mode,  add 8 to the initial value -> master mode for using subordinate devices
        4,...                                 % Latency minimization (0 = none, 1 = try for low latency with reliable playback, 2 = full audio device control, 3 full controll with agressive settings, 4 full controll with agressive settings and fail if device won't meet requirements)
        fs,...                                % Sampling Frequency
        [2],...                               % Number of channels for [Out In]
        [],[],...                             % Default buffersize and suggested latency
        []);                                  % Specific track numbers for [Output; Input]
    
    paTargEar = PsychPortAudio('OpenSlave', pamaster,1, 2);
    paMaskEar = PsychPortAudio('OpenSlave', pamaster,1, 2);
    
    PsychPortAudio('Start', pamaster); % start the master device
    
    newRun = true;
    while newRun
        % Target noise generation
        clipCheck = 1;
        
        while clipCheck
            allNoiseBands = makeNoiseBands(bandDur, ISI, rampDur, freqSeq, bandWidth, targetEarLevel-rms1Level, fs);
            
            nClipSamples = sum(abs(allNoiseBands(:))>1);
            
            if nClipSamples == 0 % no clipping? Great!
                clipCheck = 0; % exit the loop
                fprintf('\nNoise bands successfully generated. No clipping detected.');
            else
                fprintf('\nDetected %d clipped samples, generating a new sequence...',nClipSamples);
            end
            
        end
        
        % Generate the pink noise
        clipCheck = 1;
        while clipCheck
            noiseStim =  pnoise(noiseDur*1000,lowCutoff,highCutoff,contralatEarLevel-rms1Level,0,fs);
            
            nClipSamples = sum(abs(noiseStim(:))>1);
            
            if nClipSamples == 0 % no clipping? Great!
                clipCheck = 0; % exit the loop
                fprintf('\nNoise bands successfully generated. No clipping detected.');
            else
                fprintf('\nDetected %d clipped samples, generating a new sequence...',nClipSamples);
            end
        end
        
        %% Wait for subject to start the experiment:
        % For push buttons, one way to make the text multi-line is to use html
        % formatting ( see http://undocumentedmatlab.com/blog/html-support-in-matlab-uicomponents/)
        c.String = 'Press any key to begin the next run';
        
        uicontrol(c) % bring the button into focus
        drawnow; % force updating of the figure graphics before moving on
        
        proceed =0;
        
        while ~proceed
            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
            drawnow;
            if keyIsDown
                proceed = 1;
            elseif proceed == -1
                error(sprintf('\n\nExtended high frequency threshold measurement aborted through closing the GUI\n\n'));
            end
            
        end
        
        c.String = '<html>&nbsp;&nbsp;&nbsp;&nbsp;Press and hold the space<br>&nbsp;&nbsp;&nbsp;&nbsp;bar whenever you hear the<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;pulsing noise';
        % [outtext, newpos] = textwrap(t,{'Press and hold the space bar whenever you hear the pulsing tone'}); % wrap the text, if needed
        % set(t,'String',outtext,'Position',newpos) % put the actual text up in location determined by textwrap
        drawnow; % force updating of the figure graphics before moving on
        
        
        %% Begin
        currStepSizeIdx = 1; % initial index into stepSizes
        currEar = runOrd(currRun); % target ear for current run
        
        noiseIdx = 1:noiseBuffer_smp;
        
        if currEar == 1
            bufferdata_targ = [allNoiseBands(startFreqIdx,:); zeros(1,size(allNoiseBands,2))];
            bufferdata_mask = [zeros(1,length(noiseIdx)); noiseStim(noiseIdx)];
        else
            bufferdata_targ = [zeros(1,size(allNoiseBands,2)); allNoiseBands(startFreqIdx,:)];
            bufferdata_mask =  [noiseStim(noiseIdx); zeros(1,length(noiseIdx))];
        end
        
        
        PsychPortAudio('UseSchedule', paTargEar, 1);
        PsychPortAudio('UseSchedule', paMaskEar, 1);
        
        targBuffer = PsychPortAudio('CreateBuffer', paTargEar, bufferdata_targ);
        maskBuffer = PsychPortAudio('CreateBuffer', paMaskEar, bufferdata_mask);
        
        [success, freeslots] = PsychPortAudio('AddToSchedule', paTargEar, targBuffer, nPulsesQuiet);
        [success, freeslots_pamask] = PsychPortAudio('AddToSchedule', paMaskEar, maskBuffer, 1);
        
        tStart = PsychPortAudio('Start', paTargEar, 1, 0, 1);
        
        WaitSecs((nPulsesQuiet-0.25)*totalDur./1000);
        %     totalDur_smp
        
        % Start the contralateral noise
        PsychPortAudio('Start', paMaskEar,1,0,1); % wait for start since this is the first one
        %     tStart = GetSecs;
        
        statusTarg = PsychPortAudio('GetStatus', paMaskEar);
        statusMask = PsychPortAudio('GetStatus', paMaskEar);
        % Set up some loop-related variables
        allResp = freqSeq(startFreqIdx.*ones(nPulsesQuiet./nPulsesPerStep,1));
        allRev = nan(2, maxRev);
        saveRes = 1;
        keepGoing = 1;
        timeout = 0;
        currDir = 1;
        revTime = GetSecs; % start the timeout timer
        [currBand, prevBand] = deal(startFreqIdx);
        
        targScheduleCounter = 0;
        maskScheduleCounter = 0;
        loopCtr = 0; % count the number of loops
        nRev = 0;
        while keepGoing
            loopCtr = loopCtr + 1;
            loopStart = GetSecs;
            
            bufferIdx = mod(loopCtr-1, 3)+1;
            
            if loopCtr > (2) % this is for deleting old buffers that finished playing already (assuming that buffer from 2 loops ago should be done by now)
                deleteIdx =  mod(bufferIdx, 3)+1;
                result = PsychPortAudio('DeleteBuffer', targBuffer(deleteIdx));
                result = PsychPortAudio('DeleteBuffer', maskBuffer(deleteIdx));  % delete the previous noise buffer
            end
            
            
            if currEar == 1
                bufferdata_targ = [allNoiseBands(currBand,:); zeros(1,size(allNoiseBands,2))];
            else
                bufferdata_targ = [zeros(1,size(allNoiseBands,2)); allNoiseBands(currBand,:)];
            end
            
            targBuffer(bufferIdx) = PsychPortAudio('CreateBuffer', paTargEar, bufferdata_targ);
            
            if ~statusTarg.Active
                PsychPortAudio('UseSchedule', paTargEar, 1);
            end
            
            [success, freeslots] = PsychPortAudio('AddToSchedule', paTargEar, targBuffer(bufferIdx),nPulsesPerStep); % upward sweep
            
            if ~statusTarg.Active
                PsychPortAudio('Start', paTargEar, 1, 0, 1);
                targScheduleCounter = targScheduleCounter + 1;
            end
            
            statusMask = PsychPortAudio('GetStatus', paMaskEar);
            
            if debugMode
                fprintf('\nElapsedOutSamples= %d', statusMask.ElapsedOutSamples)
                fprintf('\nBufferFraction= %1.4f', statusMask.ElapsedOutSamples./noiseBuffer_smp)
            end
            
            % Queue up the next masker buffer
            if ~statusMask.Active
                PsychPortAudio('UseSchedule', paMaskEar, 1);
            end
            
            noiseIdx = noiseIdx(end)+ [1:noiseBuffer_smp];
            
            if any(noiseIdx > length(noiseStim)) % if for whatever reason we reach the end of the noise sequence, start repeating samples from the beginning (there will be an artifact for the moment of transition)
                badIdx = noiseIdx > length(noiseStim);
                noiseIdx(badIdx) = 1:sum(badIdx);
            end
            
            if currEar == 1
                bufferdata_mask = [zeros(1,length(noiseIdx)); noiseStim(noiseIdx)];
            else
                bufferdata_mask =  [noiseStim(noiseIdx); zeros(1,length(noiseIdx))];
            end
            
            maskBuffer(bufferIdx) = PsychPortAudio('CreateBuffer', paMaskEar, bufferdata_mask); % create a buffer for the next chunk of audio
            
            [success_pamask, freeslots_pamask] = PsychPortAudio('AddToSchedule', paMaskEar, maskBuffer(bufferIdx), 1);
            
            if ~statusMask.Active
                PsychPortAudio('Start', paMaskEar, 1, 0, 1);
                maskScheduleCounter = maskScheduleCounter + 1;
            end
            
            statusTarg = PsychPortAudio('GetStatus', paTargEar);
            
            drawnow; % update the figure - this allows matlab to catch if it was closed and execute the callback
            
            if debugMode
                fprintf('\n%1.4f', (GetSecs-tStart)./(loopCtr*totalDur/1000 - 0.15*(totalDur/1000)))
                fprintf('\n%1.4f', (GetSecs-loopStart)./(totalDur/1000))
                fprintf('\nWaiting for %1.4f before proceeding to the next loop', ((nPulsesPerStep*loopCtr)+nPulsesQuiet-0.25)*totalDur/1000 - ((GetSecs-tStart)))
            end
            
            while (GetSecs-tStart) < ((nPulsesPerStep*loopCtr)+nPulsesQuiet-0.25)*totalDur/1000
                % Stall the code so that the loop runs roughly in sync w/
                % buffers being added into the schedule
            end
            
            
            [keyIsDown, secs, keyCode] = KbCheck;
            
            prevDir = currDir;
            prevBand = currBand;
            if keyIsDown && any([keyCode(upKey) keyCode(quitKey)])
                
                if keyCode(upKey)
                    currDir = 1*stepSizes(currStepSizeIdx);
                elseif  keyCode(quitKey) % if want to quite, break out of the loop
                    keepGoing = 0;
                    saveRes = 0;
                    finished = 0;
                    newRun = false;
                     
                    if debugMode % in debug mode, give user the control to examing variable states at the time of crash
                        keyboard;
                    end
                end
            else
                currDir = -1*stepSizes(currStepSizeIdx);
            end
            
            allResp(end+1,:) = freqSeq(currBand);  % store the current frequency band
            
            if sign(prevDir) ~= sign(currDir)  && loopCtr > 1 % if direction is reversing, we need to record the stimulus info
                % The loopCtr > 1 makes sure that the initial staircase
                % step is never counted as a reversal. 
                revTime = GetSecs; % reset the timeout timer
                nRev = nRev + 1;
                allRev(:,nRev) = [freqSeq(currBand); size(allResp,1)]; % record the center frequency at reversal + the step #
                
                if nRev == maxRev
                    keepGoing = 0;
                    finished = 1;
                    break;
                end
                
                if nRev == sum(reversalsPerStepSize(1:currStepSizeIdx))
                    currStepSizeIdx = currStepSizeIdx+1;
                    currDir = stepSizes(currStepSizeIdx)*currDir./abs(currDir); % update the step size for this upcoming trial
                end
                
                
            end
            
            
            currBand = currBand + currDir; % and adjust level by 1
            
            currBand = min(currBand, nFreqBands); % prevent going out of range
            currBand = max(currBand, 1);
            
            % Special-case scenario where max/min level is reached -> record as if it was a response
            if (prevDir ==currDir) && ~isempty(intersect(currBand, [1 nFreqBands])) && (diff([prevBand currBand]) ~= 0) % if max or min is hit/diverged from, also collect the data point
                allResp(end+1,:) = freqSeq(currBand);
            end
            
            
            
            if debugMode
                fprintf('\nFree slots target = %d, Status = %d',freeslots, statusTarg.Active);
                fprintf('\nFree slots mask= %d, Status = %d',freeslots_pamask, statusMask.Active);
            end
            
            % Check for timeout
            if GetSecs-revTime > timeOutTimeLimit
                keepGoing = 0;
                finished = 1;
                timeout = 1; 
                fprintf('\nNo reversal in %d sec.\n\nTrack skipped!\n',timeOutTimeLimit) 
                break;
            end
            
        end
        fprintf('\nDebug info:\nTarget schedule restarted %d times.\nMask schedule restarted %d times', targScheduleCounter, maskScheduleCounter)
        fprintf('\n')
        
        if c.isvalid
            c.String = '<html>&nbsp;&nbsp;&nbsp;&nbsp;Finishing up...'; % one last update to the GUI
            drawnow; % force updating of the figure graphics before moving on
        end
        
        if timeout % if timeouted, assign dummy threshold and standard deviation 
            thresh = timeOutThresh;
            stDev = timeOutSD; 
        else % if succesful finish, compute threshold and standard deviation based on reversals
            thresh = nanmean(allRev(1,end-useReversals+1:end)); % compute the threshold
            stDev =  nanstd(allRev(1,end-useReversals+1:end),1); % use N in std calculation to be consistent w/ AFC
        end
        
        % Make a results figure, but only if a "manual" run (i.e.
        % experiment starts next one) has just finished OR if we specify we
        % want all the figure even on "autopilot":
        if makeFigsOnAutopilot || currRun < autoPilotOnRun
            resFig = figure;
            plot(allResp,'k');
            hold on
            plot(allRev(2,:), allRev(1,:),'ro');
            plot(get(gca,'XLim'), [thresh thresh],'b--');
            set(gca,'YLim',[freqSeq(1), freqSeq(end)], 'YScale', 'log'); % 'XScale', 'log'
            xlabel('Trial #')
            ylabel('Center frequency (Hz)')
            title(sprintf('High frequency threshold = %1.1f Hz',thresh));
            %     xlim([min([startF endF]) max([startF endF])])
        end
       
        
        % Save the behavioral data + a bunch of other experimental details
        allResults{currRun} = allResp; % behavioral data
        allReversals{currRun} = allRev; % just the reversals
        allThresholds(currRun) = thresh; % just the threshold, as determined based on reversals
        allStDevs(currRun) = stDev; % standard deviation of reversals 
        allNoiseStartF(currRun) = lowF; % start frequency of noise
        allNoiseEndF(currRun) = highF; % end frequency of noise
        allNoiseDur(currRun) = length(freqSeq)./fs; % Duration of noise in seconds
        allNoiseBWidth(currRun) = bandWidth; % bandwidth of noise in Hz
        allSampleRate(currRun) = fs; % samplerate
        %     allNoiseFreqSeq{currRun} = freqSeq; % instantaneous center frequency of noise
        allRandState{currRun} = randState; % random number seed
        
        if saveRes
            save(datFile, 'currRun', 'runOrd', 'allResults', 'allReversals', 'allThresholds', 'allStDevs', 'allRandState', 'allNoiseStartF', 'allNoiseEndF', 'allNoiseDur', 'allNoiseBWidth', 'allSampleRate')
        end
        
        % Determine whether to continue or stop the experiment
        if ~autoPilotMode || currRun < autoPilotOnRun
            
            newRun = false;
            
        else
            
            currRun = currRun+1;
            
            if currRun > nRuns
                
                fprintf('\nExperiment finished!!\n');
                newRun = false;
                currRun = nRuns;  % just so the message at the end is correct, set currRun to nRuns
            else
                
                if makeFigsOnAutopilot
                    % Minimize the results figure (but apparently this method will
                    % become obsolete in the future - hence why we disable the warning messages briefly)
                    warning('off')
                    jFrame = get(handle(resFig), 'JavaFrame');
                    jFrame.setMinimized(1);
                    warning('on')
                end
                
                figure(f); % bring the GUI back into focus
            end
            
            KbReleaseWait; % make sure the subject lets go of spacebar before continuing (not super important in this case)
        end 
    end
    
    ListenChar(0); % re-enable the keyboard
    PsychPortAudio('Close')
    
    if ishandle(f)
        close(f); % close the UI figure
    end
    
    removePTB
    
catch errMsg
    ListenChar(0);
    PsychPortAudio('Close')
    removePTB
    
    if debugMode % in debug mode, give user the control to examing variable states at the time of crash
        keyboard;
    end
    
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

