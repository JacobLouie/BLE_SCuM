%switches
startInterval = 1;
endInterval =  300000;%19900;%900000;%2500;
middleFreq = 2.50e+06;
adcCLKperiod = (62.5*10^-9);
risingEdgeOffset = 0; %time in uS
floor = 1;
xtickFlag = .5;


%make data start at 0
data.x = data.x - data.x(1);

%microSecond Scale
xScaleEnd = data.x(endInterval)/10^-6;
xScaleEnd=round(xScaleEnd);
%microSecondsX = 0 + (0:xScaleEnd-1);%*10^6
microXscale10 =  0 + (0:endInterval/10)*10;
microXscale1 =  0 + (0:endInterval)*1;

%change scale
data.x = data.x * 10^6;


%plot data
subplot(2,1,1);
t = plot(data.x(startInterval:endInterval), ...
    data.y(startInterval:endInterval));
hold on;
if xtickFlag == 1
    set(gca,'xtick',microXscale10);
end
set(gca,'FontSize',20);
%set(t,"LineWidth",1.5);
set(t,'Color', 'k');

%microY = zeros(1,xScaleEnd) + 127;
%scatter(microSecondsX,microY);
clear microY;
%grid on;


%ylabel('4 bit data(0-15)'); xlabel('Time (µ secs)');
ylabel('8 bit MF Output'); xlabel('Time (µ secs)');
xlim([data.x(startInterval) data.x(endInterval)]);
ylim([min(data.y) max(data.y)+2]);

%TITLE
%title("SCUM37@bit Packet, 500KHz Frequency Deviation, -40 dBm");
%title("4 1's 4 0's (Frequency Deviation = 250 kHz)(symbol Rate = 1Msps) -40 dBm (nRF 5V power source)");
%title("1 and 0's for 1 second (1) (Frequency Deviation = 250 kHz)(symbol Rate = 1Msps)(nRF 5V power source) -40 dBm ");
%title("-90dbm (4 1's 4 0's)  (Frequency Deviation = 250 kHz)(symbol Rate = 1Msps)");
%title("4 1's 4 0's (-40dbm)(Frequency Deviation = 250 kHz)(symbol Rate = 1Msps) (nRF 5V power source)");
%title("LC Current  = 120, LC Voltage = 120 (ALL 0's)");
%title("Noise");
%title("1 and 0's for 1 second");
%title("all 0's (-60 dBm)(power supply source)");
%title("Matched Filter Bits, Bluetooth Settings");
%title("SCUM to SCUM 802.15.4");
%title("802.15.4 packet");
%title("SCUM BLE Transmit to SCUM ADC");

title("4 1's 4 0's (Frequency Deviation = 500 kHz)(symbol Rate = 2Msps)(-40 dBm)");
%title("4 1's 4 0's (Frequency Deviation = 250 kHz)(symbol Rate = 1Msps)(-40 dBm)");
%title("4 1's 4 0's (MF OUT)(Frequency Deviation = 500 kHz)(symbol Rate = 2Msps)(-40 dBm)");
%title("4 1's 4 0's (MF OUT)(Frequency Deviation = 250 kHz)(symbol Rate = 1Msps)(-40 dBm)");
hold off;


%get period and frequency
halfMax = 0.5 *(min(data.y(startInterval:endInterval)) + max(data.y(startInterval:endInterval)));
highSig = data.y(startInterval:endInterval) > halfMax;
diffSig = [0;diff(highSig)];
diffSigIndex = find(diffSig == 1);

periodArray = [0;diff(diffSigIndex)];
sizeOfPeriodArray = size(periodArray,1);
Periodplot = zeros(endInterval,1);
counter = 1;

%fill period data to match x-axis of data
for t = 1:(diffSigIndex(1) - 1);
    Periodplot(t) = periodArray(2);
    counter = counter + 1;
end
for i = 2:sizeOfPeriodArray
    for p = 1:periodArray(i)
        %filter (make floor)
        if periodArray(i) < floor
           periodArray(i) = periodArray(i-1);
        end
    Periodplot(counter) = periodArray(i);
    counter = counter + 1;
    end
end

for i = counter:endInterval
    Periodplot(i) = periodArray(sizeOfPeriodArray);
end
%{
%plot period
subplot(2,1,1);
p = plot(data.x(startInterval:endInterval),Periodplot,'LineWidth',1.5);
hold on;

if xtickFlag == 1
    set(gca,'xtick',microXscale10);
end
set(p,'Color', [0.850 0.325 0.098]);
microY = zeros(1,xScaleEnd) + (middleFreq^-1 / adcCLKperiod);
%scatter(microSecondsX,microY);
clear microY;
%grid on;

title("Period");
ylabel('Count'); xlabel('Time (µ secs)');
xlim([data.x(startInterval) data.x(endInterval)]);
hold off;
%}

%make frequency array
frequencyPlot = adcCLKperiod * Periodplot();
frequencyPlot = (frequencyPlot.^-1);
frequencyPlotY = frequencyPlot * 10^-6;

%frequencyPlot = filloutliers(frequencyPlot,"nearest","mean");

% need to make first few number 0 so I don't get Inf when i do ^-1
%for t = 1:(diffSigIndex(1) - 1);
%    frequencyPlot(t) = frequencyPlot(diffSigIndex);
%end

subplot(2,1,2);
f = plot(data.x(startInterval:endInterval),frequencyPlotY,'LineWidth',1.5);
hold on;

if xtickFlag == 1
    set(gca,'xtick',microXscale10);
end
set(gca,'FontSize',20);
set(f,"LineWidth",1.9);
set(f,'Color', [0 0.4770 0.7410]);
yline(middleFreq * 10^-06,'--','LineWidth',2);

%microY = zeros(1,xScaleEnd) + middleFreq;
%scatter(microSecondsX,microY);
clear microY;
%grid on;

% 1 or 0
%halfMaxFreq = 0.5 *(min(frequencyPlot(startInterval:endInterval)) + 3.4*min(frequencyPlot(startInterval:endInterval)));
%highOrLow = frequencyPlot(startInterval:endInterval) > halfMaxFreq;
halfMaxFreq = middleFreq;
highOrLow = frequencyPlot(startInterval:endInterval) > middleFreq;

%title("4 1's & 4 0 's, Frequency (" + halfMaxFreq*10^-6 + "MHz border), 157.5 Frequency Deviation, 1Msps, ");
title("Frequency, Border = " + halfMaxFreq*10^-6 + " MHz");
minf = min(frequencyPlotY) - 0.2 * min(frequencyPlotY);
ylabel('Frequency (MHz)'); xlabel('Time (µ secs)');
ylim([minf*1.2 max(frequencyPlotY)*1.05]);
%ylim([1.55 2.7]);
%ylim([1.2 2.35]);
xlim([data.x(startInterval) data.x(endInterval)]);
hold off;


%{
subplot(3,1,3);
d = plot(data.x(startInterval:endInterval),highOrLow,'LineWidth',1.5);
hold on;

if xtickFlag == 1
    set(gca,'xtick',microXscale10);
end
set(gca,'ytick',[0 1]);
set(d,'Color', [0.850 0.325 0.98]);
microY = zeros(1,xScaleEnd) + 1;
%scatter(microSecondsX,microY);
clear microY;
%grid on;

title("Decoded Data");
ylabel('1 or 0'); xlabel('Time (µ secs)');
ylim([0 1.2]);
xlim([data.x(startInterval) data.x(endInterval)]);
hold off;
%}

%clear adcCLKperiod; clear frequencyPlotY; clear frequencyPlot; clear microSecondsX;
%clear periodArray; clear Periodplot; clear diffSig; clear diffSigIndex; 
%clear highSig; clear microXscale10; clear microXscale1;
%clear minf; clear p; clear f; clear halfMax; clear i; clear sizeOfPeriofArray;
%clear t; clear xScaleEnd; clear halfMaxFreq; clear middleFreq; clear d;

%decode square wave to binary
%{
decodediff = [0;diff(highOrLow)];
decodeindex1 = find(decodediff == 1);
decodeindexN1 = find(decodediff == -1);
%make arrays the same size
if (length(decodeindex1) > length(decodeindexN1)) 
    decodeindex1 = decodeindex1(1:end-1,:);
    
elseif (length(decodeindex1) < length(decodeindexN1)) 
    decodeindexN1 = decodeindexN1(1:end-1,:);
end
if (decodeindexN1(1) < decodeindex1(1))
    decodeZeros = data.x(decodeindex1)-data.x(decodeindexN1);
    decodeZeros = round(decodeZeros);
else
    decodeOnes = data.x(decodeindexN1)-data.x(decodeindex1);
    decodeOnes = round(decodeOnes);
end
counter = 1;
while (counter <= length(decodeindexN1))
   
    if (counter == 1) 
        %data starts high
        if (decodeindexN1(1) < decodeindexN1(1))
            %create first string of ones
            tempones = data.x(decodeindexN1(1))-data.x(1);
            tempones = round(tempones);
            decodeData = ones(tempones,1,'double');
            %create first string of zeros
            tempzero = data.x(decodeindex1(1))-data.x(decodeindexN1(1));
            tempzero = round(tempzero);
            tempzero = zeros(tempzero,1,'double');
            decodeData = [decodeData; tempzero];
        %data start low
        else
            %create first string of zeros
            tempzero = data.x(decodeindex1(1))-data.x(1);
            tempzero = round(tempzero);
            decodeData = zeros(tempzero,1,'double');
            %create first string of ones
            tempones = data.x(decodeindexN1(1))-data.x(decodeindex1(1));
            tempones = round(tempones);
            tempones = ones(tempones,1,'double');
            decodeData = [decodeData; tempones];
        end
        counter = counter + 1;
    else
        %data starts high
        if (decodeindexN1(1) < decodeindex1(1))
            tempones = data.x(decodeindexN1(counter))-data.x(decodeindex1(counter-1));
            tempones = round(tempones);
            tempones = ones(tempones,1,'double');
            decodeData = [decodeData; tempones];
            tempzeros = zeros(decodeZeros(counter),1,'double');
            decodeData = [decodeData; tempzeros];
        %data start low
        else
            tempzero = data.x(decodeindex1(counter))-data.x(decodeindexN1(counter - 1));
            tempzero = round(tempzero);
            tempzero = zeros(tempzero,1,'double');
            decodeData = [decodeData; tempzero];
            tempones = ones(decodeOnes(counter),1,'double');
            decodeData = [decodeData; tempones];
        end
        counter = counter + 1;
    end


    
end


time = data.x(startInterval:endInterval);
time = round(time,1);
highOrLow = +highOrLow;
counter = 1;
while(counter < round(time(endInterval), TieBreaker="tozero"))
    temp = highOrLow(time == counter + risingEdgeOffset);
    if(temp == 1)
        if (counter == 1) decodeData = 1; end
        decodeData = [decodeData 1];
    else
        if (counter == 1) decodeData = 0; end
        decodeData = [decodeData 0];
    end
    counter = counter + 1;
end


%decodeData = decodeData';
decodeDataHex = binaryVectorToHex(~decodeData);

%left shift
%decodeData = [decodeData 0];
%decodeDataHex = binaryVectorToHex(decodeData);

%right shift
%decodeData = decodeData(1:end-1);
%decodeDataHex = binaryVectorToHex(decodeData);


%full search
strfind(decodeDataHex, '556B7D9171F14373CC31328D04EE0C2872F924DD6DD05B437EF6')
%search
%strfind(decodeDataHex, '56B7D9171')
%righshift
%strfind(decodeDataHex, 'B5BEC8B8')
%leftshift
%strfind(decodeDataHex, 'AD6FB22E')

%change scale
data.x = data.x / 10^6;
%}
clear counter; clear highOrLow; clear time;





