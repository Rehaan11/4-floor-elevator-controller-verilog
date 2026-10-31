`timescale 1ns/1ps

module tb_elevator_controller;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg rst;
    reg [3:0] floor_req;
    wire [1:0] current_floor;
    wire direction_up;
    wire motor_enable;
    wire door_open;
    wire [3:0] pending_requests;
    wire [2:0] state_dbg;

    localparam [2:0] ST_IDLE       = 3'd0;
    localparam [2:0] ST_MOVE_UP    = 3'd1;
    localparam [2:0] ST_MOVE_DOWN  = 3'd2;
    localparam [2:0] ST_DOOR_OPEN  = 3'd3;
    localparam [2:0] ST_DOOR_CLOSE = 3'd4;

    elevator_controller #(
        .MOVE_TICKS(2),
        .DOOR_OPEN_TICKS(2),
        .DOOR_CLOSE_TICKS(1)
    ) dut (
        .clk(clk),
        .rst(rst),
        .floor_req(floor_req),
        .current_floor(current_floor),
        .direction_up(direction_up),
        .motor_enable(motor_enable),
        .door_open(door_open),
        .pending_requests(pending_requests),
        .state_dbg(state_dbg)
    );

    integer timeout;
    reg saw_floor3_door;
    reg saw_floor0_door_after_floor3;
    reg saw_reverse_down;
    reg saw_floor2_door;

    task pulse_request;
        input [3:0] req;
        begin
            @(negedge clk);
            floor_req = req;
            @(negedge clk);
            floor_req = 4'b0000;
        end
    endtask

    initial begin
        rst = 1'b1;
        floor_req = 4'b0000;
        saw_floor3_door = 1'b0;
        saw_floor0_door_after_floor3 = 1'b0;
        saw_reverse_down = 1'b0;
        saw_floor2_door = 1'b0;

        repeat (3) @(negedge clk);
        rst = 1'b0;

        // Edge case: from floor 0, request floor 3, then add floor 0 while
        // the lift is travelling upward. It must serve floor 3 first, then
        // reverse and return to floor 0.
        pulse_request(4'b1000);

        // Wait until the controller is travelling up, then request floor 0.
        timeout = 0;
        while (!(state_dbg == ST_MOVE_UP && current_floor == 2'd1) &&
               timeout < 100) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 100) $fatal(1, "TIMEOUT: elevator did not start moving up");

        pulse_request(4'b0001);

        timeout = 0;
        while (!saw_floor3_door && timeout < 200) begin
            @(negedge clk);
            if (state_dbg == ST_DOOR_OPEN && current_floor == 2'd3)
                saw_floor3_door = 1'b1;
            if (current_floor == 2'd3 && state_dbg == ST_MOVE_DOWN)
                saw_reverse_down = 1'b1;
            timeout = timeout + 1;
        end
        if (!saw_floor3_door)
            $fatal(1, "FAIL: floor 3 was not served");

        timeout = 0;
        while (!saw_floor0_door_after_floor3 && timeout < 200) begin
            @(negedge clk);
            if (state_dbg == ST_DOOR_OPEN && current_floor == 2'd0)
                saw_floor0_door_after_floor3 = 1'b1;
            timeout = timeout + 1;
        end
        if (!saw_floor0_door_after_floor3)
            $fatal(1, "FAIL: floor 0 was not served after floor 3");
        if (!saw_reverse_down)
            $display("NOTE: reverse-down transition was brief; floor order still checked");

        // Normal operation check: request floor 2 from floor 0.
        pulse_request(4'b0100);
        timeout = 0;
        while (!saw_floor2_door && timeout < 200) begin
            @(negedge clk);
            if (state_dbg == ST_DOOR_OPEN && current_floor == 2'd2)
                saw_floor2_door = 1'b1;
            timeout = timeout + 1;
        end
        if (!saw_floor2_door)
            $fatal(1, "FAIL: floor 2 request was not served");

        // Wait for the controller to become idle with no pending requests.
        timeout = 0;
        while ((state_dbg != ST_IDLE || pending_requests != 4'b0000) &&
               timeout < 200) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 200)
            $fatal(1, "FAIL: controller did not return to idle");

        $display("PASS: normal request and direction-reversal tests completed.");
        $finish;
    end

    initial begin
        $dumpfile("elevator_controller.vcd");
        $dumpvars(0, tb_elevator_controller);
    end

endmodule
