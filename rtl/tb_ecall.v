`default_nettype none
module tb_ecall(); 
            reg clk = 0;
            reg reset = 1;

        cpu_top #(.test_file("test_ecall.hex")) dut(.clk(clk),.reset(reset));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end

        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_ecall);
            #10 reset = 0;

            wait (dut.opcode == 7'b1110011 &&  (dut.instr[31:20] == 12'd0));
            repeat (10) @(posedge clk); //allows pipeline to do all operations before sending out the values

            
            if(dut.m1.registers[1] !== 32'd5)begin
                $display("FAIL: x1 = %0d, expected 5", dut.m1.registers[1]);
                errors = errors + 1;
            end

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);
            $finish;
        end
endmodule

`default_nettype wire