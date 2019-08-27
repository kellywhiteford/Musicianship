% english_msg - english message definition file -
%
% ready_msg			displayed when ready for user response
% measure_msg		displayed when entering measurement phase
% correct_msg		displayed after correct response
% false_msg			displayed after false response
% maxvar_msg		displayed when maxvar is reached
% minvar_msg		displayed when minvar is reached
% start_msg			displayed when the experiment starts
% next_msg			displayed when the next parameter is presented
% finished_msg		displayed when the experiment is finished

msg=struct(...
'measure_msg','--- CORRECT ---',	...
'correct_msg','--- CORRECT ---',			...
'false_msg','--- INCORRECT ---',				...
'maxvar_msg','Maximum level reached',	...
'minvar_msg','Minimum level reached' ...
);

msg.ready_msg    = {'Which interval has a tone sequence?'};
msg.start_msg    = {'Your task is to determine whether the 1st or 2nd interval has a tone sequence.', ...
                    'Press any key to begin.'};
msg.next_msg     = {'End of Run.', ...
                    'Press "s" for a new run or "e" to end.'};
msg.finished_msg = {'Experiment Done.', ...
                    'Press "e" to end.'};
                    
msg.experiment_windetail = 'Experiment: %s';
msg.measurement_windetail = 'Measurement %d of %d';
msg.measurementsleft_windetail = '%d of %d measurements left';

msg.buttonString = {'1','2'};		% Cell array of strings to display on buttons 1 ... def.intervalnum. 
																			% If empty or not defined, the interval number is displayed

msg.startButtonString = 's (start)';
msg.endButtonString = 'e (end)';

% eof
