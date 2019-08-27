function varargout = AudioController(command_str, TDT, varargin)
% function varargout = AudioController(command_str, TDT, varargin)
%
% DESCRIPTION:
% Controls audio output via a list of subcommands. AudioController takes a
% command_str, in the form of a string which calls a subfunction by the same
% name, and a TDT structure with many necessary variables. If TDT.debugMode
% is 'true' or TDT.Type='PTB' (preferred) then AudioController will interact 
% with the internal sound card instead of the TDT. Some subfunctions require
% additional inputs via the varargin field.
%
%
% INPUTS:
%   command_str :: a string command which calls the subfunction of the same name
%   TDT         :: structure containing pertinent fields
%		.fs		:: the expected sampling rate
%   varargin    :: some commands take more inputs
% 
% COMMANDS:
%   TDT = AudioController('init', TDT)              :: initialize TDT
%   AudioController('loadBuffer', TDT, wave_data)   :: write wave_data [N, 2] to the buffer.
%   start_time = AudioController('start', TDT)      :: start playing sound
%   AudioController('stopReset', TDT)               :: stop playing sound and rewind
%   AudioController('clearBuffer', TDT [,N] )       :: write [N] 'zeros' to buffer, else fill entire buffer with zeros
%   AudioController('startNoise', TDT)              :: start background noise (happens automatically on init)
%   AudioController('stopNoise', TDT)               :: stop background noise
%   AudioController('close', TDT)                   :: close audio handle

% created 12/17/2012, ZRE

% check for input
if ~exist('command_str', 'var')
    error('you need to pass a command, as a string, to AudioController: "AudioController(''close'', TDT)"')
end
if ~exist('TDT', 'var')
    error('AudioController takes a second argument, "TDT", which is a structure containing many pertient fields')
end
if ~isfield(TDT, 'fs')
	error('You must specify the sampling rate, "TDT.fs".')
end
	
% call subfunction
if strcmp(command_str, 'init')
    evalStr = sprintf('TDT = %s(TDT, varargin{:});', command_str);
elseif strcmp(command_str, 'start')
    evalStr = sprintf('start_time = %s(TDT, varargin{:});', command_str);
else
    evalStr = sprintf('%s(TDT, varargin{:});', command_str);
end
eval(evalStr)

% return stuff
if strcmp(command_str, 'init') && nargout == 1
    varargout{1} = TDT;
elseif strcmp(command_str, 'start') && nargout == 1
    varargout{1} = start_time;
end

%% subfunctions

function varargout = init(TDT) %#ok<*DEFNU>
% function TDT = init(TDT)
%
% DESCRIPTION: set up and return TDT data structure and call envoke
%
% INPUTS:
%	TDT.
% 		noiseAmps :: [=0] white noise gain

% created 12/05/2012, ZRE

if ~exist('TDT', 'var') || ~isfield(TDT, 'noiseAmp') 
	TDT.noiseAmp = 0;
end

if ~isDebugMode(TDT)
	TDT.CIR_PATH = 'expCircuitF32.rcx';
	% check to make sure the circuit exists
	if ~exist(TDT.CIR_PATH, 'file')
		if ~isfield(TDT,'circuit_dir')
			error('Circuit %s not found, and TDT.circuit_dir not defined',TDT.CIR_PATH)
		end
		TDT.CIR_PATH = fullfile(TDT.circuit_dir, TDT.CIR_PATH);
		if ~exist(TDT.CIR_PATH, 'file')
			error('Circuit %s not found',TDT.CIR_PATH);
		end
	end
	TDT.USB_ch = 1;
	TDT.FS_tag  =  2; % Corresponds to 25kHz; if this changes, the deciamtion of data later MUST be adjusted
	if ~isfield(TDT,'Type')
		TDT.Type = 'RP2';
	end
	if ~isfield(TDT,'onsetdel')
		TDT.onsetdel = 0;
	end
	
	%% load TDT circuit
	% The following code is pulled from: loadTDTCircuit.m
	figNum = 99;
	[TDT.handle, TDT.RP, fs] = loadCircuit(TDT.FS_tag, figNum, TDT.USB_ch, TDT.CIR_PATH, TDT.Type);
	
	% make sure the sample rate matches!
	if round(fs) ~= TDT.fs
		error('the sampling rate specified by "loadCircuit", (%g), does not match the expected sample rate (%g)', fs, TDT.fs)
	end
	
	%% set default params
	TDT.fsActual = round(invoke(TDT.RP, 'GetSFreq'));
	% Need to differentiate between the software trigger that begins
	% playback (soundPlayBackTrigger) and the one that gets sent out via
	% the digital triggers (playbackStamp), as the former might change with
	% different circuit designs. We want the latter to *always* be one,
	% unless we explicitly change it, so we separate them here.
	TDT.soundPlayBackTrigger = 1;
	TDT.playbackStamp = 1;
	TDT.stopTrigger = 2;
	TDT.startNoiseTrigger = 3;
	TDT.stopNoiseTrigger = 4;
	TDT.resetTrigger = 5;
	TDT.manualTrigger = 6;
	TDT.oneRMSdB = getTDTrms(TDT.Type);
	TDT.dbBaselineAmp = 65;
	TDT.baselineAmp = 100 * 10^(-(TDT.oneRMSdB - TDT.dbBaselineAmp) / 20); % baseLine = .01 is oneRMSdB dBSPL, we want 65
	
	%% invoke
	invoke(TDT.RP, 'ZeroTag', 'datainleft');
	invoke(TDT.RP, 'ZeroTag', 'datainright');
	invoke(TDT.RP, 'SetTagVal', 'onsetdel', TDT.onsetdel); % onset delay is in ms
	invoke(TDT.RP, 'SetTagVal', 'noiselev',TDT.noiseAmp);
	invoke(TDT.RP, 'SetTagVal', 'phase', -1);
	invoke(TDT.RP, 'SoftTrg', TDT.startNoiseTrigger); %Playback noise trigger
else
    if ~isfield(TDT, 'noiseAmp')
        TDT.noiseAmp = 0;
    end
	% use psychtoolbox
	TDT.RP = [];
	InitializePsychSound(1);
    TDT.handle = PsychPortAudio('Open');
    status = PsychPortAudio('GetStatus', TDT.handle);
    TDT.fsActual = status.SampleRate;
    TDT.Type = 'PTB';
end
varargout{1} = TDT;


function startNoise(TDT)
% function startNoise(TDT)
%
% INPUTS:
%	TDT
if ~isDebugMode(TDT)
	invoke(TDT.RP, 'SoftTrg', TDT.startNoiseTrigger); %Playback noise trigger
end


function stopNoise(TDT)
% function stopNoise(TDT)
%
% INPUTS:
%	TDT
if ~isDebugMode(TDT)
	invoke(TDT.RP, 'SoftTrg', TDT.stopNoiseTrigger); %Playback noise trigger
end


function loadBuffer(TDT, wave_data)
% function loadBuffer(TDT, wave_data)
%
% INPUTS:
%	TDT

% created 12/05/2012, ZRE

if ~exist('wave_data', 'var')
    error('loadBuffer requires a [N, 2] sound file, "wave_data".')
end

if (max(max(abs(wave_data)))) > 1
    disp(sprintf([' *** WARNING: Audio clipping! Maximum amplitude was ' num2str((max(max(abs(wave_data))))) '! ***']));
end

% make sure wave_data is appropriate
if size(wave_data, 1) == 2
    % force channels to be in columns
    wave_data = wave_data';
elseif size(wave_data, 2) == 1
    disp('WARNING: duplicating mono channel into stereo channels')
    wave_data = repmat( wave_data, 1, 2);
end

% For backward compatibility
if ~isDebugMode(TDT)
	invoke(TDT.RP, 'WriteTagVEX', 'datainleft', 0, 'F32', wave_data(:,1)); % Load into TDT.RP2
	invoke(TDT.RP, 'WriteTagVEX', 'datainright', 0, 'F32', wave_data(:,2)); % Load into TDT.RP2
	invoke(TDT.RP, 'SetTagVal', 'presstimesindex', 0);
else
    % delineate channels by columns
    if size(wave_data, 1) == 2
        wave_data = wave_data.';
    end
    % resample
%     new_wave_data = resample(wave_data, TDT.fsActual, TDT.fs);

    % WHY DOESNT resample WORK FOR ME!!! (ZRE)
    stim_dur = size(wave_data, 1) / TDT.fs;
    new_wave_data = interp1(linspace(0, stim_dur, size(wave_data,1)), wave_data, linspace(0, stim_dur, TDT.fsActual * stim_dur)'); 
    % add white noise
	new_wave_data = new_wave_data + TDT.noiseAmp * randn(size(new_wave_data, 1), 1) * [1 -1];

    % load buffer
    PsychPortAudio('FillBuffer', TDT.handle, new_wave_data.');
end

function debugMode = isDebugMode(TDT)
debugMode = isfield(TDT, 'debugMode') && TDT.debugMode;
debugMode = (debugMode || strcmpi(TDT.Type,'PTB'));

function start_time = start(TDT)
% function TDTstart(TDT)
%
% INPUTS:
%	TDT
%
% OUTPUTS:
%   start_time      :: sound start time
 
% created 12/05/2012, ZRE
if ~isDebugMode(TDT)
	invoke(TDT.RP, 'SetTagVal', 'trgname', TDT.playbackStamp);
	invoke(TDT.RP, 'SoftTrg', TDT.soundPlayBackTrigger); % Trigger sound playback
else
	PsychPortAudio('Start', TDT.handle);
end
start_time = GetSecs;

function stopReset(TDT)
% function stopReset(TDT)
%
% stops and resets buffer
%
% INPUTS:
%	TDT
 
% created 12/05/2012, ZRE

if ~isDebugMode(TDT)
	invoke(TDT.RP, 'SoftTrg', TDT.stopTrigger); %Stop trigger
	invoke(TDT.RP, 'SoftTrg', TDT.resetTrigger); %Reset Trigger
else
	PsychPortAudio('Stop', TDT.handle);
end


function clearBuffer(TDT, N)
% function clearBuffer(TDT, N)
%
% write N zeros to buffer
%
% INPUTS:
%	TDT :: structure
%	N	:: if not passed then write zeros to entire buffer

% created 12/05/2012, ZRE

if ~isDebugMode(TDT)
	if ~exist('N', 'var')
		% fill entire buffer with zeros
		invoke(TDT.RP, 'ZeroTag', 'datainleft');
		invoke(TDT.RP, 'ZeroTag', 'datainright');
	else
		% write N zeros to buffer
		loadBuffer(TDT, zeros(N, 2) )
	end
else
	disp('no buffer to clear in debug mode')
end


function close(TDT)
% function close(TDT)
%
% INPUTS:
%	TDT

% created 12/05/2012, ZRE

if isfield(TDT, 'RP')
	if ~isempty(TDT.RP)
		if strcmpi(class(TDT.RP), 'COM.RPco_x')
			invoke(TDT.RP, 'SoftTrg', TDT.stopNoiseTrigger); %Stop noise trigger
			closeCircuit(TDT.handle, TDT.RP);
		elseif strcmpi(class(TDT.RP), 'handle')
			warning('User:TDT','TDT circuit has already been closed!')
		else
			warning('User:TDT','Something fishy is happening.')
		end
	else
		PsychPortAudio('Close', TDT.handle);
	end
end
