%Flag
% 1 = plot FFT of 2's Compliment
% 0 = plot FFT of RAW ADC
twoComp = 1;

%Flag
%Plot 2's Compliment
% 1 = filter is on
% 0 = filter is off
filtOn = 0;

if (twoComp == 1)
    tempData = arraysignedData;
else
    tempData = data.y;
end


if (filtOn == 1)
    fc = 4.5e6; %cutoff frequency
    %fc = 7e6; %cutoff frequency
    fs = 16e6;
    [z,p,k] = butter(4,fc/(fs/2));
    sos = zp2sos(z,p,k);
    tempData = filtfilt(sos, 1, tempData);
end

y = abs(fft(tempData));
x = (0:length(y)-1) * 16/length(y);
clf;
fig = plot(x,y);
hold on;
fontsize(24, "points");
%title("FFT 4 1's 4 0's ", 'FontSize', 24);
%title("SCUM37@BIT data 802.15.4 MOD ", 'FontSize', 24);
title("SCUM37@BIT data 802.15.4 MOD (Filtered)", 'FontSize', 24);
%title("SCUM37@BIT data 802.15.4 MOD 2's complement", 'FontSize', 24);
%title("SCUM37@BIT data 802.15.4 MOD 2's complement (After ADC RAW Filter)", 'FontSize', 24);
xlabel('Frequency (MHz)', 'FontSize', 24);
xlim([0 8]);
ylim([0 5500]);

if (twoComp == 0)
    data.y = round(tempData);
end



