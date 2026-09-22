`timescale 1ns/1ps

module tb_heartbeat_monitor;

    parameter integer TIMEOUT_CYCLES = 5;
    parameter integer CLK_PERIOD_NS  = 10;

    reg  clk;
    reg  rst_n;
    reg  heartbeat;
    reg  clear_timeout;
    wire timeout;

    integer checks;
    integer errors;
    integer index;

    heartbeat_monitor #(
        .TIMEOUT_CYCLES(TIMEOUT_CYCLES)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .heartbeat     (heartbeat),
        .clear_timeout (clear_timeout),
        .timeout       (timeout)
    );

    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    task check_timeout;
        input expected;
        input [8*80-1:0] description;
        begin
            checks = checks + 1;
            if (timeout !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s at t=%0t: expected timeout=%b, got %b",
                         description, $time, expected, timeout);
            end else begin
                $display("PASS: %0s", description);
            end
        end
    endtask

    task wait_rising_edges;
        input integer count;
        integer edge_index;
        begin
            for (edge_index = 0; edge_index < count; edge_index = edge_index + 1)
                @(posedge clk);
            #1;
        end
    endtask

    task send_heartbeat;
        begin
            @(negedge clk);
            heartbeat = 1'b1;
            @(negedge clk);
            heartbeat = 1'b0;
            #1;
        end
    endtask

    task send_clear;
        begin
            @(negedge clk);
            clear_timeout = 1'b1;
            @(negedge clk);
            clear_timeout = 1'b0;
            #1;
        end
    endtask

    initial begin
        clk           = 1'b0;
        rst_n         = 1'b0;
        heartbeat     = 1'b0;
        clear_timeout = 1'b0;
        checks        = 0;
        errors        = 0;

        // Reset must immediately force a non-timeout state.
        #1;
        check_timeout(1'b0, "reset asserts a known non-timeout state");
        wait_rising_edges(2);
        rst_n = 1'b1;

        // A heartbeat before the boundary restarts the timeout interval.
        wait_rising_edges(TIMEOUT_CYCLES - 1);
        check_timeout(1'b0, "no timeout one cycle before the boundary");
        send_heartbeat;
        check_timeout(1'b0, "heartbeat keeps timeout deasserted");

        // Repeated valid heartbeats must keep the monitor healthy.
        for (index = 0; index < 3; index = index + 1) begin
            wait_rising_edges(2);
            send_heartbeat;
            check_timeout(1'b0, "periodic heartbeat keeps monitor healthy");
        end

        // TIMEOUT_CYCLES missing samples assert timeout exactly at the boundary.
        wait_rising_edges(TIMEOUT_CYCLES - 1);
        check_timeout(1'b0, "timeout remains low through N-1 missing cycles");
        wait_rising_edges(1);
        check_timeout(1'b1, "timeout asserts on the Nth missing cycle");
        wait_rising_edges(2);
        check_timeout(1'b1, "timeout remains latched without recovery input");

        // A new heartbeat is an explicit recovery event.
        send_heartbeat;
        check_timeout(1'b0, "heartbeat clears a latched timeout");

        // Exercise the boundary again, then use the independent clear input.
        wait_rising_edges(TIMEOUT_CYCLES);
        check_timeout(1'b1, "timeout can assert again after recovery");
        send_clear;
        check_timeout(1'b0, "clear_timeout clears and restarts the monitor");
        wait_rising_edges(TIMEOUT_CYCLES - 1);
        check_timeout(1'b0, "clear_timeout restarts a full timeout interval");
        wait_rising_edges(1);
        check_timeout(1'b1, "timeout reasserts at the post-clear boundary");

        // Asynchronous reset must clear an active timeout without a clock edge.
        @(negedge clk);
        #1 rst_n = 1'b0;
        #1;
        check_timeout(1'b0, "asynchronous reset clears active timeout");

        if (errors == 0) begin
            $display("\nTEST PASSED: %0d checks completed with no errors.", checks);
            $finish;
        end else begin
            $display("\nTEST FAILED: %0d of %0d checks failed.", errors, checks);
            $finish;
        end
    end

endmodule
