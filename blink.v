module blink(input clk, output reg led);
  reg [2:0] count = 0;
  always @(posedge clk) begin
    count <= count + 1;
    led <= count[2];
  end
endmodule

module tb;
  reg clk = 0;
  wire led;
  blink dut(.clk(clk), .led(led));
  always #5 clk = ~clk;
  initial begin
    $dumpfile("blink.vcd");
    $dumpvars(0, tb);
    #100 $finish;
  end
endmodule
