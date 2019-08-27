% AbsProbe_user - stimulus generation function of experiment 'AbsProbe' -
%
% This function is called by afc_main when starting
% the experiment 'AbsProbe'. It generates the stimuli which
% are presented during the experiment.
% The stimuli must be elements of the structure 'work' as follows:
%
% work.signal = def.intervallen by 2 times def.intervalnum matrix.
%               The first two columns must contain the test signal
%               (column 1 = left, column 2 = right) ...
% 
% work.presig = def.presiglen by 2 matrix.
%               The pre-signal. 
%               (column 1 = left, column 2 = right).
%
% work.postsig = def.postsiglen by 2 matrix.
%                The post-signal. 
%               ( column 1 = left, column 2 = right).
%
% work.pausesig = def.pausesiglen by 2 matrix.
%                 The pause-signal. 
%                 (column 1 = left, column 2 = right).

function AbsProbe_user

global def
global work
global set

sigLevel = work.expvaract; % Signal level
sigLevelAtten = sigLevel-set.maxlevel;  % The amount that the stimuli will be attenuated by


signal = hann(tone(work.exppar2,set.dur_ms,0,def.samplerate),set.ramp_ms,def.samplerate); %pure-tone signal

sig = scale(signal,sigLevelAtten); %signal 
ref = 0.*sig; %silence



presig = zeros(def.presiglen,2); % nothing
postsig = zeros(def.postsiglen,2); % silence; duration defined in AbsProbe_cfg.m
pausesig = zeros(def.pauselen,2); % nothing

work.signal = [ref' sig' ref' ref'];	% First two columns holds the test signal (left right); note that the signal is only presented to the right ear
work.presig = presig;					% must contain the presignal
work.postsig = postsig;                 % must contain the postsignal
work.pausesig = pausesig;               % must contain the pausesignal

% eof
