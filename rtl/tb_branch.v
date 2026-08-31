`default_nettype none  //creates an error for the silent bugs for not having a type because 
                       //if you don't give it one it will assume it's a 1 bit wire
module tb_branch;
    reg clk = 0;
    reg reset = 1;

    cpu_top #(.test_file("test_branch.hex")) dut(.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    integer errors = 0;

    //if the assertions are never met this will end the wait statement
    initial begin
        #10000;
        $display("TIMEOUT");
        $finish;
    end

    initial begin
        $dumpfile("cpu_top.vcd");
        $dumpvars(0, tb_branch);
        #10 reset = 0;

        wait (dut.opcode == 7'b1101111 && dut.imm_j == 0);//PC stop changing when imm_j = 0 with jump opcode
        repeat (10) @(posedge clk); //allows pipeline to do all operations before sending out the values

        //assertions 
        // x1 
        if(dut.m1.registers[1] !== 32'd5)begin
            $display("FAIL: x1 = %0d, expected 5", dut.m1.registers[1]);
            errors = errors + 1;
        end
        
        // x2
        if(dut.m1.registers[2] !== 32'd7)begin
            $display("FAIL: x2 = %0d, expected 7", dut.m1.registers[2]);
            errors = errors + 1;
        end

        //x5
        if(dut.m1.registers[5] !== -32'd1)begin
            $display("FAIL: x5 = %0d, expected -1", dut.m1.registers[5]);
            errors = errors + 1;
        end

        //x6
        if(dut.m1.registers[6] !== 32'd1)begin
            $display("FAIL: x6 = %0d, expected 1", dut.m1.registers[6]);
            errors = errors + 1;
        end

        //x7
        if(dut.m1.registers[7] !== 32'd5)begin
            $display("FAIL: x7 = %0d, expected 5", dut.m1.registers[7]);
            errors = errors + 1;
        end

        //x8
        if(dut.m1.registers[8] !== 32'd10)begin
            $display("FAIL: x8 = %0d, expected 10", dut.m1.registers[8]);
            errors = errors + 1;
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //bltu test

        //x10
        if(dut.m1.registers[10] !== 32'd99)begin
            $display("FAIL: x10 = %0d, expected 99", dut.m1.registers[10]);
            errors = errors + 1;
        end

        //x11
        if(dut.m1.registers[11] !== 32'd15)begin
            $display("FAIL: x11 = %0d, expected 15", dut.m1.registers[11]);
            errors = errors + 1;
        end
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //bne test

        //x12
        if(dut.m1.registers[12] !== 32'd3)begin
            $display("FAIL: x12 = %0d, expected 3", dut.m1.registers[12]);
            errors = errors + 1;
        end

        //x13
        if(dut.m1.registers[13] !== 32'd3)begin
            $display("FAIL: x13 = %0d, expected 3", dut.m1.registers[13]);
            errors = errors + 1;
        end

        //x14
        if(dut.m1.registers[14] !== 32'd99)begin
            $display("FAIL: x14 = %0d, expected 99", dut.m1.registers[14]);
            errors = errors + 1;
        end

        //x15
        if(dut.m1.registers[15] !== 32'd20)begin
            $display("FAIL: x15 = %0d, expected 20", dut.m1.registers[15]);
            errors = errors + 1;
        end
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //bgeu test

        //x16
        if(dut.m1.registers[16] !== 32'd10)begin
            $display("FAIL: x16 = %0d, expected 10", dut.m1.registers[16]);
            errors = errors + 1;
        end

        //x17
        if(dut.m1.registers[17] !== 32'd25)begin
            $display("FAIL: x17 = %0d, expected 25", dut.m1.registers[17]);
            errors = errors + 1;
        end
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        //bge test

        //x18
        if(dut.m1.registers[18] !== 32'd99)begin
            $display("FAIL: x18 = %0d, expected 99", dut.m1.registers[18]);
            errors = errors + 1;
        end

        //x19
        if(dut.m1.registers[19] !== 32'd30)begin
            $display("FAIL: x19 = %0d, expected 30", dut.m1.registers[19]);
            errors = errors + 1;
        end

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

        //x20
        if(dut.m1.registers[20] != 32'd0)begin
            $display("FAIL: x20 = %0d, expected 0", dut.m1.registers[20]);
            errors = errors + 1;
        end

        //x21
        if(dut.m1.registers[21] !== 32'd42)begin
            $display("FAIL: x21 = %0d, expected 42", dut.m1.registers[21]);
            errors = errors + 1;
        end


        if(errors != 0) $display("%0d FAILURES", errors);
        else            $display("ALL TEST PASSED");

        $finish;
    end

endmodule
`default_nettype wire