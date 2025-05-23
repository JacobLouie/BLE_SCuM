% Raw binary data needs to be inversed
% 1 = Invert 
% 0 = No Invert
Inverse_Data = 0;

MFDATALENGTH = 120000;%220000;%25000;%31250;%19000;%2000;
VerilogMFOut = readtable('VerilogMFOut');

if exist('VerilogMFOut','var') == 1
        if (istable( VerilogMFOut ) == 1)
            VerilogMFOut = table2array(VerilogMFOut);
        end
end  


if exist('FPGAoutput','var') == 1
        if (istable( FPGAoutput ) == 1)
            FPGAoutput = table2array(FPGAoutput);
        end
end  

DataToSearch = VerilogMFOut(1:MFDATALENGTH);
%DataToSearch = FPGAoutput(1:MFDATALENGTH);

if (Inverse_Data == 1)
    strBin = num2str(~DataToSearch);            % invert binary (1->0, 0->1)
else
    strBin = num2str(DataToSearch);                 % Convert Binary MF data to char
end

% ADV_IND
%HexKey = ["556b7d9171b12373cc31328d04ee0ce872f924dd6dd05b75f4391119a8cdf476"];
% Test Packets
HexKey = ["556b7d9171f14373cc31328d04ee0c2872f924dd6dd05b437ef6"];
%HexKey = ["F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F"];
BinKey = hexToBinaryVector(HexKey,strlength(HexKey)*4);         % Full key search
BinKeySTR = strrep(num2str(BinKey(1:end)), ' ', '');
searchSTR = BinKeySTR;
BinKey = reshape(BinKeySTR.'-'0',1,[]);
         
strBin=convertCharsToStrings(strBin);       % Convert Char values to string/text
FindLocations = strfind(strBin,searchSTR);  % Search for data
disp( " " + FindLocations);

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

totScore = Score + Score2;
stem(corrOffset,totScore);
%{
if (FindLocations > 0)
title("xcorr With Binary Key," + ...
    " MF Packets Found = " + length(FindLocations) + " @ " + FindLocations);
else
     title("xcorr With Binary Key," + ...
    " MF Packets Found = 0");
end
%}
ylabel('Score (Max = Packet Length)'); xlabel('Bit Number');
xlim([-230 MFDATALENGTH]);

ylim([0 length(BinKey)*1.05])
fontsize(gcf,24,"points");
disp("------------------------------------------------------")
% Chip error rate calc
chipCount = 0;
packCount = 0;
for i = 1:length(totScore)
    if totScore(i) >= 150
        chipCount = chipCount + totScore(i);
        packCount = packCount + 1;
    end
end

%packCount = floor(MFDATALENGTH/208);
disp("Packets Found: " + FindTotal + " of " + packCount);

%TotChip = MFDATALENGTH;
TotChip = length(BinKey)*packCount;
disp("Chip Rate: " + chipCount + "/" + TotChip + " = " + chipCount/TotChip);
%disp("@-60dBm");


