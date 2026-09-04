`default_nettype none
module tb_led(); 
            reg clk = 0;
            reg reset = 1;
            wire [3:0] led_reg;

        cpu_top #(.test_file("test_led.hex")) dut(.clk(clk), .reset(reset), .led_reg(led_reg));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_led);
            #10 reset = 0;

            wait (dut.opcode == 7'b1101111 && dut.imm_j == 0);
            repeat (10) @(posedge clk); //allows pipeline to do all operations before sending out the values

            //x1
            if(dut.m1.registers[1] !== 32'h80000000)begin
                $display("FAILED: x1 = %h, expected 0x80000000", dut.m1.registers[1]);
                errors = errors + 1;
            end

            //x2
            if(dut.m1.registers[2] !== 32'd5)begin
                $display("FAILED: x2 = %0d, expected 5", dut.m1.registers[2]);
                errors = errors + 1;
            end

            if(dut.led_reg !== 4'b0101)begin
                $display("FAILED: led_reg = %0d, expected 5", dut.led_reg);
                errors = errors + 1;
            end

            

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire