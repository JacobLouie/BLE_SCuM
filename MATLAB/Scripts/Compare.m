clf
%flag
shift  = 39;

I_bad = data.bad;
I_good = data.good;

ADC_clock = 1/16; % micro second scale
xLIMlow = 10;
xLIMhigh = xLIMlow+15;
xAxis = linspace(0,ADC_clock*length(I_bad),length(I_bad));

plot(xAxis(1:length(I_bad)-(shift-1)),I_bad(1:length(I_bad)-(shift-1)),Color="r",LineStyle="-",LineWidth=2);
hold on;
plot(xAxis(1:length(I_bad)-(shift-1)),I_good(shift:length(I_bad))*-1,Color="b",LineStyle="-",LineWidth=2);
hold on;
title("I 2's complement (Bad vs Good data)");
ylabel('4 bit signed amplitude'); xlabel('Time (µ secs)');
set(gca,'FontSize',20);
ylim([-8.25 7.25]);
xlim([xLIMlow xLIMhigh]);
legend("Bad Data(new)","Good Data(old)")




