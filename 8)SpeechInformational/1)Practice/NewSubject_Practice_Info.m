function [subject] = NewSubject_Practice_Info(ID, uniID)

% This function is called by SpeechInformational if the given subject ID 
% does not yet exist. It creats a "subject" structure to track a subject's 
% responses and progress.

degrees = [15]; % spatial separation condition for practice
reps = 1; % just one practice run per condition
subject.id = ID;
subject.uni = uniID;
subject.responses = {}; % subject responses go here
subject.targSent = {}; % target sentences go here
subject.maskSent1 = {}; % masker1 sentences go here
subject.maskSent2 = {}; % masker2 sentences go here
subject.targVoice = {}; % target voices go here
subject.maskVoice1 = {}; % masker1 voices go here
subject.maskVoice2 = {}; % masker2 voices go here
subject.targLev = {}; % target level (for each trial) goes here
subject.condition = {}; % spatial separation condition (for each trial) goes here
subject.numberCorrect = {}; % number of keywords correct (for each trial) goes here


list = repmat(degrees,1,reps);
subj.num_blocks = length(list); % total number of blocks

subject.Avg = zeros(1,subj.num_blocks); % Target thresholds goes here
subject.SD = zeros(1,subj.num_blocks); % Standard deviation for each run goes here
subject.rev_level = zeros(10,subj.num_blocks); % Level of target at each reversal point goes here

subject.block_order = list(randperm(length(list))); % randmizes block order

subject.nextcond = subject.block_order(1);
subject.nextblock = 1; 

save([cd '\Output\' ID '_' uniID '.mat'],'subject');

end