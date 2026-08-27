`default_nettype none
module tb_lui_auipc(); 
            reg clk = 0;
            reg reset = 1;

        cpu_top #(.test_file("test_lui_auipc.hex")) dut(.clk(clk),.reset(reset));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_lui_auipc);
            #10 reset = 0;

            wait (dut.opcode == 7'b1101111 && dut.imm_j == 0);
            #1; 

            //x1
            if(dut.m1.registers[1] !== 32'h12345000)begin
                $display("FAILED: x1 = %h, expected 0x12345000", dut.m1.registers[1]);
                errors = errors + 1;
            end

            //x2
            if(dut.m1.registers[2] !== 32'h01000004)begin
                $display("FAILED: x2 = %h, expected 0x01000004", dut.m1.registers[2]);
                errors = errors + 1;
            end

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire