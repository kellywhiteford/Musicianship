function varargout = SpeechTest(varargin) % Format for input: "SpeechTest('subjID','experimentName','uniID')"

% SPEECHTEST Format for input: "SpeechTest('ID','experimentName','uniID'). Runs a speech 
% for subject 'subjID'.
% This is a GUI created with MATLAB's "GUIDE" tool. 
% Example: SpeechTest('s1','QuickSIN','umn')

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @SpeechTest_OpeningFcn, ...
    'gui_OutputFcn',  @SpeechTest_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SpeechTest is made visible.
function SpeechTest_OpeningFcn(hObject, ~, handles, varargin)
%% Checks that the correct experiment name was entered.
if ~strcmp(varargin{2},'QuickSIN')
    disp('Wrong experiment name! Enter QuickSIN as the experiment name.')
    error('Incorrect input to SpeechTest function.')
end

%% Set parameters
handles.parname = varargin{2}; % experiment name
run QuickSIN_parameters.m % load experiment parameters
handles.par = parameters; % structure of parameters

if ~exist([cd '\Output\'],'dir') % do we need to create the subject folder?
    mkdir([cd '\Output\']); % if so, then make it.
end

subjID = varargin{1}; % Subject number
uniID = varargin{3}; % University ID (e.g., 'umn' for University of Minnesota)
fName = [cd '\Output\' handles.parname '_' subjID '_' uniID '.mat']; % Name of location where data is saved

if exist(fName,'file') % check whether subject ID has been defined yet
    handles.subject = load(fName,'subject'); % if so, import subject structure
    handles.subject = handles.subject.subject;
    if isfield(handles.subject,'finished') % checks whether subject has already completed the entire experiment
        disp('This subject already has a completed data file for QuickSIN.')
        error('Check the subject ID or move on to the next task.')
    end
    if isempty(handles.subject.responses) % if there are no responses recorded, treat as if a new subject
        NewSubject_QuickSIN(subjID,handles.par,uniID); % generate subject structure
        handles.subject = load(fName,'subject'); % then load it
        handles.subject = handles.subject.subject;
    end
else % if not, this is a new subject
    NewSubject_QuickSIN(subjID,handles.par,uniID); % generate subject structure
    handles.subject = load(fName,'subject'); % then load it
    handles.subject = handles.subject.subject;
end


%% Grab and present stimuli
handles.listname = [handles.par.listnamepre num2str(handles.subject.nextlist) handles.par.listnamepost]; % which list to use
handles.sentind = 1;
handles.sentnum = handles.subject.nextsentord(handles.sentind); % start with first sentence in sentence order.
handles.completed = 0;
fileName = [handles.listname num2str(handles.sentnum) handles.par.fileending]; % Target speech sentence

set(handles.Message, 'String', strcat(['Trial ', num2str(handles.sentind) ' of ' num2str(handles.par.NumSentencesAvailable)])); % displays trial number in gui

set(handles.Tracker,'String', ['List ' num2str(handles.subject.listind) ' of ' num2str(length(handles.subject.listord))]); % Update list tracker

[sentence,fs] = audioread(fileName); % read next sentence audio.
sentence = sentence(:,1); % We only need one column of speech.

% Adjust level of signal and noise and present stimuli
maxlevel = handles.par.MaxLevel; % Defined in QuickSIN_parameters.m
atten_level = handles.par.OverallLevel - maxlevel; % amount of attenuation needed for speech signal
sentence = scale(sentence./rms(sentence),atten_level); % force speech+babble to have rms=1 and then attenuate so that level matches handles.par.OverallLevel (defined in QuickSIN_parameters.m)
y = hann(sentence',50,fs); % add ramps 

handles.y = y; % save to "handles" structure so GUI will see it on next button press
handles.fs = fs;
%handles.noise = noise'; 

uicontrol(handles.Play); % highlight the Play button

% Choose default command line output for SpeechTest
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SpeechTest wait for user Response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SpeechTest_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% set(hObject,'Units','Pixels','Position',get(0,'ScreenSize')) % fits gui to screen



% --- Executes on button press in Play.
function Play_Callback(hObject, eventdata, handles)
% hObject    handle to Play (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.Message, 'String', []); % Clear message to user
set(handles.Tracker,'String', ['List ' num2str(handles.subject.listind) ' of ' num2str(length(handles.subject.listord))]); % Update list tracker
set(handles.Play,'enable','off'); % Can't press play again until response is saved
set(handles.Exit,'enable','off'); % Can't exit in the middle of a list (althohugh user could always just close the window).
set(handles.Save,'enable','on'); % Can now save response

set(handles.Message, 'String', strcat(['Trial ', num2str(handles.sentind) ' of ' num2str(handles.par.NumSentencesAvailable)])); % displays trial number in gui

% Get current sentence audio
y = handles.y; 
fs = handles.fs;


% Play current sentence audio
disp(size(y));
disp(size(fs));
sound(y,fs);

if handles.sentind == handles.par.SentencesPerList % If list is over, determine next list
    if handles.subject.listind < length(handles.subject.listord) % Assuming there is a next list
        handles.subject.listind = handles.subject.listind + 1; % Go to next list index
        handles.subject.nextcond = handles.subject.condord(handles.subject.listind); % next condition
        handles.subject.nextlist = handles.subject.listord(handles.subject.listind); % next list number
        handles.subject.nextsentord = handles.subject.sentordord(handles.subject.listind,:); % sentence order for next list
        subject = handles.subject; % extract current Subject structure from "handles"
        save([cd '\Output\' handles.parname '_' subject.id '_' subject.uni '.mat'],'subject'); % save Subject structure (with responses)
        handles.listname = [handles.par.listnamepre num2str(handles.subject.nextlist) handles.par.listnamepost]; % next list name
        handles.sentind = 1;
        handles.sentnum = handles.subject.nextsentord(handles.sentind); % start with first sentence in sentence order.
    else % If this was the end of the last list, flag for exit
        handles.completed = 1;
    end
else % If list is not over yet, determine next sentence
    handles.listname = [handles.par.listnamepre num2str(handles.subject.nextlist) handles.par.listnamepost]; % list name
    handles.sentind = handles.sentind + 1;
    handles.sentnum = handles.subject.nextsentord(handles.sentind); % next sentence in sentence order
end

fileName = [handles.listname num2str(handles.sentnum) handles.par.fileending]; % Speech + Babble

[sentence,fs] = audioread(fileName); % read next sentence audio.
sentence = sentence(:,1); % We only need one column of target speech.

% Adjust overall level and present stimuli
maxlevel = handles.par.MaxLevel; % Defined in QuickSIN_parameters.m
atten_level = handles.par.OverallLevel - maxlevel; % amount of attenuation needed for speech signal
sentence = scale(sentence./rms(sentence),atten_level); % force speech+babble to have rms=1 and then attenuate so that level matches handles.par.OverallLevel (defined in QuickSIN_parameters.m)

y = hann(sentence',50,fs); %add ramps 

handles.y = y; % save to "handles" structure so GUI will see it on next button press
handles.fs = fs;

uicontrol(handles.Response)

guidata(hObject, handles);


function Response_Callback(hObject, eventdata, handles)
% hObject    handle to Response (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Response as text
%        str2double(get(hObject,'String')) returns contents of Response as a double


% --- Executes during object creation, after setting all properties.
function Response_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Response (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Append current contents of response box to "responses" in subject
% structure.
handles.subject.responses = [handles.subject.responses; get(handles.Response, 'string')];
if isempty(get(handles.Response, 'string')) % if no response
    handles.subject.responses = [handles.subject.responses; 'NO RESPONSE']; % record the fact that there was no response
end
set(handles.Response, 'string',''); % clear response box

set(handles.Message, 'String', strcat(['Trial ', num2str(handles.sentind) ' of ' num2str(handles.par.NumSentencesAvailable)])); % displays trial number in gui

if handles.sentind == 1 % If we are about to start a new list
    subject = handles.subject; % Extract subject structure
    save([cd '\Output\' handles.parname '_' subject.id '_' subject.uni '.mat'],'subject'); % save it
    set(handles.Message, 'String', 'End of list.'); % notify user that the current list has ended
    if handles.subject.listind == round(length(handles.subject.listord)/2) % Optional break message
        set(handles.Message, 'String', 'Halfway done!');
    end
    set(handles.Play,'enable','on'); % user can now click Play for next sentence
    set(handles.Save,'enable','off'); % can't save response again until next sentence is played
    set(handles.Exit,'enable','on'); % can now exit at the end of the list
    uicontrol(handles.Play); % highlight the Play button
elseif handles.completed % End of experiment
    handles.subject.finished = 'yes'; % Indicates subject has completed the experiment
    subject = handles.subject; % Extract subject structure
    save([cd '\Output\' handles.parname '_' subject.id '_' subject.uni '.mat'],'subject'); % save it
    set(handles.Message, 'String', 'End of experiment. Please press Exit.'); % inform user that experiment is over
    set(handles.Play,'enable','off'); % no more sentences to play
    set(handles.Save,'enable','off'); % no more responses to save
    set(handles.Exit,'enable','on'); % can exit
    uicontrol(handles.Exit); % highlight the Exit button
else % Same list, new sentence
    set(handles.Play,'enable','on'); % user can now click Play for next sentence
    set(handles.Save,'enable','off'); % can't save response again until next sentence is played
    set(handles.Exit,'enable','off'); % can't exit until end of list
    uicontrol(handles.Play); % highlight the Play button
end


guidata(hObject, handles);


% --- Executes on button press in Exit.
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
subject = handles.subject; % Extract subject structure
save([cd '\Output\' handles.parname '_' subject.id '_' subject.uni '.mat'],'subject'); % save it
guidata(hObject, handles);
close(gcf) % close the GUI
