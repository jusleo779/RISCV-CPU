module alu(
    input[31:0] a,
    input[31:0] b,
    input [3:0] alu_op, 
    output reg [31:0] result
);

parameter ADD_SUB = 3'b000; //depends on func7[5] value
parameter SLL = 3'b001;
parameter SLT = 3'b010;
parameter SLTU = 3'b011;
parameter XOR = 3'b100;
parameter SRL_SRA = 3'b101; //depends onf func7[5] value
parameter OR = 3'b110;
parameter AND = 3'b111;

always@(*)begin
    case(alu_op[2:0])
    ADD_SUB: begin 
        if(alu_op[3])
            result = a - b;
        else
            result = a + b;
    end
    SLL: result = a << (b[4:0]);  

    SLT: result = ($signed(a) < $signed(b)) ? 32'd1: 32'd0;

    SLTU: result = (a < b) ? 32'd1: 32'd0;

    XOR: result = a ^ b;

    SRL_SRA:begin
        if(alu_op[3])
            result = $signed(a) >>> (b[4:0]);
        else
            result = a >> (b[4:0]);
    end

    OR: result = a | b;

    AND: result = a & b;

    default: result = 32'b0;
    endcase
end

endmodule