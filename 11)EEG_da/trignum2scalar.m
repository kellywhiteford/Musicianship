%
% trignum2scalar function
%
%   FILE NAME       : BioSemi Trigger Number to Scalar Converter
%   DESCRIPTION     : The BioSemi ActiveTwo EEG System has 8 trigger
%                     channels dedicated to stimulus presentation -- with 
%                     states HIGH/ON and LOW/OFF -- that when permuted form
%                     an 8-bit unsigned integer (0-255). Using
%                     trignum2scalar, the user can hand-pick their desired
%                     trigger number, which is returned as a scalar used to
%                     multiply a "ones" array in the playrec channel 
%                     corresponding to "ADAT Out" (channel 12 on the RME 
%                     Fireface UCX, and channel 14 on the RME MADIface 
%                     UFX+). This is useful when you want to label specific
%                     events with specific trigger numbers.
%
%INPUT ITEMS
%
%   n               : Desired trigger number, 1-255.
%
%RETURNED ITEMS
%
%   sf              : Scale-factor applied to "ones" array to return the
%                     desired trigger number.
%
%(C) Timothy Nolan Jr., Auditory Neuroscience Lab, CMU
%    Last Edit 03.31.2019
%

function sf = trignum2scalar(n)
    if n > 0 && n < 256
        sf = (n/2 + mod(n,2)*127.5)/(255*64);
    else
        error('ERROR: Desired trigger number is not in range. Please select a value from 1 to 255 when using trignum2scalar.');
    end
end