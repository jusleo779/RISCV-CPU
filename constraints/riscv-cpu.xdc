
## Clock signal
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports {clk}]; #100mHz clock
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}];

## Buttons
set_property -dict { PACKAGE_PIN D9    IOSTANDARD LVCMOS33 } [get_ports {reset}]; #btn[0]

## Switches
set_property -dict { PACKAGE_PIN A8    IOSTANDARD LVCMOS33 } [get_ports {switches[0]}]; #switch 0
set_property -dict { PACKAGE_PIN C11   IOSTANDARD LVCMOS33 } [get_ports {switches[1]}]; #switch 1
set_property -dict { PACKAGE_PIN C10   IOSTANDARD LVCMOS33 } [get_ports {switches[2]}]; #switch 2
set_property -dict { PACKAGE_PIN A10   IOSTANDARD LVCMOS33 } [get_ports {switches[3]}]; #switch 3

## LEDs
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led_reg[0] }]; #led 0
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { led_reg[1] }]; #led 1
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { led_reg[2] }]; #led 2
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { led_reg[3] }]; #led 3

## LEDS RGB
set_property -dict { PACKAGE_PIN K1    IOSTANDARD LVCMOS33 } [get_ports { halted }]; # led3 red