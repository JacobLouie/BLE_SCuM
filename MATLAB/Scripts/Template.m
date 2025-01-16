% Create sin and cos Template for _MHz signal
F1 = 3*10^6;     % 3MHz signal
%F1 = 2*10^6;     % 2MHz signal
%F1 = 2.5*10^6;   % 2.5MHz signal
%F1 = 1.5*10^6;   % 1.5MHz signal
%F1 = 1*10^6;     % 1MHz signal

%F1 = 3.5*10^6;   % 1.5MHz signal
%F1 = 4*10^6;   % 1.5MHz signal
%F1 = 1.6*10^6;   % 1.6MHz signal
%F1 = 1.75*10^6;  % 1.75MHz signal
%F1 = 4*10^6;     % 2MHz signal

% Magnitude
Magnitude = 15; % +-15
%Magnitude = 1023; % +-1000

% 1 = 802.15.4
% 2 = BLE
MODE = 1;
%---------------------------------------------------%
% Data rate
fs1 = 128*10^6; % 16MHz Clock (sampling frequency)
dt1 = 1/fs1;    % seconds per sample

if (MODE == 1) StopTime1 = 0.45e-6;  % need 8 samples for 802.15.4
else StopTime1 = 0.95e-6; end       % need 16 samples for BLE

t1 = (0:dt1:StopTime1)'; 
% For ploting
data1 = Magnitude*cos(2*pi*F1*t1); 
data2 = Magnitude*sin(2*pi*F1*t1);

%---------------------------------------------------%
% Sample rate
F2 = 16*10^6;   % 16MHz
t2 = (0:1/F2:StopTime1);
%---------------------------------------------------%
Template1 = zeros(1,length(t2),'double')';
Template2 = zeros(1,length(t2),'double')';

i = 1;
for t = t2
    Template1(i) = round(Magnitude*cos(2*pi*F1*t)); 
    Template2(i) = round(Magnitude*sin(2*pi*F1*t)); 
    i = i + 1;
end    
% clear figure
clf
% Plot cosine
plot(t1,data1,Color="b",LineWidth = 2);
hold on;
stem(t2,Template1,Color="b");
title("2MHz Cos", "FontSize",28, LineWidth = 2);
%hold on;
% Plot sine
plot(t1,data2,Color="r");
hold on;
stem(t2,Template2,Color="r");
%hold on;


% Verilog text
% Note: need to change the Template name "Template_Cos'XX'MHz"
for i = 1:length(Template1)
    % check if negative
    if Template1(i) < 0 
        VerilogCosTemplate(i,1) = "assign Template_Cos3MHz["+(i-1)+"] = -11'd"+(abs(Template1(i)))+";";
    else
        VerilogCosTemplate(i,1) = "assign Template_Cos3MHz["+(i-1)+"] = 11'd"+Template1(i)+";";
    end
    % check if negative
    if Template2(i) < 0 
        VerilogSinTemplate(i,1) = "assign Template_Sin3MHz["+(i-1)+"] = -11'd"+(abs(Template2(i)))+";";
    else
        VerilogSinTemplate(i,1) = "assign Template_Sin3MHz["+(i-1)+"] = 11'd"+Template2(i)+";";
    end
end

% MATLAB text
for i = 1:length(Template1)
    if i == 1
        MATLABCosTemplate = Template1(i);
        MATLABSinTemplate = Template2(i);
    else
        MATLABCosTemplate = MATLABCosTemplate + ";" + Template1(i);
        MATLABSinTemplate = MATLABSinTemplate + ";" + Template2(i);
    end
end



