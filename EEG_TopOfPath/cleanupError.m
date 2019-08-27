function cleanupError(TDT,err)

ListenChar(0);
ShowCursor;
Screen('CloseAll');
sca
try
	AudioController('close', TDT)
catch err
	warning(err.identifier,err.message);
end
if exist('err', 'var') && ~isempty(err)
	rethrow(err);
end
