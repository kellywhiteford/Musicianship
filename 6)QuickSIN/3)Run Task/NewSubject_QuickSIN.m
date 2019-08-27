function [subject] = NewSubject_QuickSIN(ID,parameters,uni)
% This function is called by SpeechTest for the experiment "QuickSIN" if 
% the given subject ID and university ID  does not yet exist. It creats a 
% "subject" structure to track a subject's responses and progress.

subject.id = ID; % subject ID (e.g., 's1')
subject.uni = uni; % University ID (e.g., 'umn' for University of Minnesota)
subject.responses = {}; % subject responses go here
L = parameters.NumRepetitions*parameters.NumConditions; % total number of lists needed
allorder = randperm(parameters.NumListsAvailable) + 2; % randomizes lists; adds 2 to each list number to select from tracks 3-14
subject.listord = allorder(1:L); % chooses the needed number of lists

subject.sentordord = zeros(L,parameters.SentencesPerList);
for i = 1:L
    subject.sentordord(i,:) = 1:parameters.SentencesPerList; % sentence order is fixed according to QuickSIN manual
end

% which condition on each list
condordmat = zeros(parameters.NumConditions,parameters.NumRepetitions); % matrix of condition presentation orders
for i = 1:parameters.NumRepetitions
    condordmat(:,i) = randperm(parameters.NumConditions);
end
subject.condord = reshape(condordmat,[1 L]); % vector of condition presentation order

subject.listind = 1;
subject.nextlist = subject.listord(1);
subject.nextsentord = subject.sentordord(1,:);
subject.nextcond = subject.condord(1);

save([cd '\Output\QuickSIN_' ID '_' uni '.mat'],'subject');

end