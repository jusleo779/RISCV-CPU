`default_nettype none
module tb_io_loop(); 
            reg clk = 0;
            reg reset = 1;
            reg[3:0] switches = 4'b0101;
            wire [3:0] led_reg;

        cpu_top #(.test_file("test_io_loop.hex")) dut(.clk(clk), .reset(reset), .switches(switches), .led_reg(led_reg));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #10000;
            $display("TIMEOUT");
            $finish;
        end
        initial begin 
            $dumpfile("cpu_top.vcd");
            $dumpvars(0, tb_io_loop);
            #10 reset = 0;

           
            repeat (30) @(posedge clk); //allows pipeline to do all operations before sending out the values

            
            if(dut.led_reg !== 4'b0101)begin
                $display("FAILED: led_reg = %b, expected 0101", dut.led_reg);
                errors = errors + 1;
            end

            // change the switches mid-run; the loop must pick it up
            switches = 4'b1010;
            repeat (30) @(posedge clk);

            if(dut.led_reg !== 4'b1010)begin
                $display("FAILED: led_reg = %b, expected 1010 after switch change", dut.led_reg);
                errors = errors + 1;
            end
            

            if(errors == 0) $display("ALL TEST PASSED");
            else            $display("%0d FAILURES", errors);

            $finish;
        end
endmodule

`default_nettype wire