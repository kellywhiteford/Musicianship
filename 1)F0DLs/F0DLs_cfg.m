
% This matlab script is called by afc_main when starting
% the experiment 'F0DLs'.

def=struct(...
    'expname','F0DLs',           ...		% name of experiment
    'headphone','HD650',		 ...		% Headphone type
    'intervalnum',2,			 ...		% number of intervals
    'ranpos',0,					 ...		% interval which contains the test signal: 1 = first interval ..., 0 = random interval
    'rule',[1 3],				 ...		% [up down]-rule: [1 2] = 1-up 2-down
    'startvar',7.7815,			 ...		% starting value of the tracking variable
    'expvarunit','10logpct',	 ...		% unit of the tracking variable
    'varstep',[3, 1, 0.5],		 ...        % [starting stepsize ... minimum stepsize] of the tracking variable
    'minvar',-40,				 ...		% minimum value of the tracking variable
    'maxvar',30,				 ...		% maximum value of the tracking variable
    'steprule',-1,				 ...		% stepsize is changed after each upper (-1) or lower (1) reversal
    'reversalnum',6,			 ...		% number of reversals in measurement phase
    'exppar1',100, 				 ...		% F0
    'exppar1unit','Hz',          ...		% unit of experimental parameter
    'exppar2',60, 				 ...		% Level (dB SPL)
    'exppar2unit','dBSPL',		 ...		% unit of experimental parameter
    'repeatnum',3,				 ...		% number of repetitions of the experiment
    'parrand',1,                 ...		% toggles random presentation of the elements in "exppar" on (1), off(0)
    'mouse',1,					 ...		% enables mouse control (1), or disables mouse control (0)
    'markinterval',1,			 ...		% toggles visuell interval marking on (1), off(0)
    'feedback',1,				 ...		% visual feedback after response: 0 = no feedback, 1 = correct/false/measurement phase
    'backgroundsig',0,           ...		% allows a backgroundsignal during output: 0 = no bgs, 1 = bgs is added to the other signals, 2 = bgs and the other signals are multiplied
    'samplerate',48000,          ...		% sampling rate in Hz
    'intervallen',9600*4,          ...        % length of each signal-presentation interval in samples (200 ms * 4)
    'pauselen', 24000,			 ...		% length of pauses between signal-presentation intervals in samples (500 ms)
    'presiglen',0,               ...		% length of signal leading the first presentation interval in samples
    'postsiglen',4800,              ...		% length of signal following the last presentation interval in samples
    'result_path','./Output/',   ...		% where to save results
    'control_path','./Control/', ...		% where to save control files
    'messages','F0DLs',          ...		% message configuration file
    'windetail',1,               ...        % If set to 1, displays number of runs left on message screen.
    'savefcn','default',		 ...		% function which writes results to disk
    'debug',0,					 ...		% set 1 for debugging (displays all changible variables during measurement)
    'maxiter',100                ...
    );

