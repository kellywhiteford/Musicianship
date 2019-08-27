function varargout = buttonColumnGUI(varargin)
% BUTTONCOLUMNGUI MATLAB code for buttonColumnGUI.fig
%      BUTTONCOLUMNGUI, by itself, creates a new BUTTONCOLUMNGUI or raises the existing
%      singleton*.
%
%      H = BUTTONCOLUMNGUI returns the handle to a new BUTTONCOLUMNGUI or the handle to
%      the existing singleton*.
%
%      BUTTONCOLUMNGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BUTTONCOLUMNGUI.M with the given input arguments.
%
%      BUTTONCOLUMNGUI('Property','Value',...) creates a new BUTTONCOLUMNGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before buttonColumnGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to buttonColumnGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help buttonColumnGUI

% Last Modified by GUIDE v2.5 25-Aug-2016 17:30:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @buttonColumnGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @buttonColumnGUI_OutputFcn, ...
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


% --- Executes just before buttonColumnGUI is made visible.
function buttonColumnGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to buttonColumnGUI (see VARARGIN)

handles.guiState = varargin{1};
infoText = varargin{2};
buttonText = varargin{3};
actionButtonText = varargin{4};
title_text = varargin{5};
curr_col = varargin{6};
exitbuttontext = varargin{7};
handles.output = hObject;
guidata(hObject,handles);

set(handles.figure1,'Name',title_text)

switch handles.guiState
    case 'open'
        set(handles.actionButton,'String',actionButtonText,'Visible','off')
        set(handles.infoText,'String',infoText)
        set(handles.buttonPanel,'Visible','off')
    case 'info'
        set(handles.actionButton,'String',actionButtonText,'Visible','on')
        set(handles.ExitButton,'String',exitbuttontext,'Visible','off')
        set(handles.infoText,'String',infoText)
        set(handles.buttonPanel,'Visible','off')
        uiwait(handles.figure1)
    case 'trial'
        set(handles.actionButton,'String',actionButtonText,'Visible','off')
        set(handles.ExitButton,'String',exitbuttontext,'Visible','off')
        set(handles.infoText,'String',infoText)
        set(handles.buttonPanel,'Visible','off')       
    case 'response'
        set(handles.actionButton,'String',actionButtonText,'Visible','off')
        set(handles.ExitButton,'String',exitbuttontext,'Visible','off')
        set(handles.infoText,'String',infoText)
        set(handles.buttonPanel,'Visible','on')
        for ncat = 1:length(buttonText(1,:))
            for nButton = 1:length(buttonText(:,1))
                if nButton == curr_col
                    eval(['set(handles.b',num2str(nButton),num2str(ncat),',''String'',buttonText{nButton, ncat},''Visible'',''on'',''Enable'',''on'')'])
                else
                    eval(['set(handles.b',num2str(nButton),num2str(ncat),',''String'',buttonText{nButton, ncat},''Visible'',''on'',''Enable'',''off'')'])
                end
            end
        end
        uiwait(handles.figure1)
    case 'exit'
        set(handles.actionButton,'String',actionButtonText,'Visible','on')
        set(handles.ExitButton,'String',exitbuttontext,'Visible','on')
        set(handles.infoText,'String',infoText)
        set(handles.buttonPanel,'Visible','off')
        uiwait(handles.figure1)
end


% --- Outputs from this function are returned to the command line.
function varargout = buttonColumnGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
switch handles.guiState
    case 'response'
        varargout{1} = handles.response;
    case 'open'
        varargout{1} = handles.output;
    case 'close'
        delete(handles.figure1);
    case 'info'
        varargout{1} = handles.output;
    case 'exit'
        varargout{1} = handles.output;
        
end


% --- Executes on button press in actionButton.
function button_Callback(hObject, eventdata, handles)
% hObject    handle to actionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end
    


% --- Executes on button press in actionButton.
function actionButton_Callback(hObject, eventdata, handles)
% hObject    handle to actionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1)
    case 'exit'
        handles.output = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end


% --- Executes on button press in b21.
function b21_Callback(hObject, eventdata, handles)
% hObject    handle to b21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b22.
function b22_Callback(hObject, eventdata, handles)
% hObject    handle to b22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b23.
function b23_Callback(hObject, eventdata, handles)
% hObject    handle to b23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b24.
function b24_Callback(hObject, eventdata, handles)
% hObject    handle to b24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b25.
function b25_Callback(hObject, eventdata, handles)
% hObject    handle to b25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b26.
function b26_Callback(hObject, eventdata, handles)
% hObject    handle to b26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b27.
function b27_Callback(hObject, eventdata, handles)
% hObject    handle to b27 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b28.
function b28_Callback(hObject, eventdata, handles)
% hObject    handle to b28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b31.
function b31_Callback(hObject, eventdata, handles)
% hObject    handle to b31 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b32.
function b32_Callback(hObject, eventdata, handles)
% hObject    handle to b32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b33.
function b33_Callback(hObject, eventdata, handles)
% hObject    handle to b33 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b34.
function b34_Callback(hObject, eventdata, handles)
% hObject    handle to b34 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b35.
function b35_Callback(hObject, eventdata, handles)
% hObject    handle to b35 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b36.
function b36_Callback(hObject, eventdata, handles)
% hObject    handle to b36 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b37.
function b37_Callback(hObject, eventdata, handles)
% hObject    handle to b37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b38.
function b38_Callback(hObject, eventdata, handles)
% hObject    handle to b38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b41.
function b41_Callback(hObject, eventdata, handles)
% hObject    handle to b41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b42.
function b42_Callback(hObject, eventdata, handles)
% hObject    handle to b42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b43.
function b43_Callback(hObject, eventdata, handles)
% hObject    handle to b43 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b44.
function b44_Callback(hObject, eventdata, handles)
% hObject    handle to b44 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b45.
function b45_Callback(hObject, eventdata, handles)
% hObject    handle to b45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b46.
function b46_Callback(hObject, eventdata, handles)
% hObject    handle to b46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b47.
function b47_Callback(hObject, eventdata, handles)
% hObject    handle to b47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b48.
function b48_Callback(hObject, eventdata, handles)
% hObject    handle to b48 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b51.
function b51_Callback(hObject, eventdata, handles)
% hObject    handle to b51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b52.
function b52_Callback(hObject, eventdata, handles)
% hObject    handle to b52 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b53.
function b53_Callback(hObject, eventdata, handles)
% hObject    handle to b53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b54.
function b54_Callback(hObject, eventdata, handles)
% hObject    handle to b54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b55.
function b55_Callback(hObject, eventdata, handles)
% hObject    handle to b55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b56.
function b56_Callback(hObject, eventdata, handles)
% hObject    handle to b56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b57.
function b57_Callback(hObject, eventdata, handles)
% hObject    handle to b57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end

% --- Executes on button press in b58.
function b58_Callback(hObject, eventdata, handles)
% hObject    handle to b58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1);
    case 'response'
        handles.response = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end


% --- Executes on button press in ExitButton.
function ExitButton_Callback(hObject, eventdata, handles)
% hObject    handle to ExitButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
switch handles.guiState
    case 'info'
        uiresume(handles.figure1)
    case 'exit'
        handles.output = get(hObject,'String');
        guidata(hObject,handles);
        uiresume(handles.figure1)
end


