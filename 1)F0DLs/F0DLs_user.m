
% This function is called by afc_main
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
% 

function F0DLs_user

global def
global work
global set

f0_ref = set.freq; % defined in "F0DLs_set.m"

% Geometrically centers f0 changes around f0 
f0A = f0_ref * sqrt(1 + 10^(work.expvaract/10)/100);
f0B = f0_ref / sqrt(1 + 10^(work.expvaract/10)/100);

tone_ref = generate_ct(f0_ref); % reference tone

% tone with F0 above reference F0
toneA = generate_ct(f0A);

% tone with F0 below reference F0
toneB = generate_ct(f0B);

% First, apply window and scale to correct level
tone_ref = hann(scale(tone_ref'./rms(tone_ref), set.level), set.ramp_ms, def.samplerate); 
toneA = hann(scale(toneA'./rms(toneA), set.level), set.ramp_ms, def.samplerate);
toneB = hann(scale(toneB'./rms(toneB), set.level), set.ramp_ms, def.samplerate); 

%Then, make tone sequences.
tref = [tone_ref, tone_ref, tone_ref, tone_ref];
tuser = [toneA, toneB, toneA, toneB];


if ~true % set to true to make plots for checking stimuli
    figure
    f_plot = (0:(length(tone_ref) - 1)) / length(tone_ref) * def.samplerate;
    plot(f_plot, 20 * log10(abs(fft(tone_ref))), 'k')
    hold on
    plot(f_plot, 20 * log10(abs(fft(toneA))), 'r')
    plot(f_plot, 20 * log10(abs(fft(toneB))), 'b')
    xlabel('Frequency (Hz)')
    ylabel('Amp (dB)')
    legend('ref', 'A', 'B')
    
    figure
    plot((1:length(tone_ref)) / def.samplerate, tone_ref)
    figure
    subplot(1,2,1)
    plot(tuser)
    title('Target')
    ylabel('Amplitude')
    hold on
    subplot(1,2,2)
    spec_klw(tuser,80,def.samplerate,'b',[1 10000]);
    title(['Target: f0 = ' num2str(f0A) ' & F0 ' num2str(f0B) ' Hz'])
    
    figure
    subplot(1,2,1)
    plot(tref)
    title('Reference')
    hold on
    subplot(1,2,2)
    cd ../11)EEG_da % Folder with /da/ stimulus
    [stimulus, fs_da] = audioread('DAbase_resampled.wav');
    da = stimulus/rms(stimulus); % Forces stimuli to have rms=1
    cd ../1)F0DLs % Change back to F0DLs folder
    spec_klw(da',80,fs_da,'r',[1 10000]); % frequency spectrum of /da/
    hold on
    spec_klw(tref,80,def.samplerate,'b',[1 10000]); % frequency spectrum of reference; should match /da/
    title(['Reference: f0 = ' num2str(f0_ref) ' Hz'])
    legend('/da/', 'Reference', 'Location','best')
    
    figure
    subplot(1,2,1)
    spec_klw(da',80,fs_da,'r',[1 10000]); % frequency spectrum of /da/
    title('/da/')
    hold on
    subplot(1,2,2)
    spec_klw(tref,80,def.samplerate,'b',[1 10000]); % frequency spectrum of reference; should match /da/
    title('Reference')
    
end

% silence = zeros(def.pauselen,1);
% example = [tref'; silence; tuser'];
% audiowrite('F0DLs_Example.wav',example,def.samplerate) 

presig=zeros(def.presiglen,2);
postsig=zeros(def.postsiglen,2);
pausesig=zeros(def.pauselen,2);

work.signal=[tuser', tuser', tref', tref']; % left = right (diotic) first two columns holds the test signal (left right)					
work.presig=presig;							% must contain the presignal
work.postsig=postsig;						% must contain the postsignal
work.pausesig=pausesig;						% must contain the pausesignal

% eof
