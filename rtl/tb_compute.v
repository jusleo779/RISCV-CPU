`default_nettype none
module tb_compute(); 
            reg clk = 0;
            reg reset = 1;
            reg[3:0] switches = 4'b0011;
            wire [3:0] led_reg;

        cpu_top #(.test_file("test_compute.hex")) dut(.clk(clk), .reset(reset), .switches(switches), .led_reg(led_reg));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_compute);
            #10 reset = 0;

           
            repeat (20) @(posedge clk); //allows pipeline to do all operations before sending out the values

            // led_reg resets to 0000, so check 0111 first 
            if(dut.led_reg !== 4'b1000)begin
                $display("FAILED: led_reg = %b, expected 1000", dut.led_reg);
                errors = errors + 1;
            end

            // change the switches mid-run; the loop must pick it up
            switches = 4'b1100;
            repeat (20) @(posedge clk); //20 is enough cycles because worst case is 18 cycles

            if(dut.led_reg !== 4'b0000)begin
                $display("FAILED: led_reg = %b, expected 0000 after switch change", dut.led_reg);
                errors = errors + 1;
            end
            

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire