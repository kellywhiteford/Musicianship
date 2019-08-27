%% SpeechInformational. 
% This program uses the matrix-style word corpus recorded for the Boston
% University psychoacoustics lab by the Sensimetrics Corporation 
% (Malden, MA). 
% 
% This program was written with Matlab 2016b. 

% To use this program, make sure to set the calibration level ("rms1level"
% in parameters.m)

function SpeechInformational(subjID,uniID)
%% Set parameters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Enter path where stimulus files and mat file with grid of words are located
stimpath = '..\BUC-Mx_2014_FiveCategories';  

% Load the matrix of words in the BUG corpus 
load([stimpath,'\BUC_Mx_2014_Text.mat'])

% Loads experimental parameters.
run parameters.m
handles.completed = 0; %

talkerVec = 1:12; % Enter vector of possible talker #s you wish to hear

%NOTE: Only "Female" condition is currently implemented for spatial conditions
malfem = 'Female'; % Enter whether you want to hear a 'Male' or 'Female' voice

numberOfWordColumns = 5;  % BUC matrix words without conjunctions
numberOfWordsPerColumn = 8; % Number of options per category
state = 1; % 1 = continue, 0 = exit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Determine (randomized) condition order for subject
if exist([cd '\Output\' subjID '_' uniID '.mat'],'file') % check whether subject ID has been defined yet
    handles.subject = load([cd '\Output\' subjID '_' uniID '.mat'],'subject'); % if so, import subject structure
    handles.subject = handles.subject.subject;
    if isfield(handles.subject,'finished') % checks whether subject has already completed the entire experiment
        disp('This subject already has a completed data file for SpeechInformational.')
        error('Check the subject ID or move on to the next task.')
    end
    if isempty(handles.subject.responses) % if there are no responses recorded, treat as if a new subject
        NewSubject_Info(subjID,uniID); % generate subject structure
        handles.subject = load([cd '\Output\' subjID '_' uniID '.mat'],'subject'); % then load it
        handles.subject = handles.subject.subject;
    end
else % if not, this is a new subject
    NewSubject_Info(subjID,uniID); % generate subject structure
    handles.subject = load([cd '\Output\' subjID '_' uniID '.mat'],'subject'); % then load it
    handles.subject = handles.subject.subject;
end


%% Randomly select sentence, present, and obtain responses as long as user selects "Continue"
while state==1
    target_lev_data(trial_count) = targ_lev; % store target level
    % display(num2str(handles.subject.nextcond)) % prints spatial condition to command window
    startNewBlock = 'no'; % startNewBlock is 'no' when in the middle of a block
    
    %% Generate random list of words
    targetColumnIndexList = 1:numberOfWordColumns;
    targetRow = zeros(1,numberOfWordColumns);
    targetRow(1) = 2; % Target always has the callsign "Jane"
    for w=2:numberOfWordColumns
        targetRow(w) = ceil(rand*numberOfWordsPerColumn);  % select the row containing the current word
    end
    
   
    % Columns: Category (1: Name, 2: verb, 3: number, etc.); see Kidd et al.'s (2008) Table 1
    % Rows: Number of options per category
    possibleWords = repmat(1:numberOfWordsPerColumn,numberOfWordColumns,1)';
    
   % Possible words left over once accounting for target's words
    leftOverWords1 = reshape(possibleWords(find(possibleWords ~= targetRow)),numberOfWordsPerColumn-1,numberOfWordColumns);
   
    maskRow1 = zeros(1,numberOfWordColumns);
    maskRow2 = zeros(1,numberOfWordColumns);
    for w=1:numberOfWordColumns
        maskRow1(w) = randsample(leftOverWords1(:,w),1); % randomly selects masker1 words
    end
    
    % Possible words left over once accounting for masker1's words
    leftOverWords2 = reshape(leftOverWords1(find(leftOverWords1 ~= maskRow1)),numberOfWordsPerColumn-2,numberOfWordColumns);
    
    for w=1:numberOfWordColumns
        maskRow2(w) = randsample(leftOverWords2(:,w),1); % randomly selects masker2 words
    end
    
    % Choose talkers
    talkers = randsample(talkerVec,3); % returns a vector of 3 values sampled uniformly at random from talkerVec
    targtalk= num2str(talkers(1)); % Target talker
    masktalk1 = num2str(talkers(2)); % Masker 1 talker
    masktalk2 = num2str(talkers(3)); % Masker 2 talker
    wordSignal = [];
    wordSignal_M1 = [];
    wordSignal_M2 = [];
    
    for Word = 1:length(targetColumnIndexList)
        % load and scale words
        currentWordText_T = BUC_Mx_2014_Text{targetRow(Word),targetColumnIndexList(Word)}; % Target current word
        currentWordText_M1 = BUC_Mx_2014_Text{maskRow1(Word),targetColumnIndexList(Word)}; % Masker1 current word
        currentWordText_M2 = BUC_Mx_2014_Text{maskRow2(Word),targetColumnIndexList(Word)}; % Masker1 current word
        if strcmp(malfem,'Male') % Not used in this experiment but can be implemented for future use.
            currentWordFileName_T = [stimpath,'\',currentWordText_T,'_',targtalk,'M.wav'];
            currentWordFileName_M1 = [stimpath,'\',currentWordText_M1,'_',masktalk1,'M.wav'];
            currentWordFileName_M2 = [stimpath,'\',currentWordText_M2,'_',masktalk2,'M.wav'];
        else
            currentWordFileName_T = [stimpath,'\0_BU\0_BU_s_',currentWordText_T,'_',targtalk,'F.wav'];
            switch handles.subject.nextcond
                case 0 % co-located
                    currentWordFileName_M1 = [stimpath,'\0_BU\0_BU_s_',currentWordText_M1,'_',masktalk1,'F.wav'];
                    currentWordFileName_M2 = [stimpath,'\0_BU\0_BU_s_',currentWordText_M2,'_',masktalk2,'F.wav'];
                case 15
                    currentWordFileName_M1 = [stimpath,'\L15_BU\L15_BU_s_',currentWordText_M1,'_',masktalk1,'F.wav'];
                    currentWordFileName_M2 = [stimpath,'\R15_BU\R15_BU_s_',currentWordText_M2,'_',masktalk2,'F.wav'];
            end
        end
        
        
        targetSignal = audioread(currentWordFileName_T);
        m1Signal = audioread(currentWordFileName_M1);
        m2Signal = audioread(currentWordFileName_M2);
      
        stimatten = rms1Level - 40 - targ_lev; % - 40 needed because stimuli were rms normalized to digital rms = .01 before convolution (i.e., 40 dB down from rms=1; 20*log10(1/.01) = 40); no level-correction is added for the rms change after convolution with HRTFs
        stimatten_M1 = rms1Level - 40 - mask_lev;
        stimatten_M2 = rms1Level - 40 - mask_lev;
        
        targetSignal = targetSignal.* 10^(-stimatten/20); % Scale down (or up) from reference rms to appropriate level
        m1Signal = m1Signal.* 10^(-stimatten_M1/20); % Scale down (or up) from reference rms to appropriate level
        m2Signal = m2Signal.* 10^(-stimatten_M2/20); % Scale down (or up) from reference rms to appropriate level
        
        
        % Concatenate all words in sequence
        temp = targetSignal;
        temp_M1 = m1Signal;
        temp_M2 = m2Signal;
        wordSignal = [wordSignal; temp];
        wordSignal_M1 = [wordSignal_M1; temp_M1];
        wordSignal_M2 = [wordSignal_M2; temp_M2];
        clear targetSignal m1Signal m2Signal
    end
    
    lVec = [length(wordSignal),length(wordSignal_M1),length(wordSignal_M2)]; % length of Target, Masker 1, and Masker 2
    BIG = max(lVec); % longest talker; this will determine the length of the trial
    
    % zero padding so that all stimuli have the same length
    n_end_T = BIG -lVec(1); % length of padding for Target
    n_end_M1 = BIG - lVec(2); % length of padding for Masker 1
    n_end_M2 = BIG - lVec(3); % length of padding for Masker 2
    
    pad_T = zeros(n_end_T,2); % zero padding for Target
    pad_M1 = zeros(n_end_M1,2); % zero padding for Masker 1
    pad_M2 = zeros(n_end_M2,2); % zero padding for Masker 2
    
    % Set zero padding to empty for the longest talker.
    if n_end_T == 0 % If no padding is needed for the Target,
        pad_T = []; % then zero padding should be empty.
    elseif n_end_M1 == 0
        pad_M1 = [];
    elseif n_end_M2 == 0
        pad_M2 = [];
    end
    
    % Concatenate talkers with zero padding.
    target = [wordSignal; pad_T];
    masker1 = [wordSignal_M1; pad_M1];
    masker2 = [wordSignal_M2; pad_M2];

    y = target+masker1+masker2;
    
    playstim = y;
    
    
    %% Prepare GUI
    titletext = ['Block ',num2str(handles.subject.nextblock)];
    switch trial_count
        case 1 % New Block
            infoText = ['In this experiment, you will hear three, simultaneous sentences, spoken by three different female talkers. ' ...
                        'Your task is to listen to the voice whose first word is "Jane". This is the target voice. ' ...
                        'Please try to only listen to the target voice and ignore the other voices. ' ...
                        'After listening to the target sentence, you will report back the words from the target voice by clicking ' ...
                        'buttons on the screen corresponding to the words that you heard. ' ...
                        'Please ask the experimenter now if you have any questions. ' ...
                        'Otherwise, you may click the button labeled "Begin" to start the task.'];
            buttonText = {''};
            actionButtonText = 'Begin';
            exitbuttontext = '';
            buttonColumnGUI('info',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            
            actionButtonText = '';
            exitbuttontext = '';
            buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            infoText = ['Listen to the sentence where the first word is "Jane".'];
            actionButtonText = '';
            exitbuttontext = '';
            buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            pause(.5)
        otherwise
            infoText = ['Listen to the sentence where the first word is "Jane".'];
            titletext = ['Block ',num2str(handles.subject.nextblock)];
            buttonText = {''};
            actionButtonText = '';
            exitbuttontext = '';
            buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            pause(.5)
    end
    %% Play Stimulus using player of choice
    playObj = audioplayer([playstim(:,1) playstim(:,2)],Fs,24); 
    playblocking(playObj);

    %% Obtain response
    infoText = ['Please select the target words from each column. '];
    resp = [];
    for Word = 1:length(targetColumnIndexList)
        buttontext = BUC_Mx_2014_Text';
        infotext = {['Please respond ',];['Response: ', resp ]};
        actionbuttontext = '';
        subjectresponse{Word} = buttonColumnGUI('response',infotext,buttontext,actionbuttontext,titletext,Word,exitbuttontext);
        resp = [resp mat2str(subjectresponse{Word})];
    end
    buttonText = {''};
    infotext = {['Please respond ',];['Response: ', resp]};
    actionbuttontext = '';
    buttonColumnGUI('trial',infotext,buttontext,actionbuttontext,titletext,[],exitbuttontext);  % Get responses for the whole sequence
    
    %% Feedback and Adaptive Tracking
    for Word= 1:length(targetColumnIndexList)
        A(Word) = BUC_Mx_2014_Text(targetRow(Word),targetColumnIndexList(Word));
        M1(Word) = BUC_Mx_2014_Text(maskRow1(Word),targetColumnIndexList(Word));
        M2(Word) = BUC_Mx_2014_Text(maskRow2(Word),targetColumnIndexList(Word));
        corr_incorr{Word} =  strcmp(BUC_Mx_2014_Text(targetRow(Word),targetColumnIndexList(Word)),subjectresponse(Word));
    end
    
    nCorrect = sum(cell2mat(corr_incorr(:))); % number of correct words in the sentence
    handles.subject.responses = [handles.subject.responses; subjectresponse]; % subject responses for each trial
    handles.subject.targSent = [handles.subject.targSent; A]; % actual target words for each trial
    handles.subject.maskSent1 = [handles.subject.maskSent1; M1]; % masker 1 words for each trial
    handles.subject.maskSent2 = [handles.subject.maskSent2; M2]; % masker 2 words for each trial
    handles.subject.targVoice = [handles.subject.targVoice; targtalk]; % target voice for each trial
    handles.subject.maskVoice1 = [handles.subject.maskVoice1; masktalk1]; % masker 1 voice for each trial
    handles.subject.maskVoice2 = [handles.subject.maskVoice2; masktalk2]; % masker 2 voice for each trial
    handles.subject.targLev = [handles.subject.targLev; targ_lev]; % target level for each trial
    handles.subject.condition = [handles.subject.condition; handles.subject.nextcond]; % spatial condition for each trial
    handles.subject.numberCorrect = [handles.subject.numberCorrect; nCorrect]; % total number correct for each trial
    
    numberCorrect(trial_count) = nCorrect;
    corr_wrds = sum(cell2mat(corr_incorr(:))); % counts total number of words correct for this trial

    if nCorrect>=numberOfWordColumns-1 % At least 4/5 keywords correct: Decrease target level
        direction = 'down'; % decrease target level
        if strcmp(prev_trial,'up')
            rev_count = rev_count + 1; % counts reversal if previous trial was in the opposite direction
            rev_level(rev_count) = targ_lev; % level of the target at the reversal point
        end
        switch rev_count
            case {0,1,2,3} % initial and first three reversals
                ind = 1; % index for step size of target level
            case 10 % last reversal
                handles.subject.rev_level(:,handles.subject.nextblock) = rev_level'; % Level of target at each reversal point; Columns correspond to Block number
                handles.subject.block(handles.subject.nextblock).level = target_lev_data; % trial by trial level of the target
                handles.subject.block(handles.subject.nextblock).Corr = numberCorrect; % trial by trial number of keywords correct
                handles.subject.Avg(handles.subject.nextblock) = mean(rev_level(5:10)); % takes mean of target level at last 6 reversal points
                handles.subject.SD(handles.subject.nextblock) = std(rev_level(5:10)); % takes standard devitation of target level at last 6 reversal points
                handles.subject.nextblock = handles.subject.nextblock + 1; % move to next block
                if handles.subject.nextblock <= length(handles.subject.block_order) % If the experiment is not over
                    handles.subject.nextcond = handles.subject.block_order(handles.subject.nextblock); % move to next condition
                else 
                    handles.completed = 1; % Indicate that experiment is over
                end
                subject = handles.subject; % Extract subject structure
                save([cd '\Output\' subject.id '_' uniID '.mat'],'subject'); % save it
                % RESETS PARAMETERS HERE
                run parameters.m
                startNewBlock = 'yes';
                trial_count = 0;
                %
                buttonText = {''};
                infoText = {['End of block ', num2str(handles.subject.nextblock-1)]};
                actionButtonText = '';
                buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            otherwise % all following reversals
                ind = 2; % index for step size of target level
        end
        if strcmp(startNewBlock,'no') % If the block is not over yet,
            targ_lev = targ_lev - steps_db(ind); % decreases target level by steps_db(ind); steps_db is defined in parameters.m
            infotext = [num2str(corr_wrds),' of 5 words correct. :)']; % Feedback for subject
        end
    else % Two or more words are incorrect.
        direction = 'up'; % increase target level
        if strcmp(prev_trial,'down')
            rev_count = rev_count + 1; % counts reversal if previous trial was in the opposite direction
            rev_level(rev_count) = targ_lev; % level of the target at the reversal point
        end
        switch rev_count
            case {0,1,2,3} % initial and first three reversals
                ind = 1; % index for step size of target level
            case 10 % last reversal
                handles.subject.rev_level(:,handles.subject.nextblock) = rev_level'; % Level of target at each reversal point; Columns correspond to Block number
                handles.subject.block(handles.subject.nextblock).level = target_lev_data; % trial by trial level of the target
                handles.subject.block(handles.subject.nextblock).Corr = numberCorrect; % trial by trial number of keywords correct
                handles.subject.Avg(handles.subject.nextblock) = mean(rev_level(5:10)); % takes mean of target level at last 6 reversal points
                handles.subject.SD(handles.subject.nextblock) = std(rev_level(5:10)); % takes standard devitation of target level at last 6 reversal points 
                handles.subject.nextblock = handles.subject.nextblock + 1; % move to next block
                if handles.subject.nextblock <= length(handles.subject.block_order) % If the experiment is not over
                    handles.subject.nextcond = handles.subject.block_order(handles.subject.nextblock); % move to next condition
                else 
                    handles.completed = 1; % Indicate that experiment is over
                end
                subject = handles.subject; % Extract subject structure
                save([cd '\Output\' subject.id '_' uniID '.mat'],'subject'); % save it
                % RESETS PARAMETERS HERE
                run parameters.m;
                startNewBlock = 'yes';
                trial_count = 0;
                %
                buttonText = {''};
                infoText = {['End of block ', num2str(handles.subject.nextblock-1)]};
                actionButtonText = 'Continue';
                exitbuttontext = 'Exit';
                buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
            otherwise % all following reversals
                ind = 2; % index for step size of target level
        end
        if strcmp(startNewBlock,'no') % If the block is not over yet,
            if targ_lev + steps_db(ind) <= max_lev % checks to make sure target level is less than max_lev (set in parameters.m)
                targ_lev = targ_lev + steps_db(ind);  % increases target level by steps_db(ind); steps_db is defined in parameters.m
            else 
                targ_lev = max_lev; % set target level to max_lev (defined in parameters.m) if the ceiling level is reached
            end
            infotext = [num2str(corr_wrds),' of 5 words correct.']; % Feedback for subject
        end
    end
    if rev_count < 10 && strcmp(startNewBlock,'no') % If the block is not over yet,
        pause(.5)
        buttonText = {''};
        actionButtonText = 'Continue';
        exitbuttontext = 'Exit';
        exitstate = buttonColumnGUI('exit',infotext,buttonText,actionButtonText,titletext,[],exitbuttontext);
    end
    
    % If subject reaches maximum number of trials
    if trial_count >= max_trials
        r = length(handles.subject.rev_level(:,handles.subject.nextblock)); % number of reversals expected
        R = length(rev_level); % number of reversals calcualted
        z = zeros(1,r-R); % number of zeros will match the number of reversals that are missing
        revDat = [rev_level,z]; % zeros are used where there are missing reversals
        handles.subject.rev_level(:,handles.subject.nextblock) = revDat'; % Level of target at each reversal point; Columns correspond to Block number
        handles.subject.block(handles.subject.nextblock).level = target_lev_data; % trial by trial level of the target
        handles.subject.block(handles.subject.nextblock).Corr = numberCorrect; % trial by trial number of keywords correct
        handles.subject.Avg(handles.subject.nextblock) = .12345; % NO THRESHOLD CALCULATED IF MAXIMUM TRIALS IS REACHED WITHOUT CONVERGING TO THRESHOLD
        handles.subject.SD(handles.subject.nextblock) = 0; % STANDARD DEVIATION IS SET TO 0 IF MAX TRIALS IS REACHED WITHOUT CONVERGING TO THRESHOLD
        handles.subject.nextblock = handles.subject.nextblock + 1; % move on to next block
        if handles.subject.nextblock <= length(handles.subject.block_order)  % If the experiment is not over
            handles.subject.nextcond = handles.subject.block_order(handles.subject.nextblock); % move to next condition
        else
            handles.completed = 1; % Indicate that experiment is over
        end
        subject = handles.subject; % Extract subject structure
        save([cd '\Output\' subject.id '_' uniID '.mat'],'subject'); % save it
        % RESETS PARAMETERS HERE
        run parameters.m
        startNewBlock = 'yes';
        trial_count = 0;
        %
        buttonText = {''};
        infoText = {['End of block ', num2str(handles.subject.nextblock-1)]};
        actionButtonText = '';
        buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
    end
        
    
    if handles.completed % End of experiment
        handles.subject.finished = 'yes'; % Indicates subject has completed the experiment
        subject = handles.subject; % Extract subject structure
        save([cd '\Output\' subject.id '_' uniID '.mat'],'subject'); % save it
        buttonText = {''};
        infoText = {'End of experiment'};
        actionButtonText = '';
        exitbuttontext = 'Exit';
        exitstate = 'Exit';
        buttonColumnGUI('trial',infoText,buttonText,actionButtonText,titletext,[],exitbuttontext);
        state = 0;
    end
    
    if strcmp(exitstate,'Continue') % If experiment is in progress,
        trial_count = trial_count + 1; % move on to the next trial
        prev_trial = direction; % store reversal direction of trial that just finished
        state = 1; % continue looping through trials
    elseif strcmp(exitstate,'Exit')
        state = 0;
    end
end

buttonColumnGUI('close',infotext,buttonText,actionButtonText,titletext,[],exitbuttontext);