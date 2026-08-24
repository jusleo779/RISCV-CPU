module cpu_top(
    input clk,
    input reset
);

    // Program Counter
    reg [31:0] pc = 32'b0;

    // Instruction memory: word-addressed, 32-bit wide
    reg [31:0] imem [0:1023]; //1024 instances of imem(an array) that holds 32 bits
    wire [31:0] instr;

    //before simulation
    initial begin
        $readmemh("../selftest/test_alu.hex", imem);//fills array from the start from hex file
    end

    assign instr = imem[pc[11:2]];  // word-aligned fetch

    // Decode stub — pull out fields, don't act on them yet
    //set bit locations by document
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};  // I-type, sign-extended

    wire[31:0] result;
    wire[31:0] data1, data2;

    wire alu_src = (opcode == 7'b0110011);

    wire use_funct7 = alu_src || (opcode == 7'b0010011 && funct3 == 3'b101); //includes the immediate versions of SRL/SRA

    //positive list
    wire reg_write = (opcode == 7'b0110111) ||                          // U-type (LUI - upper immediate)
                     (opcode == 7'b0010111) ||                          // U-type (AUIPC - upper immediate)
                     (opcode == 7'b1101111) ||                          // J-type (JAL - jumps)
                     (opcode == 7'b1100111) ||                          // I-type (JALR - jumps)
                     (opcode == 7'b0010011) ||                          // I-type (OP- Register-Register Arithmetic Immediate)
                     (opcode == 7'b0000011) ||                          // I-type (LOAD - LB, LH, LW, LBU, LHU)
                     (opcode == 7'b0110011);                            // R-type (OP - Register-Register Arithmetic)

    // PC update — no branches yet, just PC + 4
    always @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc + 4;
    end

    // Debug: print what's happening each cycle
    always @(posedge clk) begin
        if (!reset)
            $display("pc=%0d instr=%h opcode=%b rd=%0d rs1=%0d imm=%0d data1=%0d result=%0d",
                       pc, instr, opcode, rd, rs1, $signed(imm_i), data1, result);
    end



    alu m2(
        .a(data1),
        .b((alu_src)? data2: imm_i), 
        .alu_op({funct7[5] && use_funct7, funct3}),
        .result(result)
    );
    
    regfile m1(
        .clk(clk),
        .rs1_addr(rs1),
        .rs2_addr(rs2),
        .rd_addr(rd),
        .rd_data(result),
        .write_enable(reg_write),
        .rs1_data(data1),
        .rs2_data(data2)
    );
    
  
    

endmodule
