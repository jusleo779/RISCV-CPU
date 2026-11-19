`default_nettype none
module tb_subword();
    reg clk = 0;
    reg reset = 1;

    cpu_top #(.test_file("test_subword.hex")) dut(.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    integer errors = 0;

    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("subword.vcd");
        $dumpvars(0, tb_subword);
        #10 reset = 0;

        // 23 instructions before `j loop`: the last one (lhu x16) is fetched
        // at slot 22 and written back about 4 cycles later (~cycle 26).
        // 40 leaves margin. No taken jumps before the end, so no flush slots.
        repeat (40) @(posedge clk);

        
        if (dut.m1.registers[1] !== 32'h11223344) begin
            $display("FAIL: x1 = %h, expected 11223344", dut.m1.registers[1]);
            errors = errors + 1;
        end

        if (dut.m1.registers[2] !== 32'd24) begin
            $display("FAIL: x2 = %0d, expected 24", dut.m1.registers[2]);
            errors = errors + 1;
        end
        
        if (dut.m1.registers[3] !== 32'h000000AB) begin
            $display("FAIL: x3 = %h, expected 000000AB", dut.m1.registers[3]);
            errors = errors + 1;
        end

        if (dut.m1.registers[4] !== 32'd28) begin
            $display("FAIL: x4 = %0d, expected 28", dut.m1.registers[4]);
            errors = errors + 1;
        end

        if (dut.m1.registers[5] !== 32'h0000BEEF) begin
            $display("FAIL: x5 = %h, expected 0000BEEF", dut.m1.registers[5]);
            errors = errors + 1;
        end

        if (dut.m1.registers[6] !== 32'd32) begin
            $display("FAIL: x6 = %0d, expected 32", dut.m1.registers[6]);
            errors = errors + 1;
        end

        if (dut.m1.registers[7] !== 32'h80017F9C) begin
            $display("FAIL: x7 = %h, expected 80017F9C", dut.m1.registers[7]);
            errors = errors + 1;
        end

        if (dut.m1.registers[10] !== 32'h1122AB44) begin
            $display("FAIL: x10 = %h, expected 1122AB44 (sb lane 1)", dut.m1.registers[10]);
            errors = errors + 1;
        end

        
        if (dut.m1.registers[11] !== 32'hBEEF3344) begin
            $display("FAIL: x11 = %h, expected BEEF3344 (sh lane 2)", dut.m1.registers[11]);
            errors = errors + 1;
        end

        if (dut.m1.registers[12] !== 32'hFFFFFF9C) begin
            $display("FAIL: x12 = %h, expected FFFFFF9C (lb 0x9C)", dut.m1.registers[12]);
            errors = errors + 1;
        end
        
        if (dut.m1.registers[13] !== 32'h0000009C) begin
            $display("FAIL: x13 = %h, expected 0000009C (lbu 0x9C)", dut.m1.registers[13]);
            errors = errors + 1;
        end

        if (dut.m1.registers[14] !== 32'h0000007F) begin
            $display("FAIL: x14 = %h, expected 0000007F (lb lane 1, 0x7F)", dut.m1.registers[14]);
            errors = errors + 1;
        end

        if (dut.m1.registers[15] !== 32'hFFFF8001) begin
            $display("FAIL: x15 = %h, expected FFFF8001 (lh 0x8001)", dut.m1.registers[15]);
            errors = errors + 1;
        end

        if (dut.m1.registers[16] !== 32'h00008001) begin
            $display("FAIL: x16 = %h, expected 00008001 (lhu 0x8001)", dut.m1.registers[16]);
            errors = errors + 1;
        end

        if (errors == 0) $display("ALL TEST PASSED");
        else             $display("%0d FAILURES", errors);

        $finish;
    end
endmodule

`default_nettype wire