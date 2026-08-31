`default_nettype none
module tb_load_store(); 
            reg clk = 0;
            reg reset = 1;

        cpu_top #(.test_file("test_load_store.hex")) dut(.clk(clk),.reset(reset));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_load_store);
            #10 reset = 0;

            wait (dut.opcode == 7'b1101111 && dut.imm_j == 0);
            repeat (10) @(posedge clk); //allows pipeline to do all operations before sending out the values

            //x5
            if(dut.m1.registers[5] !== 32'd100)begin
                $display("FAIL: x5 = %0d, expected 100", dut.m1.registers[5]);
                errors = errors + 1;
            end

            //x6
            if(dut.m1.registers[6] !== 32'd0)begin
                $display("FAIL: x6 = %0d, expected 0", dut.m1.registers[6]);
                errors = errors + 1;
            end

            //x7 (loaded value that was stored)
            if(dut.m1.registers[7] !== 32'd100)begin
                $display("FAIL: x7 = %0d, expected 100", dut.m1.registers[7]);
                errors = errors + 1;
            end

            //x8
            if(dut.m1.registers[8] !== 32'd50)begin
                $display("FAIL: x8 = %0d, expected 50", dut.m1.registers[8]);
                errors = errors + 1;
            end
            //x9
            if(dut.m1.registers[9] !== 32'd100)begin
                $display("FAIL: x9 = %0d, expected 100", dut.m1.registers[9]);
                errors = errors + 1;
            end

            //x10
            if(dut.m1.registers[10] !== 32'd50)begin
                $display("FAIL: x10 = %0d, expected 50", dut.m1.registers[10]);
                errors = errors + 1;
            end

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire