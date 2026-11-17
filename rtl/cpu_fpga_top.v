`default_nettype none
module cpu_fpga_top(
    input wire clk,
    input wire reset,
    input wire [3:0] switches,
    output wire [3:0] led_reg,
    output wire halted
);

    reg clk_div = 1'b0; //simulation can't start with empty value

   
    // 50 MHz clk
    always@(posedge clk)begin
        clk_div <= ~clk_div; //makes it 50 Mhz clk by changing the clk based on posedge clk
    end

    wire clk_50;

    // makes it a distributable clk that has less variation in the delay
    BUFG bufg_inst (.I(clk_div), .O(clk_50)); //primitive built into Vivado

    // Reset synchronizer, clocked by the domain that reads it (clk_50).
    // reset1 may go metastable when the button changes near an edge
    // reset2 samples it a full cycle later, so the CPU sees one clean value.
    // Initialized RESET as 1 so CPU starts IN reset at power-on, released after 2 clk_50 cycles.

    // the ASYNC_REG tells Vivado these are syncrhonizer's values
    (* ASYNC_REG = "TRUE" *) reg reset1 = 1'b1;
    (* ASYNC_REG = "TRUE" *) reg reset2 = 1'b1;

    always@(posedge clk_50)begin
        reset1 <= reset;     
        reset2 <= reset1;    
    end
    

    cpu_top#(.test_file("test_compute.hex")) dut(
                                                    .clk(clk_50), 
                                                    .reset(reset2), 
                                                    .switches(switches), 
                                                    .led_reg(led_reg), 
                                                    .halted(halted)
                                                );

endmodule

`default_nettype wire