`timescale 1ns/1ps

// Four-floor elevator controller (floors 0, 1, 2, 3).
// Scheduling policy: continue in the current direction while requests remain
// ahead; reverse only when no requests remain ahead and requests remain behind.
//
// This is a synthesizable RTL model. Travel and door dwell are clock-counted
// timers for simulation/FPGA demonstration; replace them with sensor feedback
// for a physical elevator model.
module elevator_controller #(
    parameter integer MOVE_TICKS       = 3,
    parameter integer DOOR_OPEN_TICKS  = 4,
    parameter integer DOOR_CLOSE_TICKS = 2
) (
    input  wire       clk,
    input  wire       rst,          // synchronous, active-high reset
    input  wire [3:0] floor_req,    // one request bit per floor: [3:0]
    output reg  [1:0] current_floor,
    output reg        direction_up, // 1 = up, 0 = down
    output reg        motor_enable,
    output reg        door_open,
    output reg  [3:0] pending_requests,
    output reg  [2:0] state_dbg
);

    localparam [2:0] ST_IDLE       = 3'd0;
    localparam [2:0] ST_MOVE_UP    = 3'd1;
    localparam [2:0] ST_MOVE_DOWN  = 3'd2;
    localparam [2:0] ST_DOOR_OPEN  = 3'd3;
    localparam [2:0] ST_DOOR_CLOSE = 3'd4;

    reg [31:0] timer;

    // True when at least one request is strictly above/below a given floor.
    function has_above;
        input [3:0] req;
        input [1:0] floor_num;
        begin
            case (floor_num)
                2'd0: has_above = |req[3:1];
                2'd1: has_above = |req[3:2];
                2'd2: has_above = req[3];
                default: has_above = 1'b0;
            endcase
        end
    endfunction

    function has_below;
        input [3:0] req;
        input [1:0] floor_num;
        begin
            case (floor_num)
                2'd0: has_below = 1'b0;
                2'd1: has_below = req[0];
                2'd2: has_below = |req[1:0];
                default: has_below = |req[2:0];
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            current_floor    <= 2'd0;
            direction_up     <= 1'b1;
            motor_enable     <= 1'b0;
            door_open        <= 1'b0;
            pending_requests <= 4'b0000;
            state_dbg        <= ST_IDLE;
            timer            <= 32'd0;
        end else begin
            // Latch all incoming floor requests. A request is cleared when
            // that floor is being served in ST_DOOR_OPEN.
            pending_requests <= pending_requests | floor_req;

            // Safe defaults; states assert outputs as needed.
            motor_enable <= 1'b0;
            door_open    <= 1'b0;

            case (state_dbg)
                ST_IDLE: begin
                    timer <= 32'd0;

                    if (pending_requests[current_floor]) begin
                        state_dbg <= ST_DOOR_OPEN;
                    end else if (direction_up &&
                                 has_above(pending_requests, current_floor)) begin
                        state_dbg    <= ST_MOVE_UP;
                        motor_enable <= 1'b1;
                    end else if (direction_up &&
                                 has_below(pending_requests, current_floor)) begin
                        direction_up <= 1'b0;
                        state_dbg    <= ST_MOVE_DOWN;
                        motor_enable <= 1'b1;
                    end else if (!direction_up &&
                                 has_below(pending_requests, current_floor)) begin
                        state_dbg    <= ST_MOVE_DOWN;
                        motor_enable <= 1'b1;
                    end else if (!direction_up &&
                                 has_above(pending_requests, current_floor)) begin
                        direction_up <= 1'b1;
                        state_dbg    <= ST_MOVE_UP;
                        motor_enable <= 1'b1;
                    end
                end

                ST_MOVE_UP: begin
                    motor_enable <= 1'b1;
                    if (timer < MOVE_TICKS - 1) begin
                        timer <= timer + 1'b1;
                    end else begin
                        timer <= 32'd0;
                        if (current_floor < 2'd3) begin
                            current_floor <= current_floor + 1'b1;

                            if (pending_requests[current_floor + 1'b1]) begin
                                state_dbg <= ST_DOOR_OPEN;
                            end else if (!has_above(pending_requests,
                                                    current_floor + 1'b1) &&
                                         has_below(pending_requests,
                                                   current_floor + 1'b1)) begin
                                // No stops remain ahead: reverse now rather
                                // than travelling unnecessarily to the top.
                                direction_up <= 1'b0;
                                state_dbg    <= ST_MOVE_DOWN;
                            end
                        end else begin
                            // At top floor, reverse if work remains below.
                            if (has_below(pending_requests, current_floor)) begin
                                direction_up <= 1'b0;
                                state_dbg    <= ST_MOVE_DOWN;
                            end else begin
                                state_dbg <= ST_IDLE;
                            end
                        end
                    end
                end

                ST_MOVE_DOWN: begin
                    motor_enable <= 1'b1;
                    if (timer < MOVE_TICKS - 1) begin
                        timer <= timer + 1'b1;
                    end else begin
                        timer <= 32'd0;
                        if (current_floor > 2'd0) begin
                            current_floor <= current_floor - 1'b1;

                            if (pending_requests[current_floor - 1'b1]) begin
                                state_dbg <= ST_DOOR_OPEN;
                            end else if (!has_below(pending_requests,
                                                    current_floor - 1'b1) &&
                                         has_above(pending_requests,
                                                   current_floor - 1'b1)) begin
                                // No stops remain below: reverse and serve
                                // the requests above.
                                direction_up <= 1'b1;
                                state_dbg    <= ST_MOVE_UP;
                            end
                        end else begin
                            // At bottom floor, reverse if work remains above.
                            if (has_above(pending_requests, current_floor)) begin
                                direction_up <= 1'b1;
                                state_dbg    <= ST_MOVE_UP;
                            end else begin
                                state_dbg <= ST_IDLE;
                            end
                        end
                    end
                end

                ST_DOOR_OPEN: begin
                    door_open        <= 1'b1;
                    pending_requests[current_floor] <= 1'b0;
                    if (timer < DOOR_OPEN_TICKS - 1) begin
                        timer <= timer + 1'b1;
                    end else begin
                        timer     <= 32'd0;
                        state_dbg <= ST_DOOR_CLOSE;
                    end
                end

                ST_DOOR_CLOSE: begin
                    door_open <= 1'b0;
                    if (timer < DOOR_CLOSE_TICKS - 1) begin
                        timer <= timer + 1'b1;
                    end else begin
                        timer     <= 32'd0;
                        state_dbg <= ST_IDLE;
                    end
                end

                default: begin
                    state_dbg        <= ST_IDLE;
                    timer            <= 32'd0;
                    motor_enable     <= 1'b0;
                    door_open        <= 1'b0;
                end
            endcase
        end
    end

endmodule
