# 4-Floor Elevator Controller in Verilog HDL

A four-floor elevator controller designed in Verilog HDL for simulation and FPGA implementation in Xilinx Vivado. The design combines floor-request storage, direction-aware scheduling, and a motion/door finite-state machine (FSM).

> **Project status:** RTL, testbench, and Basys 3 constraints are included. Run simulation and synthesis in Vivado before claiming verified results. Add your own screenshots and measured reports only after generating them.

## Features

- Four floors: Floor 0, Floor 1, Floor 2, and Floor 3.
- Four request bits, one per floor.
- Five-state motion/door FSM:
  - `ST_IDLE`
  - `ST_MOVE_UP`
  - `ST_MOVE_DOWN`
  - `ST_DOOR_OPEN`
  - `ST_DOOR_CLOSE`
- Direction-aware scheduling: continue in the current direction while requests remain ahead; reverse when no requests remain ahead and requests remain behind.
- Parameterized travel, door-open, and door-close timer counts.
- Directed self-checking testbench for normal operation and a direction-reversal scenario.
- Basys 3 XDC pin constraints.

## Repository contents

```text
4-floor-elevator-controller-verilog/
├── elevator_controller.v
├── tb_elevator_controller.v
├── Basys-3-Master.xdc
└── README.md
```

## Design overview

`pending_requests[3:0]` stores requests for floors 0 through 3. Bit 0 represents Floor 0, bit 1 Floor 1, bit 2 Floor 2, and bit 3 Floor 3.

The request scheduler checks whether pending requests exist above or below the current floor. The FSM controls movement and door timing. For the direction-reversal case, if the elevator is moving upward and requests exist for Floor 3 and Floor 0, it should serve Floor 3 before reversing to serve Floor 0.

### FSM state encoding

| State | `state_dbg` | Description |
|---|---:|---|
| `ST_IDLE` | `3'b000` | Wait for or schedule pending requests |
| `ST_MOVE_UP` | `3'b001` | Move up one floor at a time |
| `ST_MOVE_DOWN` | `3'b010` | Move down one floor at a time |
| `ST_DOOR_OPEN` | `3'b011` | Open door and serve the current floor |
| `ST_DOOR_CLOSE` | `3'b100` | Close the door before resuming |

## Requirements

- Xilinx Vivado Design Suite
- Verilog simulation support
- Basys 3 FPGA board only if implementing on hardware

## Run the simulation in Vivado

1. Open Vivado and select **Create Project**.
2. Choose **RTL Project**.
3. Add `elevator_controller.v` under **Design Sources**.
4. Add `tb_elevator_controller.v` under **Simulation Sources**.
5. Set `tb_elevator_controller` as the simulation top.
6. Select **Run Simulation → Run Behavioral Simulation**.
7. Add these signals to the waveform: `clk`, `rst`, `floor_req`, `current_floor`, `direction_up`, `motor_enable`, `door_open`, `pending_requests`, and `state_dbg`.
8. Run until the testbench finishes. Check the Tcl console for the PASS message and inspect the floor order and direction transitions.
9. Save a screenshot of the waveform and console output for your submission.

If the testbench fails, debug the RTL/testbench and rerun it before publishing a successful result.

## Synthesis and timing reports

1. Set `elevator_controller` as the synthesis top, not the testbench.
2. Add `Basys-3-Master.xdc` under **Constraints**.
3. Run **Run Synthesis**.
4. Open **Report Utilization** and save a screenshot.
5. Run implementation if required for the timing report you want to present.
6. Open **Report Timing Summary** and save a screenshot showing the clock constraint and timing metrics.

The XDC defines a 100 MHz clock (10 ns period), matching the Basys 3 onboard clock. Confirm that top-level port names match the RTL and review all Vivado warnings and constraints.

## Basys 3 switch and LED mapping

| Board input/output | Controller signal |
|---|---|
| 100 MHz clock | `clk` |
| Center pushbutton | `rst` |
| SW0–SW3 | `floor_req[0]`–`floor_req[3]` |
| LD0–LD1 | `current_floor[0]`–`current_floor[1]` |
| LD2 | `direction_up` |
| LD3 | `motor_enable` |
| LD4 | `door_open` |
| LD5–LD8 | `pending_requests[0]`–`pending_requests[3]` |
| LD9–LD11 | `state_dbg[0]`–`state_dbg[2]` |

**Hardware note:** Switches remain asserted while physically ON. A switch left ON may repeatedly request that floor. For a more user-friendly demonstration, consider adding edge detection or using debounced pushbuttons.

## Future improvements

- Add debounced, edge-detected floor-button inputs.
- Add sensor-based floor detection and explicit fault handling.
- Improve request capture/clear behavior for requests arriving during door service.
- Add more edge-case tests and assertions.
- Add actual Vivado waveform, utilization, and timing screenshots after running the tools.

## Safety disclaimer

This is an educational FPGA/RTL project, not a safety-certified elevator controller. Travel is modeled with counters rather than physical floor sensors. Do not use this design to control a passenger-carrying elevator.
