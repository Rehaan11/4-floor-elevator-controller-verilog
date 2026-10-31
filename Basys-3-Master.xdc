## Basys 3 Master XDC — Four-Floor Elevator Controller
## Target: Digilent Basys 3 (Artix-7)
## Top module ports must match elevator_controller.v exactly.
## SW0..SW3 request floors 0..3; BTNC is active-high synchronous reset.
## LD0..LD1 show current_floor; LD2 direction; LD3 motor; LD4 door;
## LD5..LD8 pending requests; LD9..LD11 FSM state.
## 100 MHz clock = 10 ns period.

## 100 MHz onboard clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports {clk}]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {clk}]

## Center pushbutton reset (BTNC)
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {rst}]

## Floor request switches SW0..SW3
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports {floor_req[0]}]
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports {floor_req[1]}]
set_property -dict { PACKAGE_PIN W16 IOSTANDARD LVCMOS33 } [get_ports {floor_req[2]}]
set_property -dict { PACKAGE_PIN W17 IOSTANDARD LVCMOS33 } [get_ports {floor_req[3]}]

## Current floor: LD0..LD1
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {current_floor[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {current_floor[1]}]

## Direction, motor enable, door open: LD2..LD4
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {direction_up}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {motor_enable}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {door_open}]

## Pending requests: LD5..LD8
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {pending_requests[0]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {pending_requests[1]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {pending_requests[2]}]
set_property -dict { PACKAGE_PIN V13 IOSTANDARD LVCMOS33 } [get_ports {pending_requests[3]}]

## FSM state debug: LD9..LD11
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports {state_dbg[0]}]
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports {state_dbg[1]}]
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports {state_dbg[2]}]

## Basys 3 configuration properties
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
