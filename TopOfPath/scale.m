function result = scale(stimulus,gain)
%scale(stimulus,gain)
%Scales a stimulus by a factor gain in dB

if nargin < 2
   help scale
   return
end

   result = stimulus .* 10^(gain/20);
