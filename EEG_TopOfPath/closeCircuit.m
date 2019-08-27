function closeCircuit(f1,RP)
%At the end of an experiment, the circuit is removed
if strcmpi(class(RP), 'COM.RPco_x')
	invoke(RP,'ClearCOF'); %clear the circuit from the RP2
	close(f1); %close the ActX control window
elseif strcmpi(class(RP), 'handle')
	warning('TDT circuit has already been closed!')
else
	warning('Something fishy is happening.')
end

