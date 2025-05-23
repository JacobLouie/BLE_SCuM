#Clock
create_clock -period 62.5 -name clk [get_ports clk];

##Pmod Header JB
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports clk];               #JB[10]

##Switches
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {select[0]}];       #SW[0]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {select[1]}];       #SW[1]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports rst];               #SW[15]

##Pmod Headers
##Pmod Header JA
set_property -dict {PACKAGE_PIN C17 IOSTANDARD LVCMOS33} [get_ports {I_BPF[0]}];        #JA[1]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {I_BPF[1]}];        #JA[2]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {I_BPF[2]}];        #JA[3]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {I_BPF[3]}];        #JA[4]
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports {Q_BPF[0]}];        #JA[7]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {Q_BPF[1]}];        #JA[8]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {Q_BPF[2]}];        #JA[9]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {Q_BPF[3]}];        #JA[10]

## LEDs
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {LED[0]}];          #LED[0]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {LED[1]}];          #LED[1]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports packet_detectedLED];#LED[2]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {LED[2]}];          #LED[15]

##Pmod Header JC
#DRIVE 16 SLEW FAST
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports clk_Debug];       #JC[4]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports value];           #JC[3]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports update];          #JC[2]
set_property -dict {PACKAGE_PIN E7 IOSTANDARD LVCMOS33 DRIVE 8 SLEW SLOW} [get_ports packet_trigger];   #JC[7]

##Pmod Header JD
#DRIVE 16 SLEW FAST
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {I_Debug[0]}];                        #JD[1]
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {I_Debug[1]}];                        #JD[2]
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {I_Debug[2]}];                        #JD[3]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {I_Debug[3]}];                        #JD[4]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {Q_Debug[0]}];                        #JD[7]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {Q_Debug[1]}];                        #JD[8]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {Q_Debug[2]}];                        #JD[9]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33 DRIVE 16 SLEW FAST} [get_ports {Q_Debug[3]}];                        #JD[10]

