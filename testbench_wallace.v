`timescale 1ns/1ps
module tb_piped_wallace_mult;
    localparam CLK_PERIOD = 10;        
    localparam NUM_TESTS  = 1000;      
    localparam LATENCY    = 5;         
    
    reg         clk;
    reg         reset;
    reg  [15:0] x;
    reg  [15:0] y;
    wire [31:0] prod;
    
    piped_wallace_mult dut (
        .clock(clk),
        .reset(reset),
        .x(x),
        .y(y),
        .prod(prod)
    );
    
    integer i;
    integer errors;
    integer total;
    integer cycle_count;
    integer write_ptr, read_ptr;
    integer queued;
    
    reg [31:0] expected_queue [0:4095];
    reg [15:0] x_queue [0:4095];  
    reg [15:0] y_queue [0:4095];  
    reg [31:0] exp;
    reg [15:0] test_x, test_y;
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_piped_wallace_mult);
        
        reset = 1'b1;
        x = 16'h0000;
        y = 16'h0000;
        errors = 0;
        total  = 0;
        cycle_count = 0;
        write_ptr = 0;
        read_ptr  = 0;
        queued = 0;
        
        repeat (2) @(posedge clk);
        @(posedge clk);
        reset = 1'b0;
        
        for (i = 0; i < NUM_TESTS; i = i + 1) begin
            if (cycle_count >= LATENCY) begin
                exp = expected_queue[read_ptr];
                test_x = x_queue[read_ptr];
                test_y = y_queue[read_ptr];
                read_ptr = (read_ptr + 1) % 4096;
                queued = queued - 1;
                total = total + 1;
                
                if (prod !== exp) begin
                    $display("FAIL - Test %0d @ time %0t: %0d * %0d = %0d (expected %0d)", 
                             total, $time, test_x, test_y, prod, exp);
                    errors = errors + 1;
                end else begin
                    $display("PASS - Test %0d @ time %0t: %0d * %0d = %0d", 
                             total, $time, test_x, test_y, prod);
                end
            end
            
            x = $random & 16'hFFFF;
            y = $random & 16'hFFFF;
            
            expected_queue[write_ptr] = x * y;
            x_queue[write_ptr] = x;
            y_queue[write_ptr] = y;
            write_ptr = (write_ptr + 1) % 4096;
            queued = queued + 1;
            
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        
        while (queued > 0) begin
            exp = expected_queue[read_ptr];
            test_x = x_queue[read_ptr];
            test_y = y_queue[read_ptr];
            read_ptr = (read_ptr + 1) % 4096;
            queued = queued - 1;
            total = total + 1;
            
            if (prod !== exp) begin
                $display("FAIL - Test %0d (flush) @ time %0t: %0d * %0d = %0d (expected %0d)", 
                         total, $time, test_x, test_y, prod, exp);
                errors = errors + 1;
            end else begin
                $display("PASS - Test %0d (flush) @ time %0t: %0d * %0d = %0d", 
                         total, $time, test_x, test_y, prod);
            end
            
            @(posedge clk);
            cycle_count = cycle_count + 1;
        end
        
        $display("-------------------");
        if (errors == 0)
            $display("TEST PASSED: %0d tests, 0 errors", total);
        else
            $display("TEST FAILED: %0d tests, %0d errors", total, errors);
        $display("------------------------");
        
        # (CLK_PERIOD*2);
        $finish;
    end
endmodule
