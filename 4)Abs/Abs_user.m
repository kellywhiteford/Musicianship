% Abs_user - stimulus generation function of experiment 'Abs' -
%
% This function is called by afc_main when starting
% the experiment 'Abs'. It generates the stimuli which
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

function Abs_user

global def
global work
global set

% work.expvaract holds the current value of the tracking variable of the experiment.
burstLevel = work.expvaract; % Signal level
burstLevelAtten = burstLevel-set.maxlevel;  % The amount that the stimuli will be attenuated by

a_burst = scale(tone(work.exppar1,set.burst_dur,0,def.samplerate),burstLevelAtten); % one tone burst with the level scaled
burst = hann(a_burst,set.ramp_ms,def.samplerate); %one tone burst with ramps
signal = [burst,burst,burst,burst,burst,burst,burst,burst]; % signal is 8 tone bursts

ref = 0.*signal; %silence

% if work.presentationCounter == 1 % make plots on first trial (for debugging)
%     figure
%     subplot(1,2,1)
%     plot(signal)
%     title('Target')
%     hold on
%     subplot(1,2,2)
%     spec(signal,80,def.samplerate);
% end



presig = zeros(def.presiglen,2);
postsig = zeros(def.postsiglen,2);
pausesig = zeros(def.pauselen,2);

% make required fields in work

work.signal = [signal' signal' ref' ref'];	% left = right (diotic) first two columns holds the test signal (left right)
work.presig = presig;											% must contain the presignal
work.postsig = postsig;											% must contain the postsignal
work.pausesig = pausesig;										% must contain the pausesignal

% eof
