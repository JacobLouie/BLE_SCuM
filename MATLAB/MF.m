% Note: Change the name of data set to "data", first column to "x"
%       and second column to "y".
%-----------------------------------------------------------------%
% Flags 
% 802.15.4 mode = 1 (2MHz-3MHz)
% BLE mode = 0 (2MHz-2.5MHz)
% BLE mode = 2 (1.5MHz-2MHz)
% BLE mode = 3 (1MHz-1.5MHz)
MODE = 0;

% Raw binary data needs to be inversed
% 1 = Invert 
% 0 = No Invert
Inverse_Data = 1;

% Data Length
% Note: will be half for BLE compared to 802.15.4
MFDATALENGTH = 2000;%20000; %5000

% --------------------------------------------------------
% Make data start at 0
data.x = data.x - data.x(1);
% Change scale
data.x = data.x * 10^6;
% Clear Figure
clf;
% --------------------------------------------------------
% Templates were made in another matlab file (Template.m)
%3MHz Templates
Cos3MHzTemp     = [15;6;-11;-14;0;14;11;-6;-15;-6;11;14;0;-14;-11;6];
Sin3MHzTemp     = [0;14;11;-6;-15;-6;11;14;0;-14;-11;6;15;6;-11;-14];

% 2MHz Templates
Cos2MHzTemp     = [15;11;0;-11;-15;-11;0;11;15;11;0;-11;-15;-11;0;11];
Sin2MHzTemp     = [0;11;15;11;0;-11;-15;-11;0;11;15;11;0;-11;-15;-11];

% 2.5MHz Templates
Cos25MHzTemp    = [15;8;-6;-15;-11;3;14;12;0;-12;-14;-3;11;15;6;-8];
Sin25MHzTemp    = [0;12;14;3;-11;-15;-6;8;15;8;-6;-15;-11;3;14;12];

% 1.5MHz Templates
Cos15MHzTemp    = [15;12;6;-3;-11;-15;-14;-8;0;8;14;15;11;3;-6;-12];
Sin15MHzTemp    = [0;8;14;15;11;3;-6;-12;-15;-12;-6;3;11;15;14;8];

% 1MHz Templates
Cos1MHzTemp    = [15;14;11;6;0;-6;-11;-14;-15;-14;-11;-6;0;6;11;14];
Sin1MHzTemp    = [0;6;11;14;15;14;11;6;0;-6;-11;-14;-15;-14;-11;-6];




% 802.15.4 mode
if MODE == 1 
    TemplateCos1 = Cos2MHzTemp(1:8);
    TemplateSin1 = Sin2MHzTemp(1:8);
    TemplateCos2 = Cos3MHzTemp(1:8);
    TemplateSin2 = Sin3MHzTemp(1:8);
% BLE mode (2MHz-2.5MHz)
elseif MODE == 0
    TemplateCos1 = Cos2MHzTemp;
    TemplateSin1 = Sin2MHzTemp;
    TemplateCos2 = Cos25MHzTemp;
    TemplateSin2 = Sin25MHzTemp;
% BLE mode (1.5MHz-2MHz)
elseif MODE == 2
    TemplateCos1 = Cos15MHzTemp;
    TemplateSin1 = Sin15MHzTemp;
    TemplateCos2 = Cos2MHzTemp;
    TemplateSin2 = Sin2MHzTemp;
% BLE mode (1MHz-1.5MHz)
elseif MODE == 3
    TemplateCos1 = Cos1MHzTemp;
    TemplateSin1 = Sin1MHzTemp;
    TemplateCos2 = Cos15MHzTemp;
    TemplateSin2 = Sin15MHzTemp;    
end

if (MODE == 1) DATA_LENGTH = 8; % 1/16MHz * 8 = 0.5uS
else DATA_LENGTH = 16; end      % 1/16MHz * 16 = 1uS

% total number of packets found
FindTotal = 0;

%for OFFSET = 0:7
OFFSET  = 0;
% --------------------------------------------------------
sum1_cos            = zeros(1,MFDATALENGTH,'double')';
sum2_sin            = zeros(1,MFDATALENGTH,'double')';
sum3_cos            = zeros(1,MFDATALENGTH,'double')';
sum4_sin            = zeros(1,MFDATALENGTH,'double')';

sum1_squared_cos    = zeros(1,MFDATALENGTH,'double')';
sum2_squared_sin    = zeros(1,MFDATALENGTH,'double')';
sum3_squared_cos    = zeros(1,MFDATALENGTH,'double')';
sum4_squared_sin    = zeros(1,MFDATALENGTH,'double')';

Low_MHz_Score       = zeros(1,MFDATALENGTH,'double')';
High_MHz_Score      = zeros(1,MFDATALENGTH,'double')';
MF_Output           = zeros(1,MFDATALENGTH,'double')';
value               = zeros(1,MFDATALENGTH,'double')';
xData               = zeros(1,MFDATALENGTH,'double')';
signedData          = zeros(1,16,'double')';
arraysignedData     = zeros(1,MFDATALENGTH*8,'double')';
arrayOther          = zeros(1,MFDATALENGTH*8,'double')';
DebugTempScore1     = zeros(DATA_LENGTH,MFDATALENGTH,'double')';
DebugTempScore2     = zeros(DATA_LENGTH,MFDATALENGTH,'double')';
DebugTempScore3     = zeros(DATA_LENGTH,MFDATALENGTH,'double')';
DebugTempScore4     = zeros(DATA_LENGTH,MFDATALENGTH,'double')';


    for i = 1:MFDATALENGTH
        for j = 1:DATA_LENGTH
            % Get string version of data.y index j
            % "...,8 <--" 8 bits format
            % ADC values or 0-15 = 4 bits total. I can't do 4 bit operations in
            % MATLAB I think.
            tempString = dec2bin(data.y(((i-1)*DATA_LENGTH + OFFSET)+j),8);
            % Check if most MSB is 1 (negative) (convert string to decimal (- '0'))
            % 5th element is now the MSB for the 4 bit part.
            if (tempString(5) - '0' == 1)
                % Fill uper 4 bits out of 8 bit value with 1's
                tempString = ['1111',tempString(5:8)];
            end
            % Convert 8 bit string into signed decimal
            tempString = typecast(uint16(bin2dec(tempString)), 'int8');
            signedData(j) = tempString(1);
            
            % debug
            arraysignedData((i*8)-8 + j) = signedData(j);
            arrayOther((i*8)-8 + j) = (data.y(((i-1)*8 + OFFSET)+j)-8);
    
            % Low MHz
            sum1_cos(i) = sum1_cos(i) + TemplateCos1(j) * signedData(j);
            DebugTempScore1(i,j) = TemplateCos1(j) * signedData(j);
            sum2_sin(i) = sum2_sin(i) + TemplateSin1(j) * signedData(j);
            DebugTempScore2(i,j) = TemplateSin1(j) * signedData(j);
            % %High MHz
            sum3_cos(i) = sum3_cos(i) + TemplateCos2(j) * signedData(j);
            DebugTempScore3(i,j) = TemplateCos2(j) * signedData(j);
            sum4_sin(i) = sum4_sin(i) + TemplateSin2(j) * signedData(j);
            DebugTempScore4(i,j) = TemplateSin2(j) * signedData(j);
    
        end
    
        % Low MHz
        sum1_squared_cos(i) = sum1_cos(i) * sum1_cos(i);
        sum2_squared_sin(i) = sum2_sin(i) * sum2_sin(i); 
        % High MHz
        sum3_squared_cos(i) = sum3_cos(i) * sum3_cos(i); 
        sum4_squared_sin(i) = sum4_sin(i) * sum4_sin(i);
    
        % Add squared scores together
        Low_MHz_Score(i) = sum1_squared_cos(i) + sum2_squared_sin(i);
        % Add squared scores together
        High_MHz_Score(i) = sum3_squared_cos(i) + sum4_squared_sin(i);  
        % Use this to compare to SCUM value;
        %MF_Output(i) = [High_MHz_Score()[16:13],Low_MHz_Score(16:13)];
        if Low_MHz_Score(i) > High_MHz_Score(i)
            value(i) = 0;
        else
            value(i) = 1;
        end
    end
    % -----------------------------------------------------------------------------------------
    % Comparing Verilog to MATLAB data output
    % plot
    %{
    xData = (1:MFDATALENGTH);
    if exist('VerilogMFOut','var') == 1
        if (istable( VerilogMFOut ) == 1)
            VerilogMFOut = table2array(VerilogMFOut);
        end
        subplot(2,1,1);
        plot(xData,VerilogMFOut(2:MFDATALENGTH+1));
        xlim([0, MFDATALENGTH]);
        %xlim([0, 200]);
        ylim([-0.1, 1.1]);
        xlabel('µS');
        ylabel('Binary Data');
        title("Verilog Output");
        hold on
        subplot(2,1,2);
    end    
    plot(xData,value);
    hold on
    
    xlim([0, MFDATALENGTH]);
    %xlim([0, 200]);
    ylim([-0.1, 1.1]);
    xlabel('µS');
    ylabel('Binary Data');
    title("MATLAB Output");
    %change scale
    data.x = data.x / 10^6;
    %}
    %{
    [Score,corrOffset] = xcorr(value,VerilogMFOut(2:MFDATALENGTH+1));
    [Score2,corrOffset2] = xcorr(~value,~VerilogMFOut(2:MFDATALENGTH+1));
    stem(corrOffset,Score + Score2);
    ylim([0 2050]);
    %}
    % -----------------------------------------------------------------------------------------
    % Search for Full Packets
    

    if (Inverse_Data == 1)
        strBin = num2str(~value);            % invert binary (1->0, 0->1)
    else
        strBin = num2str(value);                 % Convert Binary MF data to char
    end
    
    
    %strBin = num2str(~value);                 % invert binary (1->0, 0->1)
    
    
    % ASCII search (ASCII 48 = decimal 0)
    %ASCII48 = ["00110000" + "00110000"];    % String we are searching for 
    %ASCII48 = ["00110000"];                 % String we are searching for
    %ASCII48 = ["11001111" + "11001111"];    % String we are searching for (inverse)
    %ASCII48 = ["11001111"];                 % String we are searching for (inverse)
    %strBin=convertCharsToStrings(strBin);   % Convert Char values to string/text
    %FindLocations = strfind(strBin,ASCII48);% Search for data
    
    % SCUM37@BIT search
    % Hex Key: 0x556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6
    %searchSTR = ["0101010101101011"];          %0x556b
    HexKey = ["1556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6"];
    BinKey = hexToBinaryVector(HexKey);         % Full key search
    BinKeySTR = strrep(num2str(BinKey(2:end)), ' ', '');
    searchSTR = BinKeySTR;
    BinKey = reshape(BinKeySTR.'-'0',1,[]);
             
    strBin=convertCharsToStrings(strBin);       % Convert Char values to string/text
    FindLocations = strfind(strBin,searchSTR);  % Search for data
    disp(OFFSET + " " + FindLocations);

    if (FindLocations > 0)
        FindTotal = FindTotal + length(FindLocations);
    end
    
    % correlation with BinKey to binary data.
    if (Inverse_Data == 1)
        [Score,corrOffset] = xcorr(~value,BinKey);
        % inverse
        [Score2,corrOffset2] = xcorr(value,~BinKey);
    else
        [Score,corrOffset] = xcorr(value,BinKey);
        % inverse
        [Score2,corrOffset2] = xcorr(~value,~BinKey);
    end

    
    stem(corrOffset,Score + Score2);
    if (FindLocations > 0)
    title("OFFSET: " + OFFSET + ", xcorr With Binary Key," + ...
        " MF Packets Found = " + length(FindLocations) + " @ " + FindLocations);
    else
         title("OFFSET: " + OFFSET + ", xcorr With Binary Key," + ...
        " MF Packets Found = 0");
    end
    
    xlim([-230 2000]);
    fontsize(gcf,24,"points");
    
%end
disp("Total: " + FindTotal);

    
% -----------------------------------------------------------------------------------------
% debug plot
%{
clf
xData = (0: length(arraysignedData)-1);
subplot(2,1,1);
scatter(xData,arraysignedData);
%scatter(xData,arrayOther);
hold on;
plot(xData,arraysignedData);
%plot(xData,arrayOther);
hold on;
plot(xData,data.y(1:length(xData)));
xlabel('Sample Number');
ylabel('ADC Amplitude');
%}
%subplot(2,1,2);
%plot(xData, BinKey);




