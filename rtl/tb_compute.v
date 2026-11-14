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
            $dumpfile("compute.vcd");
            $dumpvars(0, tb_compute);
            #10 reset = 0;

            // led_reg resets to 0000, so a CPU that never executes sw would pass any 0000 check.
            // Both expected values here (1100, 0100) are nonzero, so a dead CPU fails BOTH checks;
            // check order doesn't matter (unlike v1, where the nonzero check had to come first).
            
            repeat (30) @(posedge clk); // from reset: lui (slot 0), lw (1), sw fetched at slot 13, writes led_reg in MEM ≈ cycle 17. 30 = safe margin
                                        

            //input was 0011 the leds should output 1100 for -5
            if(dut.led_reg !== 4'b1100)begin 
                $display("FAILED: led_reg = %b, expected 1100", dut.led_reg);
                errors = errors + 1;
            end

            // change the switches mid-run; the loop must pick it up
            switches = 4'b1100;
            repeat (30) @(posedge clk); //30 is enough cycles because worst case is 28 cycles
                                        //16 (one fully cycle through all instrcutions) + 12 (lw→sw)

            // input 1100 and the leds output should 0100
            if(dut.led_reg !== 4'b0100)begin
                $display("FAILED: led_reg = %b, expected 0100 after switch change", dut.led_reg);
                errors = errors + 1;
            end
            

            


            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire