`default_nettype none
module tb_arch(); 
            reg clk = 0;
            reg reset = 1;
            wire halted;

        cpu_top #(.test_file("I-add-00.hex"), .addr_bits(18), .hex_dir("../arch-test/hex/")) dut(.clk(clk), .reset(reset), .halted(halted));

        always #5 clk = ~clk;

        integer errors = 0;

        initial begin
            #400000;
            $display("TIMEOUT");
            $display("FAILED");
            $finish;
        end
        initial begin 
            `ifdef WAVEFORM
                $dumpfile("test_arch_I-add-00.vcd");
                $dumpvars(0, tb_arch);
            `endif

            #10 reset = 0;
            
            wait (dut.halted);
            repeat (10) @(posedge clk); // let instructions ahead of ebreak drain through WB before reading x1
            
            if (dut.m1.registers[1] !== 32'd123456789) begin
                $display("FAILED: x1 = %0d, expected 123456789", dut.m1.registers[1]);
                errors = errors + 1;
            end

            
            if(errors == 0) begin
                $display("ALL TEST PASSED");
                $display("Halted at %0d cycles", ($time / 10) - 10);
            end else begin
                $display("FAILED at %0d cycles", ($time / 10) - 10);
            end
            $finish;
        end
endmodule

`default_nettype wire