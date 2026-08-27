`default_nettype none
module regfile( //storage that can be called from 
    input wire clk,
    input [4:0] rs1_addr,          //read specficed address in register 1
    input [4:0] rs2_addr,          //read specified address in register 2
    input [4:0] rd_addr,           //write into address
    input [31:0] rd_data,          // data to write into register
    input wire write_enable,       //enable write
    output [31:0] rs1_data,        
    output [31:0] rs2_data
);
    reg [31:0] registers [0:31];

    //Adds values to register 
    always@(posedge clk) begin
        if(write_enable && rd_addr != 5'd0)
            registers[rd_addr] <= rd_data[31:0];
    end 

    //Read the values 
    assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : registers[rs2_addr];

endmodule

`default_nettype wire