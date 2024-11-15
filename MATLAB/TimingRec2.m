

% Flags 
% 802.15.4 mode = 1 (2MHz-3MHz)
% BLE mode = 0 (2MHz-2.5MHz)
% BLE mode = 2 (1.5MHz-2MHz)
% BLE mode = 3 (1MHz-1.5MHz)
MODE = 1;

% Raw binary data needs to be inversed
% 1 = Invert 
% 0 = No Invert
Inverse_Data = 1;

%for OFFSET = 0:7
OFFSET  = 0;

% Templates were made in another matlab file (Template.m)
%3MHz Templates
%Cos3MHzTemp     = [1023;391;-723;-945;0;945;723;-391;-1023;-391;723;945;0;-945;-723;391];
Cos3MHzTemp     = [15;6;-11;-14;0;14;11;-6;-15;-6;11;14;0;-14;-11;6];
%Sin3MHzTemp     = [0;945;723;-391;-1023;-391;723;945;0;-945;-723;391;1023;391;-723;-945];
Sin3MHzTemp     = [0;14;11;-6;-15;-6;11;14;0;-14;-11;6;15;6;-11;-14];

% 2MHz Templates
%Cos2MHzTemp     = [1023;723;0;-723;-1023;-723;0;723;1023;723;0;-723;-1023;-723;0;723];
Cos2MHzTemp     = [15;11;0;-11;-15;-11;0;11;15;11;0;-11;-15;-11;0;11];
%Sin2MHzTemp     = [0;723;1023;723;0;-723;-1023;-723;0;723;1023;723;0;-723;-1023;-723];
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

DATA_LENGTH = 8;
MFDATALENGTH = 2000;
BUFFER_SIZE = 11;

I_data              = zeros(1,length(data.y),'double')';
Q_data_RAW          = zeros(1,length(data.y),'double')';
% Signed buffer
for i = 1:length(data.y)
    tempStringI = dec2bin(data.y(i),8);
    if tempStringI(5) - '0' == 1
        tempStringI = ['1111',tempStringI(5:8)];
    end
    I_data(i) = typecast(uint8(bin2dec(tempStringI)),'int8');
end

% Make Q data
deriv = diff(I_data);
tdata = I_data(2:end) + 1j * deriv;
Q_data = imag(tdata);
%Q_data = [0;Q_data];
I_data = real(tdata);

for i = 1:length(Q_data)
    tempStringQ = dec2bin(Q_data(i),8);
    if tempStringQ(5) - '0' == 1
        tempStringQ = ['0000',tempStringQ(5:8)];
    end
    Q_data_RAW(i) = typecast(uint8(bin2dec(tempStringQ)),'int8');
end

%Timing Recovery constants
sample_point    = 1; %1
e_k_shift       = 2; %2
tau_shift       = 11; %11
%{
%disp("Sample Point: " + sample_point)
disp("e_k_shift: " + e_k_shift);
disp("tau_shift: " + tau_shift);
disp("----------------------------------------");
for sample_point = 0:11
%}

% --------------------------------------------------------
MF_Output           = zeros(1,MFDATALENGTH,'double')';
value               = zeros(1,MFDATALENGTH,'double')';
dataCount = 1;
% --------------------------------------------------------


I_k = zeros(BUFFER_SIZE,1,'double')';
Q_k = zeros(BUFFER_SIZE,1,'double')';


y1 = 0;
y2 = 0;
e_k = 0;
tau_int_1 = 0;
tau_1 = 0;
dtau = 0;
i_1 = 0;
q_1 = 0;
i_2 = 0;
q_2 = 0;
i_3 = 0;
q_3 = 0;
i_4 = 0;
q_4 = 0;
adjust = 0;
shift_counter = 0;
update_data = 0;

for i = 1:MFDATALENGTH*8
    I_k(1:BUFFER_SIZE-1) = I_k(2:BUFFER_SIZE);
    Q_k(1:BUFFER_SIZE-1) = Q_k(2:BUFFER_SIZE);

    I_k(BUFFER_SIZE) = I_data(i);
    Q_k(BUFFER_SIZE) = Q_data(i);

     %MF
    if(update_data == 1)
        sum1_cos = 0;
        sum2_sin = 0;
        sum3_cos = 0;
        sum4_sin = 0;
        sum5_cos = 0;
        sum6_sin = 0;
        sum7_cos = 0;
        sum8_sin = 0;
            for j = 1:DATA_LENGTH
                % Low MHz
                sum1_cos = sum1_cos + TemplateCos1(j) * I_k(3+j);
                sum2_sin = sum2_sin + TemplateSin1(j) * I_k(3+j);
                sum5_cos = sum5_cos + TemplateCos1(j) * Q_k(3+j);
                sum6_sin = sum6_sin + TemplateSin1(j) * Q_k(3+j);
                % %High MHz
                sum3_cos = sum3_cos + TemplateCos2(j) * I_k(3+j);
                sum4_sin = sum4_sin + TemplateSin2(j) * I_k(3+j);
                sum7_cos = sum7_cos + TemplateCos2(j) * Q_k(3+j);
                sum8_sin = sum8_sin + TemplateSin2(j) * Q_k(3+j);
            end
            
        % Low MHz
        sum1_squared_cos = sum1_cos * sum1_cos;
        sum2_squared_sin = sum2_sin * sum2_sin;
        sum5_squared_cos = sum5_cos * sum5_cos;
        sum6_squared_sin = sum6_sin * sum6_sin; 
        % High MHz
        sum3_squared_cos = sum3_cos * sum3_cos; 
        sum4_squared_sin = sum4_sin * sum4_sin;
        sum7_squared_cos = sum7_cos * sum7_cos; 
        sum8_squared_sin = sum8_sin * sum8_sin;
    
        % Add squared scores together
        Low_MHz_Score(i) = sum1_squared_cos + sum2_squared_sin + sum5_squared_cos + sum6_squared_sin;
        % Add squared scores together
        High_MHz_Score(i) = sum3_squared_cos + sum4_squared_sin + sum7_squared_cos + sum8_squared_sin; 

        % Use this to compare to SCUM value
        %MF_Output(i) = bin2dec(num2str([bitget(High_MHz_Score(i),16:-1:13),bitget(Low_MHz_Score(i),16:-1:13)]));
        if Low_MHz_Score(i) > High_MHz_Score(i)
            value(dataCount) = 0;
        else
            value(dataCount) = 1;
        end
        dataCount = dataCount + 1;
    end  
    

    % Do error calc
    if (shift_counter == mod(7 + dtau,8))

        do_error_calc = 1;
        shift_counter = 0;

        i_1 = I_k(9);
	    q_1 = Q_k(9);
	    
	    i_2 = I_k(1);
	    q_2 = Q_k(1);
	    
	    i_3 = I_k(11);
	    q_3 = Q_k(11);
    
	    i_4 = I_k(3);
	    q_4 = Q_k(3);

        %}
        dtau = tau_1 - tau;
        tau_int_1 = tau_int;
	    tau_1 = tau;        
		

        %debug
        
        if dtau ~= 0
            %disp(dtau);
            %disp(i)
            adjust(i) = i;
        end
        

    % Don't error calc
    else 
        do_error_calc = 0;
        shift_counter = shift_counter + 1;
    end

    if shift_counter == sample_point
        update_data = 1;
    else
        update_data = 0;
    end


    y1 = (i_1*i_1 - q_1*q_1)  * (i_2*i_2 - q_2*q_2) + 4*(i_1*q_1*i_2*q_2);
    y2 = (i_3*i_3 - q_3*q_3)  * (i_4*i_4 - q_4*q_4) + 4*(i_3*q_3*i_4*q_4);

    e_k = y1 - y2;



	%tau_int = tau_int_1 - (e_k >>> e_k_shift); % Verilog version
    tau_int = tau_int_1 - typecast(int32(bitshift(fi(e_k,1,32,0),e_k_shift*-1)),'int32');
	%tau = tau_int >>> tau_shift; % Verilog version
    tau = typecast(int32(bitshift(fi(tau_int,1,32,0),tau_shift*-1)),'int32');
    
end
Low_MHz_Score = nonzeros(Low_MHz_Score');
High_MHz_Score = nonzeros(High_MHz_Score');
difference = Low_MHz_Score-High_MHz_Score;
%{
updateNow = find(update_data == 1);
diffUpdateData = zeros(1,length(updateNow),'double')';
diffUpdateData(2:end) = diff(updateNow);
diffUpdateData(1) = sample_point;
%}
% -----------------------------------------------------------------------------------------
if exist('VerilogMFOut','var') == 1
        if (istable( VerilogMFOut ) == 1)
            VerilogMFOut = table2array(VerilogMFOut);
        end
end  

% Search for Full Packets

%DataToSearch = value;
DataToSearch = VerilogMFOut(1:2000);
if (Inverse_Data == 1)
    strBin = num2str(~DataToSearch);            % invert binary (1->0, 0->1)
else
    strBin = num2str(DataToSearch);                 % Convert Binary MF data to char
end


HexKey = ["1556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6"];
BinKey = hexToBinaryVector(HexKey);         % Full key search
BinKeySTR = strrep(num2str(BinKey(2:end)), ' ', '');
searchSTR = BinKeySTR;
BinKey = reshape(BinKeySTR.'-'0',1,[]);
         
strBin=convertCharsToStrings(strBin);       % Convert Char values to string/text
FindLocations = strfind(strBin,searchSTR);  % Search for data
disp(OFFSET + " " + FindLocations);

FindTotal = 0;
if (FindLocations > 0)
    FindTotal = FindTotal + length(FindLocations);
end

% correlation with BinKey to binary data.
if (Inverse_Data == 1)
    [Score,corrOffset] = xcorr(~DataToSearch,BinKey);
    % inverse
    [Score2,corrOffset2] = xcorr(DataToSearch,~BinKey);
else
    [Score,corrOffset] = xcorr(DataToSearch,BinKey);
    % inverse
    [Score2,corrOffset2] = xcorr(~DataToSearch,~BinKey);
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
ylim([0 250])
fontsize(gcf,24,"points");

%disp("Sample Point: " + sample_point)
%disp("e_k_shift: " + e_k_shift);
%disp("tau_shift: " + tau_shift);
disp("Total: " + FindTotal);
disp("----------------------------------------");
%end
