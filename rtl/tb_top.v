module tb_top;
    reg clk = 0;
    reg reset = 1;

    cpu_top dut(.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    integer errors = 0;

    initial begin
        $dumpfile("cpu_top.vcd");
        $dumpvars(0, tb_top);
        #10 reset = 0;
        #250;                    // let the program run

        //x1
        if (dut.m1.registers[1] !== 32'd12) begin
            $display("FAIL: x1 = %0d, expected 12", dut.m1.registers[1]);
            errors = errors + 1;
        end
        //x2
        if (dut.m1.registers[2] !== 32'd10) begin
            $display("FAIL: x2 = %0d, expected 10", dut.m1.registers[2]);
            errors = errors + 1;
        end
        //x3
        if (dut.m1.registers[3] !== 32'd8) begin
            $display("FAIL: x3 = %0d, expected 8", dut.m1.registers[3]);
            errors = errors + 1;
        end

        //x4
        if (dut.m1.registers[4] !== 32'd14) begin
            $display("FAIL: x4 = %0d, expected 14", dut.m1.registers[4]);
            errors = errors + 1;
        end

        //x5
        if (dut.m1.registers[5] !== 32'd6) begin
            $display("FAIL: x5 = %0d, expected 6", dut.m1.registers[5]);
            errors = errors + 1;
        end

        //x6
        if (dut.m1.registers[6] !== 32'hFFFFFFFF) begin
            $display("FAIL: x6 = %h, expected 0xFFFFFFFF", dut.m1.registers[6]);
            errors = errors + 1;
        end
        
        //x7
        if (dut.m1.registers[7] !== 32'd1) begin
            $display("FAIL: x7 = %0d, expected 1", dut.m1.registers[7]);
            errors = errors + 1;
        end

        //x8
        if (dut.m1.registers[8] !== 32'd1) begin
            $display("FAIL: x8 = %0d, expected 1", dut.m1.registers[8]);
            errors = errors + 1;
        end

        //x9
        if (dut.m1.registers[9] !== 32'd0) begin
            $display("FAIL: x9 = %0d, expected 0", dut.m1.registers[9]);
            errors = errors + 1;
        end

        //x10
        if (dut.m1.registers[10] !== 32'hFFFFFFF0) begin
            $display("FAIL: x10 = %h, expected 0xFFFFFFF0", dut.m1.registers[10]);
            errors = errors + 1;
        end

        //x11
        if (dut.m1.registers[11] !== 32'h0FFFFFFF) begin
            $display("FAIL: x11 = %h, expected 0x0FFFFFFF", dut.m1.registers[11]);
            errors = errors + 1;
        end

        //x12
        if (dut.m1.registers[12] !== 32'hFFFFFFFF) begin
            $display("FAIL: x12 = %h, expected 0xFFFFFFFF", dut.m1.registers[12]);
            errors = errors + 1;
        end

        //x13
        if (dut.m1.registers[13] !== 32'd40) begin
            $display("FAIL: x13 = %0d, expected 40", dut.m1.registers[13]);
            errors = errors + 1;
        end

        
        //x14
        if (dut.m1.registers[14] !== 32'd5) begin
            $display("FAIL: x14 = %0d, expected 5", dut.m1.registers[14]);
            errors = errors + 1;
        end

        //x15
        if (dut.m1.registers[15] !== 32'd10) begin
            $display("FAIL: x15 = %0d, expected 10", dut.m1.registers[15]);
            errors = errors + 1;
        end

        //x16
        if (dut.m1.registers[16] !== 32'd15) begin
            $display("FAIL: x16 = %0d, expected 15", dut.m1.registers[16]);
            errors = errors + 1;
        end

        //x17
        if (dut.m1.registers[17] !== 32'hFFFFFFFF) begin
            $display("FAIL: x17 = %h, expected 0xFFFFFFFF", dut.m1.registers[17]);
            errors = errors + 1;
        end

        //x18
        if (dut.m1.registers[18] !== 32'd10) begin
            $display("FAIL: x18 = %0d, expected 10", dut.m1.registers[18]);
            errors = errors + 1;
        end

        if (dut.pc !== 32'd76) $display("FAIL: program did not complete, pc=%0d", dut.pc);
        
        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d FAILURES", errors);
        $finish;
    end
   
    
endmodule
