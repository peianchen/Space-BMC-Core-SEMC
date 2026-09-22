`timescale 1ns/1ps

// Heartbeat timeout detector.
//
// A heartbeat is sampled on the rising edge of clk.  TIMEOUT_CYCLES
// consecutive rising edges without a heartbeat assert timeout.  The timeout
// remains asserted until reset, clear_timeout, or a new heartbeat is sampled.
module heartbeat_monitor #(
    parameter integer TIMEOUT_CYCLES = 25000000
) (
    input  wire clk,
    input  wire rst_n,
    input  wire heartbeat,
    input  wire clear_timeout,
    output reg  timeout
);

    function integer counter_width;
        input integer value;
        integer remaining;
        begin
            counter_width = 0;
            remaining = value - 1;
            while (remaining > 0) begin
                counter_width = counter_width + 1;
                remaining = remaining >> 1;
            end
            if (counter_width < 1)
                counter_width = 1;
        end
    endfunction

    localparam integer COUNTER_WIDTH = counter_width(TIMEOUT_CYCLES);
    reg [COUNTER_WIDTH-1:0] elapsed_cycles;

    initial begin
        if (TIMEOUT_CYCLES < 1) begin
            $display("ERROR: TIMEOUT_CYCLES must be at least 1");
            $finish;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            elapsed_cycles <= {COUNTER_WIDTH{1'b0}};
            timeout        <= 1'b0;
        end else if (heartbeat || clear_timeout) begin
            elapsed_cycles <= {COUNTER_WIDTH{1'b0}};
            timeout        <= 1'b0;
        end else if (!timeout) begin
            if (elapsed_cycles == TIMEOUT_CYCLES - 1) begin
                timeout <= 1'b1;
            end else begin
                elapsed_cycles <= elapsed_cycles + 1'b1;
            end
        end
    end

endmodule
