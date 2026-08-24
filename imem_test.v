module imem_test;
  reg [31:0] imem [0:15];
  integer i;
  initial begin
    $readmemh("t_clean.hex", imem);
    for (i = 0; i < 4; i = i + 1)
      $display("imem[%0d] = %h", i, imem[i]);
    $finish;
  end
endmodule
