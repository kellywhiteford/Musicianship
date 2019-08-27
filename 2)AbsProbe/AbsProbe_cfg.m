% AbsProbe_cfg 
%
% This matlab skript is called by afc_main when starting
% the experiment 'AbsProbe'.

def=struct(...
    'expname','AbsProbe',        ...	 % name of experiment
    'intervalnum',2,			 ...	 % number of intervals
    'ranpos',0,                  ...     % interval which contains the test signal: 1 = first interval ..., 0 = random interval
    'rule',[1 3],                ...     % [up down]-rule: [1 3] = 1-up 3-down
    'varstep',[8 4 2],           ...     % [starting stepsize ... minimum stepsize] of the tracking variable
    'steprule',-1,               ...     % stepsize is changed after each upper (-1) or lower (1) reversal
    'reversalnum', 6,            ...     % number of reversals in measurement phase
    'repeatnum', 1,              ...     % number of repeatitions of the experiment; AFC will run three reps because there are 3 fake variables in exppar1
    'startvar', 30,              ...     % starting value of the tracking variable
    'expvarunit','dB SPL',       ...     % unit of the tracking variable
    'minvar', -40,               ...     % minimum value of the tracking variable
    'maxvar', 80,                ...	 % maximum value of the tracking variable
    'terminate', 1,              ...	 % terminate execution on min/maxvar hit: 0 = warning, 1 = terminate
    'endstop', 6,                ...     % Allows x nominal levels higher/lower than the limits before terminating (if def.terminate = 1)
    'exppar1',[0 55555 9999],    ...     % Nothing at all- this just makes it so the order of the frequency conditions is blocked (if one chooses to add more frequency conditions), and then the order is randomized
    'exppar1unit','Nothing',     ...     % unit of experimental parameter
    'exppar2',4000,              ...     % vector containing experimental parameters for which the exp is performed
    'exppar2unit','Hz',          ...     % unit of experimental parameter
    'parrand',[1 1],	         ...	 % toggles random presentation of the elements in "exppar" on (1), off(0)
    'mouse',1,					 ...	 % enables mouse control (1), or disables mouse control (0)
    'markinterval',1,			 ...	 % toggles visuell interval marking on (1), off(0)
    'feedback',1,				 ...	 % visuell feedback after response: 0 = no feedback, 1 = correct/false/measurement phase
    'samplerate',48000,          ...	 % sampling rate in Hz
    'intervallen',24000,          ...     % length of each signal-presentation interval in samples
    'pauselen',14400,            ...	 % length of pauses between signal-presentation intervals in samples
    'presiglen',0,               ...	 % length of signal leading the first presentation interval in samples
    'postsiglen',0,              ...	 % length of signal following the last presentation interval in samples
    'result_path','./Output/',   ...	 % where to save results
    'control_path','./Control/', ...     % where to save control files
    'messages','AbsProbe',       ...	 % message configuration file
    'windetail',1,               ...     % If set to 1, displays number of runs left on message screen.
    'savefcn','default',		 ...     % function which writes results to disk
    'debug',0					 ...     % set 1 for debugging (displays all changible variables during measurement)
    );