`default_nettype none
module tb_stall2(); 
            reg clk = 0;
            reg reset = 1;

        cpu_top #(.test_file("test_stall2.hex")) dut(.clk(clk),.reset(reset));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_stall2);
            #10 reset = 0;

            wait (dut.opcode == 7'b1101111 && dut.imm_j == 0);
            repeat (10) @(posedge clk); //allows pipeline to do all operations before sending out the values

            //x1
            if(dut.m1.registers[1] !== 32'd4)begin
                $display("FAIL: x1 = %0d, expected 4", dut.m1.registers[1]);
                errors = errors + 1;
            end

            //x2
            if(dut.m1.registers[2] !== 32'd16)begin
                $display("FAILED: x2 = %0d, expected 16", dut.m1.registers[2]);
                errors = errors + 1;
            end

            //x3
            if(dut.m1.registers[3] !== 32'd10)begin
                $display("FAILED: x3 = %0d, expected 10", dut.m1.registers[3]);
                errors = errors + 1;
            end

            //x4
            if(dut.m1.registers[4] !== 32'd10)begin
                $display("FAILED: x4 = %0d, expected 10", dut.m1.registers[4]);
                errors = errors + 1;
            end    

            //x5
            if(dut.m1.registers[5] !== 32'd10)begin
                $display("FAILED: x5 = %0d, expected 10", dut.m1.registers[5]);
                errors = errors + 1;
            end

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire