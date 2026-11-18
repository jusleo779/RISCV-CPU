`default_nettype none
module tb_halt_flush(); 
            reg clk = 0;
            reg reset = 1;
            wire halted;

        cpu_top #(.test_file("test_halt_flush.hex")) dut(.clk(clk), .reset(reset), .halted(halted));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("test_halt_flush.vcd");
            $dumpvars(0, tb_halt_flush);
            #10 reset = 0;
            
            wait (dut.halted);
            repeat (10) @(posedge clk); // let older instructions finish writeback

            //x1
            if(dut.m1.registers[1] !== 32'd5)begin
                $display("FAILED: x1 = %0d, expected 5", dut.m1.registers[1]);
                errors = errors + 1;
            end

            //x2
            if(dut.m1.registers[2] !== 32'd10)begin
                $display("FAILED: x2 = %0d, expected 10", dut.m1.registers[2]);
                errors = errors + 1;
            end
            
            //x3
            if(dut.m1.registers[3] !== 32'd10)begin
                $display("FAILED: x3 = %0d, expected 10", dut.m1.registers[3]);
                errors = errors + 1;
            end

            if(dut.halted !== 1'b1)begin
                $display("FAILED to HALT correctly");
                errors = errors + 1;
            end

            
            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire