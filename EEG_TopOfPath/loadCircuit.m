function [f1,RP,FS]=loadCircuit(FS_tag,fig_num,USB_ch,CIR_PATH,TDTType)
% Loads the TDT circuit and makes actx links necessay
% Legacy code from KC. The TDT matlab syntax has now changed to look more
% like OOPS but this old style is still supported.
%
%------------
% Hari Bharadwaj, September 6, 2010
%------------
warning('off'); %#ok<WNOFF>

if(nargin < 4 || isempty(CIR_PATH))
	CIR_PATH='play_noise_kc.rcx'; %The *.rco circuit used to play the files
end
if(~exist(CIR_PATH))
	error('TDT circuit not found (%s)',CIR_PATH);
end
if(nargin < 5 || isempty(TDTType))
	TDTType = 'RP2';
end

if(~any(strcmp(TDTType,{'RP2','RZ6','RM1'})))
	error('TDTType %s incorrect',TDTType);
end
% In our setup, the RP2 is always USB, the RZ6 is always GB (?)
if(strcmp(TDTType,'RZ6'))
	connectType = 'GB';
else
	connectType = 'USB';
end

%Generate the actx control window in a specified figure:
%-------------------------------------------------------
f1=figure(fig_num);
set(f1,'Position',[5 5 30 30],'Visible','off'); %places and hides the ActX Window
triesLeft = 2;
RPLoaded = false;
while triesLeft > 0 && ~RPLoaded
	try
		RP=actxcontrol('RPco.x',[5 5 30 30],f1); %loads the actx control for using rco circuits
		RPLoaded = true;
	catch ME
		triesLeft = triesLeft - 1;
		warning(ME.message);
	end
end
if ~exist('RP', 'var')
	error('Couldn''t load ActiveX control. Is TDT ActiveX installed?')
end
if ~invoke(RP,['Connect' TDTType],connectType,USB_ch); % opens the RP2 device   *** CHANGED 'USB' to 'GB' TMS 6/2005 ***
	error('Could not connect to %s', TDTType);
end
% (the USB channel may change for other computer configurations)

% The rco circuit can be run at the following set of discrete sampling
% frequencies (in Hz): 0=6k, 1=12k, 2=25k, 3=50k, 4=100k, 5=200k.
% Use the tags listed above to specify below:
%--------------------------------------------------------------------------
if ~exist(CIR_PATH,'file')
	error('Circuit path not found: %s',CIR_PATH);
end
if ~invoke(RP,'LoadCOFsf',CIR_PATH,FS_tag); %loads the circuit using the specified sampling freq.
	error('Could not load onto %s circuit %s',TDTType,CIR_PATH);
end
FS_vec=getTDTRates;
FS=FS_vec(FS_tag+1);

invoke(RP,'Run'); %start running the circuit

Status = double(invoke(RP,'GetStatus'));
if bitget(double(Status),1)==0
    error(['Error connecting to ' TDTType]);
elseif bitget(double(Status),2)==0
    error('Error loading circuit');
elseif bitget(double(Status),3)==0
    error('Error running circuit');
end

% Start the background noise
if strcmp(TDTType,'RM1')
	goodStatus = (invoke(RP,'GetStatus')==255);
else
	goodStatus = invoke(RP,'GetStatus')==7;
end
if ~goodStatus  % RP2 circuit status success
    error([TDTType ' circuit status failure'])
end
