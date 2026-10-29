`default_nettype none
module cpu_fpga_top(
    input wire clk,
    input wire reset,
    input wire [3:0] switches,
    output wire [3:0] led_reg,
    output wire halted
);

    reg clk_div;

    always@(posedge clk)begin
        if(reset)
            clk_div <= 0;
        else
            clk_div <= ~clk_div; //makes it 50 Mhz clk by changing the clk based on posedge clk
    end

    wire clk_50;
    //makes it a distributable clk that has less variation in the delay
    BUFG bufg_inst (.I(clk_div), .O(clk_50)); //primitive built into Vivado

    cpu_top#(.test_file("test_io_loop.hex")) dut(.clk(clk_50), .reset(reset), .switches(switches), .led_reg(led_reg), .halted(halted));

endmodule

`default_nettype wire