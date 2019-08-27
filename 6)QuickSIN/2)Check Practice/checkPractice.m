% Loads subject data and displays responses in command window. Run this
% after the Practice task to double-check that the subject knows how to do
% the task.
function checkPractice(subjID,uniID)

fName =  ['..\1)Practice\Output\QuickSIN_Practice_' subjID '_' uniID '.mat']; % Name of location where data is saved

data = load(fName,'subject'); % load subject data structure

responses = data.subject.responses; % the subject's typed responses
 
disp(responses) % displays responses to the command window